import 'package:flutter/material.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

import '../../domain/entities/category.dart';
import '../../domain/models/category_tree_node.dart';

/// Extension providing conversion of domain category tree nodes to canonical NexaBizTree nodes.
extension CategoryTreeNodeNexaBizAdapter on List<CategoryTreeNode> {
  /// Converts a list of domain [CategoryTreeNode] into canonical [NexaBizTreeNode]s.
  List<NexaBizTreeNode<CategoryTreeNode>> toNexaBizTreeNodes({
    required Set<String> expandedIds,
    String? selectedId,
  }) {
    return map((node) {
      return NexaBizTreeItemNode<CategoryTreeNode>(
        data: node,
        expanded: expandedIds.contains(node.category.id),
        selected: selectedId == node.category.id,
        children: node.children.toNexaBizTreeNodes(
          expandedIds: expandedIds,
          selectedId: selectedId,
        ),
      );
    }).toList();
  }
}

/// Reusable hierarchical Inventory Category tree widget built directly on canonical [NexaBizTree].
///
/// Refactored to pass domain data and callbacks directly to [NexaBizTree] and [NexaBizTreeNodeRow],
/// ensuring 100% presentation design system ownership within `nexabiz_ui`.
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

    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final nexabizNodes = roots.toNexaBizTreeNodes(
      expandedIds: expandedIds,
      selectedId: selectedId,
    );

    return NexaBizTree<CategoryTreeNode>(
      shrinkWrap: true,
      padding: padding,
      branchLine: NexaBizBranchLine.path,
      nodes: nexabizNodes,
      builder: (context, node) {
        final categoryNode = node.data;
        final category = categoryNode.category;
        final level = AppTree.computeNodeLevel<CategoryTreeNode>(node, nexabizNodes);

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

        return NexaBizTreeNodeRow<CategoryTreeNode>(
          title: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(
              category.isGroup
                  ? Icons.folder_special_rounded
                  : Icons.sell_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          level: level,
          badges: [
            AppStatusBadge(
              label: category.isGroup
                  ? (isAr ? 'رئيسي' : 'Group')
                  : (isAr ? 'فرعي' : 'Leaf'),
              tone: category.isGroup
                  ? AppStatusTone.neutral
                  : AppStatusTone.info,
              animate: false,
            ),
            AppStatusBadge(
              label: badgeLabel,
              tone: badgeTone,
              animate: false,
            ),
          ],
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              category.code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
          onAddChild: onAddSubcategory != null
              ? () => onAddSubcategory!(category)
              : null,
          onEdit: onEditCategory != null
              ? () => onEditCategory!(category)
              : null,
          onDelete: onDeleteCategory != null
              ? () => onDeleteCategory!(category)
              : null,
        );
      },
    );
  }
}
