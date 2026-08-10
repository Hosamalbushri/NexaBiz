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
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/product_exception.dart';
import '../models/products_view_mode.dart';
import '../providers/product_providers.dart';
import 'inventory_routes.dart';
import 'product_barcode_scanner_page.dart';

class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pagedAsync = ref.watch(pagedProductsProvider);
    final pageIndex = ref.watch(productSearchPageIndexProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);
    final viewMode =
        ref.watch(productsViewModeProvider).valueOrNull ?? ProductsViewMode.list;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.productsListTitle,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppSpacing.md,
              AppConstants.pagePadding,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: l10n.productsSearchHint,
                  onChanged: _onQueryChanged,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProductsToolbar(
                  viewMode: viewMode,
                  onViewModeChanged: (mode) {
                    ref.read(productsViewModeProvider.notifier).setMode(mode);
                  },
                  onScan: () => _scanAndOpenProduct(context),
                  onAdd: () => InventoryRoutes.pushProductsNew(context),
                ),
              ],
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
                        actionLabel: l10n.productsAdd,
                        actionIcon: Icons.add_rounded,
                        onAction: () =>
                            InventoryRoutes.pushProductsNew(context),
                      );
                    }
                    return AppEmptyState(
                      title: l10n.emptyStateTitle,
                      subtitle: l10n.emptyStateSubtitle,
                      icon: Icons.search_off_rounded,
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: viewMode == ProductsViewMode.grid
                            ? _ProductsGrid(
                                products: paged.items,
                                onEdit: (product) =>
                                    InventoryRoutes.pushProductsEdit(
                                  context,
                                  product.id,
                                ),
                                onDelete: (product) =>
                                    _deleteProduct(context, ref, product),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                itemCount: paged.items.length,
                                itemBuilder: (context, index) {
                                  final product = paged.items[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == paged.items.length - 1
                                          ? 0
                                          : AppSpacing.sm,
                                    ),
                                    child: _ProductListCard(
                                      key: ValueKey(product.id),
                                      product: product,
                                      onEdit: () =>
                                          InventoryRoutes.pushProductsEdit(
                                        context,
                                        product.id,
                                      ),
                                      onDelete: () => _deleteProduct(
                                        context,
                                        ref,
                                        product,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      _ProductsPager(
                        page: pageIndex,
                        totalPages: paged.totalPages,
                        totalCount: paged.totalCount,
                        pageSize: kProductsPageSize,
                        onPageChanged: (page) {
                          ref
                              .read(productSearchPageIndexProvider.notifier)
                              .state = page;
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanAndOpenProduct(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final code = await ProductBarcodeScannerPage.open(context);
    if (!context.mounted || code == null || code.isEmpty) {
      return;
    }

    final product =
        await ref.read(getProductByBarcodeUseCaseProvider).call(code);
    if (!context.mounted) {
      return;
    }
    if (product == null) {
      showAppSnackBar(
        context,
        message: l10n.productsBarcodeNotFound,
        isSuccess: false,
      );
      return;
    }
    InventoryRoutes.pushProductsEdit(context, product.id);
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
      showAppSnackBar(
        context,
        message: error.code,
        isSuccess: false,
      );
    }
  }
}

class _ProductsToolbar extends StatelessWidget {
  const _ProductsToolbar({
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onScan,
    required this.onAdd,
  });

  final ProductsViewMode viewMode;
  final ValueChanged<ProductsViewMode> onViewModeChanged;
  final VoidCallback onScan;
  final VoidCallback onAdd;

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
            _ViewModeToggle(
              viewMode: viewMode,
              onChanged: onViewModeChanged,
            ),
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
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

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
    required this.onEdit,
    required this.onDelete,
  });

  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

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
              onEdit: () => onEdit(product),
              onDelete: () => onDelete(product),
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
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          product.itemCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
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
                      ],
                    ),
                  ),
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
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    product.itemCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${l10n.packSize} ${product.packSize}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsPager extends StatelessWidget {
  const _ProductsPager({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final canPrev = page > 0;
    final canNext = totalPages > 0 && page < totalPages - 1;
    final from = totalCount == 0 ? 0 : page * pageSize + 1;
    final to =
        totalCount == 0 ? 0 : ((page + 1) * pageSize).clamp(0, totalCount);

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                localization.paginationRange(from, to, totalCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              tooltip: localization.previousPage,
              onPressed: canPrev ? () => onPageChanged(page - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              localization.paginationPage(
                totalPages == 0 ? 0 : page + 1,
                totalPages,
              ),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              tooltip: localization.nextPage,
              onPressed: canNext ? () => onPageChanged(page + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
