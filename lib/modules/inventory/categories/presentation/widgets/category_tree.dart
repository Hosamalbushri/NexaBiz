import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

import '../../domain/entities/category.dart';
import '../../domain/models/category_tree_node.dart';

/// Reusable hierarchical Inventory Category tree widget mirroring Chart of Accounts `AccountTree`.
class CategoryTree extends StatelessWidget {
  const CategoryTree({
    super.key,
    required this.roots,
    required this.expandedIds,
    required this.onToggleExpand,
    required this.warehouse,
    this.selectedId,
    this.onAddSubcategory,
    this.onEditCategory,
    this.onDeleteCategory,
    this.padding = EdgeInsets.zero,
  });

  final List<CategoryTreeNode> roots;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggleExpand;
  final Warehouse warehouse;
  final String? selectedId;
  final ValueChanged<Category>? onAddSubcategory;
  final ValueChanged<Category>? onEditCategory;
  final ValueChanged<Category>? onDeleteCategory;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (roots.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: roots.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return _CategorySection(
              node: roots[index],
              expandedIds: expandedIds,
              selectedId: selectedId,
              warehouse: warehouse,
              onToggleExpand: onToggleExpand,
              onAddSubcategory: onAddSubcategory,
              onEditCategory: onEditCategory,
              onDeleteCategory: onDeleteCategory,
            )
            .animate(delay: (40 * index).ms)
            .fadeIn(duration: 220.ms, curve: Curves.easeOut)
            .moveY(
              begin: 10,
              end: 0,
              duration: 240.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.node,
    required this.expandedIds,
    required this.warehouse,
    required this.onToggleExpand,
    this.selectedId,
    this.onAddSubcategory,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  final CategoryTreeNode node;
  final Set<String> expandedIds;
  final Warehouse warehouse;
  final ValueChanged<String> onToggleExpand;
  final String? selectedId;
  final ValueChanged<Category>? onAddSubcategory;
  final ValueChanged<Category>? onEditCategory;
  final ValueChanged<Category>? onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final category = node.category;

    final accentColor = colorScheme.primary;
    final expanded = expandedIds.contains(category.id);
    final childEntries = expanded
        ? CategoryTreeNode.flatten(
            node.children,
            expandedIds: expandedIds,
            selectedId: selectedId,
          )
        : const <CategoryTreeFlatEntry>[];

    // Valuation status
    final AppStatusTone badgeTone;
    final String badgeLabel;

    if (category.costValuationMethod == CostValuationMethod.fifo) {
      badgeTone = AppStatusTone.info;
      badgeLabel = 'FIFO';
    } else if (category.costValuationMethod == CostValuationMethod.lifo) {
      badgeTone = AppStatusTone.warning;
      badgeLabel = 'LIFO';
    } else if (category.costValuationMethod ==
        CostValuationMethod.weightedAverage) {
      badgeTone = AppStatusTone.success;
      badgeLabel = isAr ? 'متوسط مرجح' : 'W. Average';
    } else {
      badgeTone = AppStatusTone.neutral;
      badgeLabel = isAr ? 'وراثة تلقائية' : 'Inherited';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Root Header Bar
            Material(
              color: accentColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.22 : 0.08,
              ),
              child: InkWell(
                onTap: node.hasChildren
                    ? () => onToggleExpand(category.id)
                    : () => onEditCategory?.call(category),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Group Avatar Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          category.isGroup
                              ? Icons.folder_special_rounded
                              : Icons.sell_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Title & Subtitle Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (category.isGroup) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  AppStatusBadge(
                                    label: isAr ? 'رئيسي' : 'Group',
                                    tone: AppStatusTone.neutral,
                                    animate: false,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AppStatusBadge(
                                  label: badgeLabel,
                                  tone: badgeTone,
                                  animate: false,
                                ),
                                if (node.hasChildren) ...[
                                  Text(
                                    ' · ',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${_countDescendants(node)} ${isAr ? 'تصنيف فرعي' : 'subcategories'}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Code Badge
                      _TrailingCode(
                        code: category.code,
                        emphasis: true,
                        color: accentColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),

                      // Action Popup Menu
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        onSelected: (val) {
                          if (val == 'add_child') {
                            onAddSubcategory?.call(category);
                          } else if (val == 'edit') {
                            onEditCategory?.call(category);
                          } else if (val == 'delete') {
                            onDeleteCategory?.call(category);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'add_child',
                            child: Row(
                              children: [
                                const Icon(Icons.create_new_folder_outlined,
                                    size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Text(isAr ? 'إضافة فرعي' : 'Add Subcategory'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Text(isAr ? 'تعديل' : 'Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: colorScheme.error),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  isAr ? 'حذف' : 'Delete',
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (node.hasChildren)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.xxs,
                          ),
                          child: AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Children Indented Rows
            if (expanded && childEntries.isNotEmpty) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              for (var i = 0; i < childEntries.length; i++) ...[
                _CategoryChildRow(
                  entry: childEntries[i],
                  accentColor: colorScheme.secondary,
                  onToggleExpand: childEntries[i].node.hasChildren
                      ? () => onToggleExpand(childEntries[i].category.id)
                      : null,
                  onAddSubcategory: onAddSubcategory,
                  onEditCategory: onEditCategory,
                  onDeleteCategory: onDeleteCategory,
                ),
                if (i < childEntries.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg +
                        (childEntries[i].depth + 1) * AppSpacing.md,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  int _countDescendants(CategoryTreeNode node) {
    var count = 0;
    void walk(CategoryTreeNode n) {
      for (final child in n.children) {
        count++;
        walk(child);
      }
    }

    walk(node);
    return count;
  }
}

class _CategoryChildRow extends StatelessWidget {
  const _CategoryChildRow({
    required this.entry,
    required this.accentColor,
    this.onToggleExpand,
    this.onAddSubcategory,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  final CategoryTreeFlatEntry entry;
  final Color accentColor;
  final VoidCallback? onToggleExpand;
  final ValueChanged<Category>? onAddSubcategory;
  final ValueChanged<Category>? onEditCategory;
  final ValueChanged<Category>? onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final category = entry.category;

    final depthInset = (entry.depth + 1) * AppSpacing.md;
    final selected = entry.isSelected;

    // Valuation status
    final AppStatusTone badgeTone;
    final String badgeLabel;

    if (category.costValuationMethod == CostValuationMethod.fifo) {
      badgeTone = AppStatusTone.info;
      badgeLabel = 'FIFO';
    } else if (category.costValuationMethod == CostValuationMethod.lifo) {
      badgeTone = AppStatusTone.warning;
      badgeLabel = 'LIFO';
    } else if (category.costValuationMethod ==
        CostValuationMethod.weightedAverage) {
      badgeTone = AppStatusTone.success;
      badgeLabel = isAr ? 'متوسط مرجح' : 'W. Average';
    } else {
      badgeTone = AppStatusTone.neutral;
      badgeLabel = isAr ? 'وراثة تلقائية' : 'Inherited';
    }

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (entry.node.hasChildren && onToggleExpand != null) {
            onToggleExpand!();
          } else {
            onEditCategory?.call(category);
          }
        },
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.md + depthInset,
            end: AppSpacing.xs,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: entry.node.hasChildren
                    ? InkWell(
                        onTap: onToggleExpand,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: AnimatedRotation(
                          turns: entry.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 22,
                            color: accentColor.withValues(alpha: 0.9),
                          ),
                        ),
                      )
                    : Icon(
                        category.isGroup
                            ? Icons.folder_outlined
                            : Icons.sell_outlined,
                        size: category.isGroup ? 18 : 16,
                        color: accentColor.withValues(alpha: 0.85),
                      ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: category.isGroup
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: category.isActive
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppStatusBadge(
                          label: category.isGroup
                              ? (isAr ? 'رئيسي' : 'Group')
                              : (isAr ? 'فرعي' : 'Leaf'),
                          tone: category.isGroup
                              ? AppStatusTone.neutral
                              : AppStatusTone.info,
                          animate: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AppStatusBadge(
                      label: badgeLabel,
                      tone: badgeTone,
                      animate: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Code Badge
              _TrailingCode(code: category.code, color: accentColor),

              // Action Popup Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                onSelected: (val) {
                  if (val == 'add_child') {
                    onAddSubcategory?.call(category);
                  } else if (val == 'edit') {
                    onEditCategory?.call(category);
                  } else if (val == 'delete') {
                    onDeleteCategory?.call(category);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'add_child',
                    child: Row(
                      children: [
                        const Icon(Icons.create_new_folder_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(isAr ? 'إضافة فرعي' : 'Add Subcategory'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(isAr ? 'تعديل' : 'Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: colorScheme.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isAr ? 'حذف' : 'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailingCode extends StatelessWidget {
  const _TrailingCode({
    required this.code,
    required this.color,
    this.emphasis = false,
  });

  final String code;
  final Color color;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: EdgeInsets.symmetric(
        horizontal: emphasis ? 10 : 8,
        vertical: emphasis ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontSize: emphasis ? 13 : 11,
        ),
      ),
    );
  }
}
