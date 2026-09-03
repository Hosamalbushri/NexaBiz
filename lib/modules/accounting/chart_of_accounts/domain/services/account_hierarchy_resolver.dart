import '../entities/account.dart';
import '../repositories/account_repository.dart';

/// Authoritative domain service managing Chart of Accounts tree hierarchy resolution.
///
/// Guarantees:
/// 1. Tenant Isolation: All operations strictly filter by [companyId].
/// 2. Direct Children: [getChildren] returns immediate child accounts of [parentUuid].
/// 3. Recursive Descendants: [getDescendants] returns all nested descendants down the tree.
/// 4. Leaf/Empty Parent Safety: Empty descendants return an empty list `[]` without throwing exceptions or crashing.
class AccountHierarchyResolver {
  const AccountHierarchyResolver(this._accountRepository);

  final AccountRepository _accountRepository;

  /// Returns direct children of [parentUuid] matching tenant [companyId].
  Future<List<Account>> getChildren({
    required String companyId,
    required String parentUuid,
    bool includeInactive = false,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanParentUuid = parentUuid.trim();
    if (cleanCompanyId.isEmpty || cleanParentUuid.isEmpty) {
      return const [];
    }

    final children = await _accountRepository.getChildren(cleanParentUuid);
    return children.where((a) {
      if (!includeInactive && (!a.isActive || a.isDeleted)) {
        return false;
      }
      if (a.companyId != null && a.companyId!.isNotEmpty) {
        return a.companyId == cleanCompanyId;
      }
      return true;
    }).toList(growable: false);
  }

  /// Returns all recursive descendants of [parentUuid] matching tenant [companyId].
  ///
  /// For parent A with children B and E, and B having children C and D:
  /// `getDescendants(A)` returns `[B, C, D, E]`.
  Future<List<Account>> getDescendants({
    required String companyId,
    required String parentUuid,
    bool includeInactive = false,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanParentUuid = parentUuid.trim();
    if (cleanCompanyId.isEmpty || cleanParentUuid.isEmpty) {
      return const [];
    }

    final allAccounts = await _accountRepository.getAll(includeInactive: includeInactive);
    final tenantAccounts = allAccounts.where((a) {
      if (a.companyId != null && a.companyId!.isNotEmpty) {
        return a.companyId == cleanCompanyId;
      }
      return true;
    }).toList(growable: false);

    final parentToChildrenMap = <String, List<Account>>{};
    for (final account in tenantAccounts) {
      final parentId = account.parentId;
      if (parentId != null && parentId.isNotEmpty) {
        parentToChildrenMap.putIfAbsent(parentId, () => []).add(account);
      }
    }

    final descendants = <Account>[];
    final visited = <String>{cleanParentUuid};

    void collectDescendants(String currentParentId) {
      final children = parentToChildrenMap[currentParentId] ?? const [];
      for (final child in children) {
        if (visited.add(child.uuid)) {
          descendants.add(child);
          collectDescendants(child.uuid);
        }
      }
    }

    collectDescendants(cleanParentUuid);
    return descendants;
  }
}
