/// Account Currency Policy defining allowed transactional currencies and valuation balance tracking.
enum AccountCurrencyPolicy {
  /// Multi-currency bucketed account policy (used for Customer AR and Supplier AP).
  ///
  /// Maintains distinct sub-ledger currency buckets for each currency transacted.
  multiCurrencyBucketed,

  /// Single fixed currency account policy (used for Cash, Bank, Card, Wallet).
  ///
  /// All postings to this account MUST be in its assigned fixed currency.
  singleFixedCurrency,

  /// Functional base currency valuation account policy (used for Revenue, Expense, Inventory, COGS, FX).
  ///
  /// Transactions may originate in foreign currencies, but valuation/balance is maintained strictly in functional base currency.
  functionalOnly;

  static AccountCurrencyPolicy fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'MULTI_CURRENCY_BUCKETED':
      case 'MULTICURRENCYBUCKETED':
        return AccountCurrencyPolicy.multiCurrencyBucketed;
      case 'SINGLE_FIXED_CURRENCY':
      case 'SINGLEFIXEDCURRENCY':
        return AccountCurrencyPolicy.singleFixedCurrency;
      case 'FUNCTIONAL_ONLY':
      case 'FUNCTIONALONLY':
        return AccountCurrencyPolicy.functionalOnly;
      default:
        throw ArgumentError('Unknown AccountCurrencyPolicy: $raw');
    }
  }

  String toDbValue() {
    switch (this) {
      case AccountCurrencyPolicy.multiCurrencyBucketed:
        return 'MULTI_CURRENCY_BUCKETED';
      case AccountCurrencyPolicy.singleFixedCurrency:
        return 'SINGLE_FIXED_CURRENCY';
      case AccountCurrencyPolicy.functionalOnly:
        return 'FUNCTIONAL_ONLY';
    }
  }
}
