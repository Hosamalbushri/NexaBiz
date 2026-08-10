import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../domain/entities/item_status.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/models/report_export_labels.dart';
import '../../domain/models/report_export_result.dart';
import '../providers/inventory_providers.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_items_data_grid.dart';
import '../widgets/report_status_chart.dart';

class InventoryReportsPage extends ConsumerStatefulWidget {
  const InventoryReportsPage({super.key});

  @override
  ConsumerState<InventoryReportsPage> createState() =>
      _InventoryReportsPageState();
}

class _InventoryReportsPageState extends ConsumerState<InventoryReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

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
    final summary = ref.watch(reportSummaryProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final pagedAsync = ref.watch(pagedReportItemsProvider);
    final exportState = ref.watch(reportExportProvider);
    final pageIndex = ref.watch(reportPageIndexProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: localization.reportsTitle,
        showBackButton: true,
        actions: [
          CustomAppBarAction(
            icon: Icons.print_rounded,
            tooltip: localization.exportReport,
            onPressed: exportState.isLoading ? null : _showExportOptions,
            isLoading: exportState.isLoading,
          ),
        ],
        bottom: TabBar(
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
        ),
      ),
      body: itemsAsync.when(
        loading: () => const AppLoading(style: AppLoadingStyle.skeletonList),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(inventoryItemsProvider),
        ),
        data: (_) {
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(inventoryItemsProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.pagePadding),
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth >= 700 ? 3 : 2;
                          final childAspectRatio =
                              constraints.maxWidth >= 700 ? 1.35 : 1.05;
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
                      AppSearchBar(
                        controller: _searchController,
                        hint: localization.search,
                        onChanged: (value) {
                          ref.read(reportsSearchQueryProvider.notifier).state =
                              value;
                          ref.read(reportPageIndexProvider.notifier).state = 0;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                              pageSize: kReportPageSize,
                              onPageChanged: (page) {
                                ref
                                    .read(reportPageIndexProvider.notifier)
                                    .state = page;
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

  Future<void> _showExportOptions() async {
    final localization = AppLocalizations.of(context);
    final validationError =
        ref.read(reportExportProvider.notifier).validateBeforeExport();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(localization.exportExcel),
            onTap: () => Navigator.pop(context, ReportExportFormat.excel),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(localization.exportPdf),
            onTap: () => Navigator.pop(context, ReportExportFormat.pdf),
          ),
        ],
      ),
    );

    if (format == null || !mounted) {
      return;
    }
    await _exportReport(format);
  }

  Future<void> _exportReport(ReportExportFormat format) async {
    final localization = AppLocalizations.of(context);
    final labels = _exportLabels(localization);
    final result = await ref.read(reportExportProvider.notifier).exportReport(
          format: format,
          labels: labels,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(localization.exportPath(path)),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: localization.shareExport,
                icon: Icons.share_outlined,
                expand: true,
                onPressed: () {
                  ref
                      .read(reportExportProvider.notifier)
                      .shareExportedFile(path);
                },
              ),
            ],
          ),
        );
    }
  }

  ReportExportLabels _exportLabels(AppLocalizations localization) {
    final locale = Localizations.localeOf(context);
    final isRtl = locale.languageCode == 'ar' ||
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
