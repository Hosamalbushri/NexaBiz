/// Controlled exception thrown when a financial operation requires an account binding that is missing or stale.
class AccountBindingException implements Exception {
  const AccountBindingException({
    required this.packageId,
    required this.requirementKey,
    required this.message,
  });

  final String packageId;
  final String requirementKey;
  final String message;

  @override
  String toString() =>
      'AccountBindingException [$packageId/$requirementKey]: $message';
}

/// Thrown when an account assignment violates multi-tenant company isolation rules.
class CrossCompanyAccountBindingException implements Exception {
  const CrossCompanyAccountBindingException({
    required this.activeCompanyId,
    required this.accountCompanyId,
    required this.accountUuid,
  });

  final String activeCompanyId;
  final String accountCompanyId;
  final String accountUuid;

  @override
  String toString() =>
      'CrossCompanyAccountBindingException: Cannot bind account [$accountUuid] belonging to company [$accountCompanyId] into target company [$activeCompanyId].';
}
