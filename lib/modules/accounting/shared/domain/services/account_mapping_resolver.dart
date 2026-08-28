enum AccountRole {
  revenue,
  receivable,
  payable,
  cash,
  inventory,
  cogs,
  tax,
  discount,
  inventoryFrom,
  inventoryTo,
}

class AccountRoleRef {
  const AccountRoleRef({
    required this.role,
    required this.accountUuid,
    required this.accountCode,
    required this.accountName,
  });

  final AccountRole role;
  final String accountUuid;
  final String accountCode;
  final String accountName;
}

class AccountMapping {
  const AccountMapping(this.accounts);

  final Map<AccountRole, AccountRoleRef> accounts;

  AccountRoleRef? getRole(AccountRole role) => accounts[role];

  void assertRequiredRoles(List<AccountRole> requiredRoles) {
    final missing = <AccountRole>[];
    for (final role in requiredRoles) {
      if (!accounts.containsKey(role)) {
        missing.add(role);
      }
    }
    if (missing.isNotEmpty) {
      final roleNames = missing.map((r) => r.name).join(', ');
      throw StateError('خطأ محاسبي: لم يتم تحديد الحسابات التالية للعملية: $roleNames');
    }
  }
}

abstract class AccountMappingResolver {
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  });
}
