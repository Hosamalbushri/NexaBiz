import 'decimal_money.dart';

/// Canonical Financial Operation Types with non-overrideable system rounding policies.
enum FinancialOperationType {
  /// Currency conversion operation (e.g. USD to YER conversion): standard Half-Up.
  currencyConversion,

  /// Multi-line journal rounding / allocation balancing: Half-Even (Banker's rounding).
  journalAllocation,

  /// General financial balance & tax calculations: Half-Up.
  financialCalculation,

  /// Reporting aggregation / display truncation: Truncate.
  reportingDisplay,
}

/// Canonical manager enforcing fixed, deterministic financial rounding rules.
class CanonicalRoundingPolicy {
  /// Resolves the mandatory canonical [FinancialRoundingMode] for a given [FinancialOperationType].
  static FinancialRoundingMode getRoundingMode(FinancialOperationType operationType) {
    switch (operationType) {
      case FinancialOperationType.currencyConversion:
        return FinancialRoundingMode.halfUp;

      case FinancialOperationType.journalAllocation:
        return FinancialRoundingMode.halfEven;

      case FinancialOperationType.financialCalculation:
        return FinancialRoundingMode.halfUp;

      case FinancialOperationType.reportingDisplay:
        return FinancialRoundingMode.truncate;
    }
  }

  /// Canonical rounding function for [DecimalMoney] ensuring identical results regardless of caller.
  static DecimalMoney round({
    required DecimalMoney money,
    required int decimalPlaces,
    required FinancialOperationType operationType,
  }) {
    final mode = getRoundingMode(operationType);
    return money.roundToDigits(decimalPlaces, roundingMode: mode);
  }
}
