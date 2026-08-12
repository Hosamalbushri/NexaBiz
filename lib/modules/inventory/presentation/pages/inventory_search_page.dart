import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../providers/count_search_provider.dart';
import '../providers/quantity_entry_provider.dart';
import '../providers/selected_item_provider.dart';
import '../widgets/catalog_expandable_search.dart';
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
  var _searchExpanded = false;

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

  void _setSearchExpanded(bool value) {
    if (_searchExpanded == value) {
      return;
    }
    setState(() => _searchExpanded = value);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final pagedAsync = ref.watch(pagedCountSearchProvider);
    final pageIndex = ref.watch(countSearchPageIndexProvider);
    final pageSize = ref.watch(countSearchPageSizeProvider);
    final searchQuery = ref.watch(countSearchQueryProvider);

    final results = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        0,
        AppConstants.pagePadding,
        AppConstants.pagePadding,
      ),
      child: pagedAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(pagedCountSearchProvider),
        ),
        data: (paged) {
          if (paged.totalCount == 0) {
            if (searchQuery.isEmpty) {
              return AppEmptyState(
                title: localization.inventoryEmptyNeedsImportTitle,
                subtitle: localization.inventoryEmptyNeedsImportMessage,
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
            pageSize: pageSize,
            statusLabel: (status) => _statusLabel(localization, status),
            onPageChanged: (page) {
              ref.read(countSearchPageIndexProvider.notifier).state = page;
            },
            onPageSizeChanged: (size) {
              if (ref.read(countSearchPageSizeProvider) == size) {
                return;
              }
              ref.read(countSearchPageSizeProvider.notifier).state = size;
              ref.read(countSearchPageIndexProvider.notifier).state = 0;
            },
            onItemSelected: _selectItem,
          );
        },
      ),
    );

    final body = Column(
      children: [
        CatalogExpandableSearchPanel(
          expanded: _searchExpanded,
          onExpandedChanged: _setSearchExpanded,
          controller: _searchController,
          focusNode: _searchFocusNode,
          searchField: ref.watch(countSearchFieldProvider),
          onQueryChanged: _onQueryChanged,
          onSearchFieldChanged: (field) {
            if (ref.read(countSearchFieldProvider) == field) {
              return;
            }
            ref.read(countSearchFieldProvider.notifier).state = field;
            ref.read(countSearchPageIndexProvider.notifier).state = 0;
          },
        ),
        Expanded(child: results),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: body,
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
        _onQueryChanged('');
        _setSearchExpanded(false);
      },
      child: Scaffold(
        // Shrink the results area with the keyboard so the list fills
        // whatever space remains under the search panel.
        resizeToAvoidBottomInset: true,
        appBar: CustomAppBar(
          title: localization.searchItems,
          showBackButton: true,
          showSearch: !_searchExpanded,
          onSearch: () => _setSearchExpanded(true),
          showCloseSearch: _searchExpanded,
          onCloseSearch: () => _setSearchExpanded(false),
        ),
        body: body,
      ),
    );
  }

  void _selectItem(InventoryItem item) {
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

  String _statusLabel(AppLocalizations localization, ItemStatus status) {
    return switch (status) {
      ItemStatus.matched => localization.matchedStatus,
      ItemStatus.shortage => localization.shortageStatus,
      ItemStatus.overage => localization.overageStatus,
      ItemStatus.notCounted => localization.notCountedStatus,
    };
  }
}
