enum AccountingRuleSeverity {
  error,
  warning,
}

class AccountingValidationRuleResult {
  const AccountingValidationRuleResult({
    required this.rule,
    required this.severity,
    required this.reason,
    required this.actionableMessage,
    this.affectedField,
  });

  final String rule;
  final AccountingRuleSeverity severity;
  final String reason;
  final String actionableMessage;
  final String? affectedField;

  bool get isError => severity == AccountingRuleSeverity.error;

  @override
  String toString() =>
      '[$rule] ${severity.name.toUpperCase()}: $reason ($actionableMessage)';
}

class AccountingValidationReport {
  const AccountingValidationReport._({
    required this.isValid,
    required this.ruleResults,
  });

  factory AccountingValidationReport.evaluate(List<AccountingValidationRuleResult> results) {
    final hasError = results.any((r) => r.isError);
    return AccountingValidationReport._(
      isValid: !hasError,
      ruleResults: results,
    );
  }

  final bool isValid;
  final List<AccountingValidationRuleResult> ruleResults;

  List<AccountingValidationRuleResult> get errors =>
      ruleResults.where((r) => r.isError).toList();

  List<AccountingValidationRuleResult> get warnings =>
      ruleResults.where((r) => r.severity == AccountingRuleSeverity.warning).toList();
}
