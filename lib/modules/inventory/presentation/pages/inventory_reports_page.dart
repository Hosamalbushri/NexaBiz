import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/models/report_export_labels.dart';
import '../../domain/models/report_export_result.dart';
import '../providers/inventory_providers.dart';
import '../providers/quantity_entry_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/selected_item_provider.dart';
import '../widgets/catalog_expandable_search.dart';
import '../widgets/report_items_data_grid.dart';
import '../widgets/report_status_chart.dart';
import 'inventory_routes.dart';

class InventoryReportsPage extends ConsumerStatefulWidget {
  const InventoryReportsPage({super.key, this.embedded = false});

  /// When true, page chrome is adapted for rare embedded hosts.
  final bool embedded;

  @override
  ConsumerState<InventoryReportsPage> createState() =>
      _InventoryReportsPageState();
}

class _InventoryReportsPageState extends ConsumerState<InventoryReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _searchExpanded = false;

  static const _filters = ReportFilter.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    ref.read(reportsSelectedFilterProvider.notifier).state =
        _filters[_tabController.index];
    ref.read(reportPageIndexProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final summaryAsync = ref.watch(reportSummaryProvider);
    final pagedAsync = ref.watch(pagedReportItemsProvider);
    final exportState = ref.watch(reportExportProvider);
    final pageIndex = ref.watch(reportPageIndexProvider);
    final pageSize = ref.watch(reportPageSizeProvider);
    final searchQuery = ref.watch(reportsSearchQueryProvider);

    final filterTabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: [
        Tab(text: localization.allItems),
        Tab(text: localization.matchedItems),
        Tab(text: localization.shortageItems),
        Tab(text: localization.overageItems),
        Tab(text: localization.notCountedItems),
      ],
    );

    final exportAction = CustomAppBarAction(
      icon: Icons.print_rounded,
      tooltip: localization.exportReport,
      onPressed: exportState.isLoading
          ? null
          : () {
              // Ignore returned Future — errors are handled inside.
              _showExportOptions();
            },
      isLoading: exportState.isLoading,
    );

    final body = summaryAsync.when(
      loading: () => const AppLoading(style: AppLoadingStyle.skeletonList),
      error: (error, _) => AppErrorState(
        message: error.toString(),
        onRetry: () {
          bumpInventoryRevisionFromWidget(ref);
          ref.invalidate(reportSummaryProvider);
          ref.invalidate(pagedReportItemsProvider);
        },
      ),
      data: (summary) {
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  bumpInventoryRevisionFromWidget(ref);
                  await ref.read(reportSummaryProvider.future);
                  await ref.read(pagedReportItemsProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: AppConstants.pageInsets(context),
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 700
                            ? 3
                            : 2;
                        final childAspectRatio = constraints.maxWidth >= 700
                            ? 1.35
                            : 1.05;
                        final colorScheme = Theme.of(context).colorScheme;
                        final cards = [
                          StatCard(
                            title: localization.totalItems,
                            value: summary.totalItems.toString(),
                            icon: Icons.inventory_2_outlined,
                            color: colorScheme.primary,
                          ),
                          StatCard(
                            title: localization.countedItems,
                            value: summary.countedItems.toString(),
                            icon: Icons.fact_check_outlined,
                            color: colorScheme.tertiary,
                          ),
                          StatCard(
                            title: localization.remainingItems,
                            value: summary.remainingItems.toString(),
                            icon: Icons.pending_actions_outlined,
                            color: colorScheme.secondary,
                          ),
                          StatCard(
                            title: localization.matched,
                            value: summary.matched.toString(),
                            icon: Icons.verified_outlined,
                            color: colorScheme.primary,
                          ),
                          StatCard(
                            title: localization.shortage,
                            value: summary.shortage.toString(),
                            icon: Icons.remove_circle_outline,
                            color: colorScheme.error,
                          ),
                          StatCard(
                            title: localization.overage,
                            value: summary.overage.toString(),
                            icon: Icons.add_circle_outline,
                            color: colorScheme.tertiary,
                          ),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cards.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                          itemBuilder: (context, index) => cards[index],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ReportStatusChart(summary: summary),
                    const SizedBox(height: AppSpacing.md),
                    _ReportsProductsHeader(
                      title: localization.productsHubTitle,
                      searchExpanded: _searchExpanded,
                      onSearch: () => setState(() => _searchExpanded = true),
                      onCloseSearch: () {
                        _searchController.clear();
                        ref.read(reportsSearchQueryProvider.notifier).state =
                            '';
                        ref.read(reportPageIndexProvider.notifier).state = 0;
                        setState(() => _searchExpanded = false);
                      },
                    ),
                    CatalogExpandableSearchPanel(
                      expanded: _searchExpanded,
                      onExpandedChanged: (value) {
                        if (!value) {
                          _searchController.clear();
                          ref
                                  .read(reportsSearchQueryProvider.notifier)
                                  .state =
                              '';
                          ref.read(reportPageIndexProvider.notifier).state = 0;
                        }
                        setState(() => _searchExpanded = value);
                      },
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      searchField: ref.watch(reportsSearchFieldProvider),
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      onQueryChanged: (value) {
                        ref.read(reportsSearchQueryProvider.notifier).state =
                            value;
                        ref.read(reportPageIndexProvider.notifier).state = 0;
                      },
                      onSearchFieldChanged: (field) {
                        if (ref.read(reportsSearchFieldProvider) == field) {
                          return;
                        }
                        ref.read(reportsSearchFieldProvider.notifier).state =
                            field;
                        ref.read(reportPageIndexProvider.notifier).state = 0;
                      },
                    ),
                    SizedBox(
                      height: 480,
                      child: pagedAsync.when(
                        loading: () => const AppLoading(),
                        error: (error, _) => AppErrorState(
                          message: error.toString(),
                          onRetry: () =>
                              ref.invalidate(pagedReportItemsProvider),
                        ),
                        data: (paged) {
                          if (paged.totalCount == 0) {
                            if (summary.totalItems == 0 &&
                                searchQuery.trim().isEmpty) {
                              return AppEmptyState(
                                title:
                                    localization.inventoryEmptyNeedsImportTitle,
                                subtitle: localization
                                    .inventoryEmptyNeedsImportMessage,
                                icon: Icons.upload_file_outlined,
                                actionLabel: localization.inventoryGoToImport,
                                actionIcon: Icons.upload_file_outlined,
                                actionVariant: AppButtonVariant.text,
                                onAction: () =>
                                    context.push(InventoryRoutes.import),
                              );
                            }
                            return AppEmptyState(
                              title: localization.emptyStateTitle,
                              subtitle: localization.emptyStateSubtitle,
                            );
                          }
                          return ReportItemsDataGrid(
                            items: paged.items,
                            statusLabel: _statusLabel,
                            totalCount: paged.totalCount,
                            page: pageIndex,
                            pageSize: pageSize,
                            onItemSelected: _openItem,
                            onPageChanged: (page) {
                              ref.read(reportPageIndexProvider.notifier).state =
                                  page;
                            },
                            onPageSizeChanged: (size) {
                              if (ref.read(reportPageSizeProvider) == size) {
                                return;
                              }
                              ref.read(reportPageSizeProvider.notifier).state =
                                  size;
                              ref.read(reportPageIndexProvider.notifier).state =
                                  0;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(child: filterTabBar),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: exportAction,
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !_searchExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }
        _searchController.clear();
        ref.read(reportsSearchQueryProvider.notifier).state = '';
        ref.read(reportPageIndexProvider.notifier).state = 0;
        setState(() => _searchExpanded = false);
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: localization.reportsTitle,
          showBackButton: true,
          actions: [exportAction],
          bottom: filterTabBar,
        ),
        body: body,
      ),
    );
  }

  String _statusLabel(ItemStatus status) {
    final localization = AppLocalizations.of(context);
    switch (status) {
      case ItemStatus.matched:
        return localization.matchedStatus;
      case ItemStatus.shortage:
        return localization.shortageStatus;
      case ItemStatus.overage:
        return localization.overageStatus;
      case ItemStatus.notCounted:
        return localization.notCountedStatus;
    }
  }

  void _openItem(InventoryItem item) {
    ref.read(selectedItemProvider.notifier).state = item;
    final mainText = _formatQuantity(item.mainQuantity);
    final subText = _formatQuantity(item.subQuantity);
    ref
        .read(quantityEntryProvider.notifier)
        .setQuantities(mainText: mainText, secondaryText: subText);
    context.push(InventoryRoutes.countDetails);
  }

  String _formatQuantity(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Future<void> _showExportOptions() async {
    final localization = AppLocalizations.of(context);
    try {
      final validationError = await ref
          .read(reportExportProvider.notifier)
          .validateBeforeExport();
      if (!mounted) {
        return;
      }
      if (validationError != null) {
        showAppSnackBar(
          context,
          message: _exportValidationMessage(localization, validationError.code),
          isSuccess: false,
        );
        return;
      }

      final format = await showAppBottomSheet<ReportExportFormat>(
        context: context,
        title: localization.exportAs,
        child: Builder(
          builder: (sheetContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: Text(localization.exportExcel),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(ReportExportFormat.excel),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(localization.exportPdf),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(ReportExportFormat.pdf),
                ),
              ],
            );
          },
        ),
      );

      if (format == null || !mounted) {
        return;
      }
      await _exportReport(format);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: localization.exportFailed,
        isSuccess: false,
      );
    }
  }

  Future<void> _exportReport(ReportExportFormat format) async {
    final localization = AppLocalizations.of(context);
    final labels = _exportLabels(localization);
    final result = await ref
        .read(loadingControllerProvider)
        .run(
          message: localization.loadingExportingReport,
          action: () => ref
              .read(reportExportProvider.notifier)
              .exportReport(format: format, labels: labels),
        );

    if (!mounted) {
      return;
    }

    switch (result) {
      case ReportExportValidationError(:final code):
        showAppSnackBar(
          context,
          message: _exportValidationMessage(localization, code),
          isSuccess: false,
        );
      case ReportExportFailure():
        showAppSnackBar(
          context,
          message: localization.exportFailed,
          isSuccess: false,
        );
      case ReportExportSuccess(:final path):
        await showAppBottomSheet<void>(
          context: context,
          title: localization.exportSuccess,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: localization.productsBarcodePrint,
                  icon: Icons.print_outlined,
                  expand: true,
                  onPressed: () async {
                    try {
                      await ref
                          .read(reportExportProvider.notifier)
                          .printExportedFile(path, labels: labels);
                    } catch (_) {
                      if (!mounted) {
                        return;
                      }
                      showAppSnackBar(
                        context,
                        message: localization.exportFailed,
                        isSuccess: false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: localization.shareExport,
                  icon: Icons.share_outlined,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  onPressed: () async {
                    try {
                      await ref
                          .read(reportExportProvider.notifier)
                          .shareExportedFile(path);
                    } catch (_) {
                      if (!mounted) {
                        return;
                      }
                      showAppSnackBar(
                        context,
                        message: localization.exportFailed,
                        isSuccess: false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
    }
  }

  ReportExportLabels _exportLabels(AppLocalizations localization) {
    final locale = Localizations.localeOf(context);
    final isRtl =
        locale.languageCode == 'ar' ||
        Directionality.of(context) == TextDirection.rtl;
    final filter = ref.read(reportsSelectedFilterProvider);
    return ReportExportLabels(
      localeCode: locale.languageCode,
      isRtl: isRtl,
      reportTitle: localization.inventoryReportTitle,
      generatedAt: localization.generatedAt,
      sheetName: localization.inventorySheetName,
      totalItems: localization.totalItems,
      countedItems: localization.countedItems,
      remainingItems: localization.remainingItems,
      matched: localization.matched,
      shortage: localization.shortage,
      overage: localization.overage,
      code: localization.codeLabel,
      name: localization.itemName,
      barcode: localization.barcode,
      packSize: localization.packSize,
      systemQuantity: localization.systemQuantity,
      actualQuantity: localization.actualQuantity,
      mainQuantity: localization.mainQuantity,
      subQuantity: localization.subQuantity,
      systemMainQuantity: localization.systemMainQuantity,
      systemSubQuantity: localization.systemSubQuantity,
      countedMainQuantity: localization.countedMainQuantity,
      countedSubQuantity: localization.countedSubQuantity,
      varianceQuantity: localization.varianceQuantity,
      varianceMainQuantity: localization.varianceMainQuantity,
      varianceSubQuantity: localization.varianceSubQuantity,
      reportSection: localization.reportSection,
      filterLabel: _filterLabel(localization, filter),
      difference: localization.difference,
      status: localization.status,
      matchedStatus: localization.matchedStatus,
      shortageStatus: localization.shortageStatus,
      overageStatus: localization.overageStatus,
      notCountedStatus: localization.notCountedStatus,
    );
  }

  String _filterLabel(AppLocalizations localization, ReportFilter filter) {
    switch (filter) {
      case ReportFilter.all:
        return localization.allItems;
      case ReportFilter.matched:
        return localization.matchedItems;
      case ReportFilter.shortage:
        return localization.shortageItems;
      case ReportFilter.overage:
        return localization.overageItems;
      case ReportFilter.notCounted:
        return localization.notCountedItems;
    }
  }

  String _exportValidationMessage(AppLocalizations localization, String code) {
    switch (code) {
      case ReportExportValidationError.emptyItems:
        return localization.exportNoItems;
      case ReportExportValidationError.dataNotReady:
        return localization.exportDataNotReady;
      default:
        return localization.exportFailed;
    }
  }
}

class _ReportsProductsHeader extends StatelessWidget {
  const _ReportsProductsHeader({
    required this.title,
    required this.searchExpanded,
    required this.onSearch,
    required this.onCloseSearch,
  });

  final String title;
  final bool searchExpanded;
  final VoidCallback onSearch;
  final VoidCallback onCloseSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final material = MaterialLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (searchExpanded)
            CustomAppBarAction(
              icon: Icons.close_rounded,
              tooltip: material.closeButtonTooltip,
              onPressed: onCloseSearch,
              accentColor: colorScheme.error,
            )
          else
            CustomAppBarAction(
              icon: Icons.search_rounded,
              tooltip: material.searchFieldLabel,
              onPressed: onSearch,
            ),
        ],
      ),
    );
  }
}
