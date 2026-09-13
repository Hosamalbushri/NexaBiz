import '../validation/accounting_validation_report.dart';

class JournalIntegrityReport {
  final List<AccountingValidationRuleResult> errors = [];

  bool get isValid => errors.isEmpty;

  void addError({
    required String rule,
    required String message,
    String? field,
  }) {
    errors.add(AccountingValidationRuleResult(
      rule: rule,
      reason: message,
      actionableMessage: message,
      severity: AccountingRuleSeverity.error,
      affectedField: field,
    ));
  }
}
