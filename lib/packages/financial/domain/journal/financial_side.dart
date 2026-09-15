/// Explicit accounting side: DEBIT or CREDIT.
///
/// Under NO circumstances may debit/credit side be inferred from the sign of an amount.
enum FinancialSide {
  debit,
  credit;

  static FinancialSide fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'DEBIT':
        return FinancialSide.debit;
      case 'CREDIT':
        return FinancialSide.credit;
      default:
        throw ArgumentError('Invalid accounting side: $raw. Must be DEBIT or CREDIT.');
    }
  }

  String toDbValue() => name.toUpperCase();

  bool get isDebit => this == FinancialSide.debit;
  bool get isCredit => this == FinancialSide.credit;
}
