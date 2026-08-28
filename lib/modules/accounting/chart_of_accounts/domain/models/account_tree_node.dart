import '../entities/account.dart';

/// Hierarchical view model for Chart of Accounts UI.
class AccountTreeNode {
  const AccountTreeNode({
    required this.account,
    this.children = const [],
  });

  final Account account;
  final List<AccountTreeNode> children;

  bool get hasChildren => children.isNotEmpty;

  /// Recursively counts all descendant nodes under this tree node.
  int get descendantCount {
    var count = 0;
    void walk(AccountTreeNode n) {
      for (final child in n.children) {
        count++;
        walk(child);
      }
    }
    walk(this);
    return count;
  }

  /// Builds a forest from a flat account list (any order).
  static List<AccountTreeNode> buildForest(List<Account> accounts) {
    final byParent = <String?, List<Account>>{};
    for (final account in accounts) {
      byParent.putIfAbsent(account.parentId, () => []).add(account);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    }

    List<AccountTreeNode> buildChildren(String? parentId) {
      final kids = byParent[parentId] ?? const <Account>[];
      return [
        for (final account in kids)
          AccountTreeNode(
            account: account,
            children: buildChildren(account.uuid),
          ),
      ];
    }

    return buildChildren(null);
  }

  /// Flattens visible nodes given which group UUIDs are expanded.
  static List<AccountTreeFlatEntry> flatten(
    List<AccountTreeNode> roots, {
    required Set<String> expandedIds,
    String? selectedId,
  }) {
    final result = <AccountTreeFlatEntry>[];

    void walk(AccountTreeNode node, int depth) {
      result.add(
        AccountTreeFlatEntry(
          node: node,
          depth: depth,
          isExpanded: expandedIds.contains(node.account.uuid),
          isSelected: selectedId == node.account.uuid,
        ),
      );
      if (node.hasChildren && expandedIds.contains(node.account.uuid)) {
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

class AccountTreeFlatEntry {
  const AccountTreeFlatEntry({
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.isSelected,
  });

  final AccountTreeNode node;
  final int depth;
  final bool isExpanded;
  final bool isSelected;

  Account get account => node.account;
  bool get isRoot => depth == 0;
}
