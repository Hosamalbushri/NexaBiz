import 'accounting_failure.dart';

/// Structured validation result produced by Accounting Domain Authority.
class AccountingValidationResult {
  const AccountingValidationResult._({
    required this.isValid,
    this.failures = const [],
    this.warnings = const [],
  });

  factory AccountingValidationResult.success([List<String> warnings = const []]) =>
      AccountingValidationResult._(isValid: true, warnings: warnings);

  factory AccountingValidationResult.failure(List<AccountingFailure> failures) =>
      AccountingValidationResult._(isValid: false, failures: failures);

  factory AccountingValidationResult.singleFailure(AccountingFailure failure) =>
      AccountingValidationResult._(isValid: false, failures: [failure]);

  final bool isValid;
  final List<AccountingFailure> failures;
  final List<String> warnings;
}
