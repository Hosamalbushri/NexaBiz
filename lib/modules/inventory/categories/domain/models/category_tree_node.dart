import '../entities/category.dart';

/// Hierarchical view model for Inventory Categories Tree UI.
class CategoryTreeNode {
  const CategoryTreeNode({
    required this.category,
    this.children = const [],
  });

  final Category category;
  final List<CategoryTreeNode> children;

  bool get hasChildren => children.isNotEmpty;

  /// Builds a forest from a flat category list (any order).
  static List<CategoryTreeNode> buildForest(List<Category> categories) {
    final byParent = <String?, List<Category>>{};
    for (final cat in categories) {
      byParent.putIfAbsent(cat.parentId, () => []).add(cat);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.code.compareTo(b.code));
    }

    List<CategoryTreeNode> buildChildren(String? parentId) {
      final kids = byParent[parentId] ?? const <Category>[];
      return [
        for (final cat in kids)
          CategoryTreeNode(
            category: cat,
            children: buildChildren(cat.id),
          ),
      ];
    }

    return buildChildren(null);
  }

  /// Flattens visible nodes given which group UUIDs are expanded.
  static List<CategoryTreeFlatEntry> flatten(
    List<CategoryTreeNode> roots, {
    required Set<String> expandedIds,
    String? selectedId,
  }) {
    final result = <CategoryTreeFlatEntry>[];

    void walk(CategoryTreeNode node, int depth) {
      result.add(
        CategoryTreeFlatEntry(
          node: node,
          depth: depth,
          isExpanded: expandedIds.contains(node.category.id),
          isSelected: selectedId == node.category.id,
        ),
      );
      if (node.hasChildren && expandedIds.contains(node.category.id)) {
        for (final child in node.children) {
          walk(child, depth + 1);
        }
      }
    }

    for (final root in roots) {
      walk(root, 0);
    }
    return result;
  }
}

class CategoryTreeFlatEntry {
  const CategoryTreeFlatEntry({
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.isSelected,
  });

  final CategoryTreeNode node;
  final int depth;
  final bool isExpanded;
  final bool isSelected;

  Category get category => node.category;
}
