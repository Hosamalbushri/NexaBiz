import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../providers/count_search_provider.dart';
import '../providers/inventory_providers.dart';
import '../providers/quantity_entry_provider.dart';
import '../providers/selected_item_provider.dart';
import '../widgets/search_items_data_grid.dart';
import 'inventory_routes.dart';

class InventorySearchPage extends ConsumerStatefulWidget {
  const InventorySearchPage({super.key, this.embedded = false});

  /// When true, omit the page app bar (for rare embedded hosts).
  final bool embedded;

  @override
  ConsumerState<InventorySearchPage> createState() =>
      _InventorySearchPageState();
}

class _InventorySearchPageState extends ConsumerState<InventorySearchPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      final normalized = value.trim();
      final current = ref.read(countSearchQueryProvider);
      if (current == normalized) {
        return;
      }
      ref.read(countSearchQueryProvider.notifier).state = normalized;
      ref.read(countSearchPageIndexProvider.notifier).state = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final pagedAsync = ref.watch(pagedCountSearchProvider);
    final pageIndex = ref.watch(countSearchPageIndexProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final hasInventory = (itemsAsync.valueOrNull?.isNotEmpty ?? false);

    final body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppConstants.pagePadding,
              AppConstants.pagePadding,
              AppSpacing.sm,
            ),
            child: AppSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hint: localization.searchItemsHint,
              autofocus: false,
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                0,
                AppConstants.pagePadding,
                AppConstants.pagePadding,
              ),
              child: pagedAsync.when(
                loading: () => const AppLoading(),
                error: (error, _) => AppErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(pagedCountSearchProvider),
                ),
                data: (paged) {
                  if (paged.totalCount == 0) {
                    if (!hasInventory) {
                      return AppEmptyState(
                        title: localization.inventoryEmptyNeedsImportTitle,
                        subtitle:
                            localization.inventoryEmptyNeedsImportMessage,
                        icon: Icons.upload_file_outlined,
                        actionLabel: localization.inventoryGoToImport,
                        actionIcon: Icons.upload_file_outlined,
                        actionVariant: AppButtonVariant.text,
                        onAction: () => context.push(InventoryRoutes.import),
                      );
                    }
                    return AppEmptyState(
                      title: localization.emptyStateTitle,
                      subtitle: localization.emptyStateSubtitle,
                    );
                  }

                  return SearchItemsDataGrid(
                    items: paged.items,
                    totalCount: paged.totalCount,
                    page: pageIndex,
                    pageSize: kSearchPageSize,
                    statusLabel: (status) => _statusLabel(localization, status),
                    onPageChanged: (page) {
                      ref.read(countSearchPageIndexProvider.notifier).state =
                          page;
                    },
                    onItemSelected: _selectItem,
                  );
                },
              ),
            ),
          ),
        ],
    );

    if (widget.embedded) {
      return Material(color: Theme.of(context).colorScheme.surface, child: body);
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: localization.searchItems,
        showBackButton: true,
      ),
      body: body,
    );
  }

  void _selectItem(InventoryItem item) {
    ref.read(selectedItemProvider.notifier).state = item;
    final mainText = _formatQuantity(item.mainQuantity);
    final subText = _formatQuantity(item.subQuantity);
    ref.read(quantityEntryProvider.notifier).setQuantities(
          mainText: mainText,
          secondaryText: subText,
        );
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

  String _statusLabel(AppLocalizations localization, ItemStatus status) {
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
}
