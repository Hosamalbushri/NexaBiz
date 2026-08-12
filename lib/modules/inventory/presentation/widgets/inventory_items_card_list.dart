import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_breakpoints.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_pagination_bar.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../models/products_view_mode.dart';

/// Shared list/grid preference for inventory item cards (search + reports).
final inventoryItemsViewModeProvider = StateProvider<ProductsViewMode>(
  (ref) => ProductsViewMode.list,
);

/// Card-based inventory item list/grid matching the products page language.
class InventoryItemsCardList extends ConsumerWidget {
  const InventoryItemsCardList({
    super.key,
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
    required this.statusLabel,
    this.onItemSelected,
    this.pageSizeOptions = const [],
    this.onPageSizeChanged,
  });

  final List<InventoryItem> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final String Function(ItemStatus status) statusLabel;
  final ValueChanged<InventoryItem>? onItemSelected;
  final List<int> pageSizeOptions;
  final ValueChanged<int>? onPageSizeChanged;

  /// Below this height, drop the pager so the list can use the remaining space
  /// (e.g. when the keyboard is open).
  static const double _minHeightForPagination = 140;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewMode = ref.watch(inventoryItemsViewModeProvider);
    final totalPages = totalCount == 0 ? 0 : (totalCount / pageSize).ceil();

    final results = viewMode == ProductsViewMode.grid
        ? _InventoryItemsGrid(
            items: items,
            statusLabel: statusLabel,
            onItemSelected: onItemSelected,
          )
        : ListView.separated(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return InventoryItemCard(
                item: item,
                statusLabel: statusLabel(item.status),
                onTap: onItemSelected == null
                    ? null
                    : () => onItemSelected!(item),
              );
            },
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showPagination = !constraints.hasBoundedHeight ||
            constraints.maxHeight >= _minHeightForPagination;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localization.searchResultsCount(totalCount),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _InventoryViewModeToggle(
                    viewMode: viewMode,
                    onChanged: (mode) {
                      ref.read(inventoryItemsViewModeProvider.notifier).state =
                          mode;
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: results),
            if (showPagination)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: AppPaginationBar(
                  page: page,
                  totalPages: totalPages,
                  totalCount: totalCount,
                  pageSize: pageSize,
                  pageSizeOptions: pageSizeOptions,
                  onPageChanged: onPageChanged,
                  onPageSizeChanged: onPageSizeChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InventoryItemsGrid extends StatelessWidget {
  const _InventoryItemsGrid({
    required this.items,
    required this.statusLabel,
    this.onItemSelected,
  });

  final List<InventoryItem> items;
  final String Function(ItemStatus status) statusLabel;
  final ValueChanged<InventoryItem>? onItemSelected;

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
        final aspectRatio = AppBreakpoints.isMobile(width) ? 0.9 : 1.0;

        return GridView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return InventoryItemGridCard(
              item: item,
              statusLabel: statusLabel(item.status),
              onTap: onItemSelected == null
                  ? null
                  : () => onItemSelected!(item),
            );
          },
        );
      },
    );
  }
}

/// List-style inventory item card.
class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
    required this.statusLabel,
    this.onTap,
  });

  final InventoryItem item;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tone = _toneFor(item.status);

    return RepaintBoundary(
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
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
                          item.itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _CodeBadge(code: item.itemCode),
                            AppStatusBadge(
                              label: statusLabel,
                              tone: tone,
                              animate: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const _CardNavAffordance(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid-style inventory item card.
class InventoryItemGridCard extends StatelessWidget {
  const InventoryItemGridCard({
    super.key,
    required this.item,
    required this.statusLabel,
    this.onTap,
  });

  final InventoryItem item;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tone = _toneFor(item.status);

    return RepaintBoundary(
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
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
                      AppStatusBadge(
                        label: statusLabel,
                        tone: tone,
                        animate: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _CodeBadge(code: item.itemCode),
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

class _InventoryViewModeToggle extends StatelessWidget {
  const _InventoryViewModeToggle({
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

AppStatusTone _toneFor(ItemStatus status) {
  return switch (status) {
    ItemStatus.matched => AppStatusTone.success,
    ItemStatus.shortage => AppStatusTone.warning,
    ItemStatus.overage => AppStatusTone.info,
    ItemStatus.notCounted => AppStatusTone.neutral,
  };
}

/// Compact forward affordance that follows reading direction.
class _CardNavAffordance extends StatelessWidget {
  const _CardNavAffordance();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: 36,
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

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
