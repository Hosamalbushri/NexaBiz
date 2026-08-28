class AccountValidationResult {
  const AccountValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  static const valid = AccountValidationResult(isValid: true);
}

abstract class AccountValidationService {
  /// Validates if an account can be posted to.
  /// Checks existence, isActive=true, isGroup=false, and deletedAt=null.
  Future<AccountValidationResult> validateAccountUuid(String accountUuid);

  /// Asserts that an account is valid for posting, throwing an exception if invalid.
  Future<void> assertCanPost(String accountUuid);
}
