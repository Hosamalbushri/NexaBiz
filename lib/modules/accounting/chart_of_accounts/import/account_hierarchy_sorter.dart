/// Topological sorter for hierarchical account import rows.
///
/// Ensures parent accounts (e.g. 1000 Assets) are ordered and processed
/// before dependent child accounts (e.g. 1100 Current Assets, 1110 Cash).
class AccountHierarchySorter {

  const AccountHierarchySorter._();

  /// Sorts raw import rows topologically by parent account code/name references.
  ///
  /// Rows without a parent reference or whose parent is already in the database
  /// are placed first, followed by child accounts in dependency order.
  static List<Map<String, dynamic>> sortRows({
    required List<Map<String, dynamic>> rows,
    required String parentFieldKey,
    required String codeFieldKey,
    required String nameFieldKey,
    Set<String> existingDbParentIdentifiers = const {},
  }) {
    if (rows.isEmpty) return const [];

    final rowByCode = <String, Map<String, dynamic>>{};
    final rowByName = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final code = row[codeFieldKey]?.toString().trim() ?? '';
      final name = row[nameFieldKey]?.toString().trim() ?? '';

      if (code.isNotEmpty) {
        rowByCode[code.toLowerCase()] = row;
      }
      if (name.isNotEmpty) {
        rowByName[name.toLowerCase()] = row;
      }
    }

    final sorted = <Map<String, dynamic>>[];
    final visited = <Map<String, dynamic>>{};
    final visiting = <Map<String, dynamic>>{};

    void visit(Map<String, dynamic> row) {
      if (visited.contains(row)) return;
      if (visiting.contains(row)) {
        // Circular parent dependency detected — break cycle gracefully
        sorted.add(row);
        visited.add(row);
        return;
      }

      visiting.add(row);

      final parentTerm = row[parentFieldKey]?.toString().trim() ?? '';
      if (parentTerm.isNotEmpty) {
        final cleanParent = parentTerm.toLowerCase();

        // If parent exists in current batch and hasn't been processed, visit parent first
        if (!existingDbParentIdentifiers.contains(cleanParent)) {
          final parentRow = rowByCode[cleanParent] ?? rowByName[cleanParent];
          if (parentRow != null && parentRow != row) {
            visit(parentRow);
          }
        }
      }

      visiting.remove(row);
      visited.add(row);
      sorted.add(row);
    }

    for (final row in rows) {
      if (!visited.contains(row)) {
        visit(row);
      }
    }

    return sorted;
  }
}
