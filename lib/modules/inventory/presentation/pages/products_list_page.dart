import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_breakpoints.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_pagination_bar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/product_exception.dart';
import '../../permissions/inventory_permission_package.dart';
import '../models/products_view_mode.dart';
import '../providers/product_providers.dart';
import '../widgets/catalog_expandable_search.dart';
import 'inventory_routes.dart';
import 'product_barcode_scanner_page.dart';

class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
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
      final current = ref.read(productSearchQueryProvider);
      if (current == normalized) {
        return;
      }
      ref.read(productSearchQueryProvider.notifier).state = normalized;
      ref.read(productSearchPageIndexProvider.notifier).state = 0;
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
    final l10n = AppLocalizations.of(context);
    final pagedAsync = ref.watch(pagedProductsProvider);
    final pageIndex = ref.watch(productSearchPageIndexProvider);
    final pageSize = ref.watch(productPageSizeProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);
    final viewMode =
        ref.watch(productsViewModeProvider).valueOrNull ??
        ProductsViewMode.list;
    final auth = ref.watch(authStateProvider);
    final canCreate = auth.hasAnyPermission(InventoryPermissions.productsCreate);
    final canUpdate = auth.hasAnyPermission(InventoryPermissions.productsUpdate);
    final canDelete = auth.hasAnyPermission(InventoryPermissions.productsDelete);

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
        // Keep list layout stable while the search field is focused.
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(
          title: l10n.productsListTitle,
          showBackButton: true,
          showSearch: !_searchExpanded,
          onSearch: () => _setSearchExpanded(true),
          showCloseSearch: _searchExpanded,
          onCloseSearch: () => _setSearchExpanded(false),
        ),
        body: Column(
          children: [
            CatalogExpandableSearchPanel(
              expanded: _searchExpanded,
              onExpandedChanged: _setSearchExpanded,
              controller: _searchController,
              focusNode: _searchFocusNode,
              searchField: ref.watch(productSearchFieldProvider),
              onQueryChanged: _onQueryChanged,
              onSearchFieldChanged: (field) {
                if (ref.read(productSearchFieldProvider) == field) {
                  return;
                }
                ref.read(productSearchFieldProvider.notifier).state = field;
                ref.read(productSearchPageIndexProvider.notifier).state = 0;
              },
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                _searchExpanded ? 0 : AppSpacing.md,
                AppConstants.pagePadding,
                AppSpacing.sm,
              ),
              child: _ProductsToolbar(
                viewMode: viewMode,
                onViewModeChanged: (mode) {
                  ref.read(productsViewModeProvider.notifier).setMode(mode);
                },
                onScan: () => _scanAndOpenProduct(context),
                onAdd: canCreate
                    ? () => InventoryRoutes.pushProductsNew(context)
                    : null,
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
                    onRetry: () => ref.invalidate(pagedProductsProvider),
                  ),
                  data: (paged) {
                    if (paged.totalCount == 0) {
                      if (searchQuery.isEmpty) {
                        return AppEmptyState(
                          title: l10n.productsEmptyTitle,
                          subtitle: l10n.productsEmptyMessage,
                          icon: Icons.inventory_2_outlined,
                          actionLabel: canCreate ? l10n.productsAdd : null,
                          actionIcon: Icons.add_rounded,
                          onAction: canCreate
                              ? () => InventoryRoutes.pushProductsNew(context)
                              : null,
                        );
                      }
                      return AppEmptyState(
                        title: l10n.emptyStateTitle,
                        subtitle: l10n.emptyStateSubtitle,
                        icon: Icons.search_off_rounded,
                      );
                    }

                    return _ProductsResults(
                      key: ValueKey(
                        '${viewMode.name}-$pageIndex-$pageSize-'
                        '${paged.totalCount}-'
                        '${paged.items.isEmpty ? 0 : paged.items.first.id}',
                      ),
                      products: paged.items,
                      viewMode: viewMode,
                      page: pageIndex,
                      pageSize: pageSize,
                      totalPages: paged.totalPages,
                      totalCount: paged.totalCount,
                      onPageChanged: (page) {
                        ref.read(productSearchPageIndexProvider.notifier).state =
                            page;
                      },
                      onPageSizeChanged: (size) {
                        if (ref.read(productPageSizeProvider) == size) {
                          return;
                        }
                        ref.read(productPageSizeProvider.notifier).state = size;
                        ref.read(productSearchPageIndexProvider.notifier).state =
                            0;
                      },
                      onEdit: canUpdate
                          ? (product) => InventoryRoutes.pushProductsEdit(
                                context,
                                product.id,
                              )
                          : null,
                      onDelete: canDelete
                          ? (product) =>
                              _deleteProduct(context, ref, product)
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanAndOpenProduct(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final code = await ProductBarcodeScannerPage.open(context);
    if (!context.mounted || code == null || code.isEmpty) {
      return;
    }

    final resolution = await ref
        .read(productScanResolverProvider)
        .resolve(code);
    if (!context.mounted) {
      return;
    }
    if (resolution == null || !resolution.fromCatalog) {
      showAppSnackBar(
        context,
        message: resolution?.fromProductQr == true
            ? l10n.productsQrScanOfflineData
            : l10n.productsBarcodeNotFound,
        isSuccess: false,
      );
      return;
    }
    if (resolution.fromProductQr) {
      showAppSnackBar(
        context,
        message: l10n.productsQrScanRecognized,
        isSuccess: true,
      );
    }
    InventoryRoutes.pushProductsEdit(context, resolution.product.id);
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog(
      context: context,
      title: l10n.productsDeleteConfirmTitle,
      message: l10n.productsDeleteConfirmMessage,
      confirmLabel: l10n.productsDelete,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(deleteProductUseCaseProvider).call(product.id);
      bumpProductsRevisionFromWidget(ref);
      final page = ref.read(productSearchPageIndexProvider);
      final refreshed = await ref.refresh(pagedProductsProvider.future);
      if (refreshed.items.isEmpty && page > 0) {
        ref.read(productSearchPageIndexProvider.notifier).state = page - 1;
      }
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.productsDeletedSuccess,
        isSuccess: true,
      );
    } on ProductException catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: error.code, isSuccess: false);
    }
  }
}

/// Product list/grid with a fixed pagination bar at the bottom.
class _ProductsResults extends StatefulWidget {
  const _ProductsResults({
    super.key,
    required this.products,
    required this.viewMode,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalCount,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.onEdit,
    this.onDelete,
  });

  final List<Product> products;
  final ProductsViewMode viewMode;
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onDelete;

  @override
  State<_ProductsResults> createState() => _ProductsResultsState();
}

class _ProductsResultsState extends State<_ProductsResults> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _ProductsResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page ||
        oldWidget.pageSize != widget.pageSize ||
        oldWidget.viewMode != widget.viewMode ||
        oldWidget.products.length != widget.products.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        _scrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.viewMode == ProductsViewMode.grid
              ? _ProductsGrid(
                  products: widget.products,
                  controller: _scrollController,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.products.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _ProductListCard(
                        key: ValueKey(product.id),
                        product: product,
                        onEdit: widget.onEdit == null
                            ? null
                            : () => widget.onEdit!(product),
                        onDelete: widget.onDelete == null
                            ? null
                            : () => widget.onDelete!(product),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: AppPaginationBar(
            page: widget.page,
            totalPages: widget.totalPages,
            totalCount: widget.totalCount,
            pageSize: widget.pageSize,
            pageSizeOptions: kProductsPageSizeOptions,
            onPageChanged: widget.onPageChanged,
            onPageSizeChanged: widget.onPageSizeChanged,
          ),
        ),
      ],
    );
  }
}

class _ProductsToolbar extends StatelessWidget {
  const _ProductsToolbar({
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onScan,
    this.onAdd,
  });

  final ProductsViewMode viewMode;
  final ValueChanged<ProductsViewMode> onViewModeChanged;
  final VoidCallback onScan;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            _ViewModeToggle(viewMode: viewMode, onChanged: onViewModeChanged),
            const Spacer(),
            Tooltip(
              message: l10n.productsScanBarcode,
              child: Material(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: onScan,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.qr_code_scanner_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: colorScheme.primary,
                elevation: 2,
                shadowColor: colorScheme.primary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.productsAdd,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.viewMode, required this.onChanged});

  final ProductsViewMode viewMode;
  final ValueChanged<ProductsViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeIconButton(
            selected: viewMode == ProductsViewMode.list,
            tooltip: l10n.productsViewList,
            icon: Icons.view_list_rounded,
            onTap: () => onChanged(ProductsViewMode.list),
          ),
          _ViewModeIconButton(
            selected: viewMode == ProductsViewMode.grid,
            tooltip: l10n.productsViewGrid,
            icon: Icons.grid_view_rounded,
            onTap: () => onChanged(ProductsViewMode.grid),
          ),
        ],
      ),
    );
  }
}

class _ViewModeIconButton extends StatelessWidget {
  const _ViewModeIconButton({
    required this.selected,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
          child: SizedBox(
            width: 40,
            height: 36,
            child: Icon(
              icon,
              size: 20,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({
    required this.products,
    this.onEdit,
    this.onDelete,
    this.controller,
  });

  final List<Product> products;
  final ValueChanged<Product>? onEdit;
  final ValueChanged<Product>? onDelete;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = AppBreakpoints.isDesktop(width)
            ? 4
            : AppBreakpoints.isTablet(width)
            ? 3
            : 2;
        final aspectRatio = AppBreakpoints.isMobile(width) ? 0.78 : 0.9;

        return GridView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductGridCard(
              key: ValueKey(product.id),
              product: product,
              onEdit: onEdit == null ? null : () => onEdit!(product),
              onDelete: onDelete == null ? null : () => onDelete!(product),
            );
          },
        );
      },
    );
  }
}

String _formatPrice(double price) {
  if (price == price.roundToDouble()) {
    return price.toStringAsFixed(0);
  }
  return price.toStringAsFixed(2);
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ColoredBox(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${l10n.packSize} ${product.packSize} · ${l10n.price} ${_formatPrice(product.price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _ProductCodeBadge(code: product.itemCode),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: l10n.productsDelete,
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: ColoredBox(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (onDelete != null)
                        IconButton(
                          tooltip: l10n.productsDelete,
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${l10n.packSize} ${product.packSize}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l10n.price} ${_formatPrice(product.price)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _ProductCodeBadge(code: product.itemCode),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact product-code chip used on list and grid cards.
class _ProductCodeBadge extends StatelessWidget {
  const _ProductCodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 3,
        ),
        child: Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
