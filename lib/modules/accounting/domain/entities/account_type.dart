import 'normal_balance.dart';

/// Top-level account classification for the Chart of Accounts.
enum AccountType {
  asset,
  liability,
  equity,
  revenue,
  expense;

  /// Normal balance implied by this classification.
  NormalBalance get normalBalance => switch (this) {
    AccountType.asset || AccountType.expense => NormalBalance.debit,
    AccountType.liability ||
    AccountType.equity ||
    AccountType.revenue => NormalBalance.credit,
  };

  /// Stable storage / sync key.
  String get storageValue => name;

  static AccountType fromStorage(String value) {
    return AccountType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown type'),
    );
  }

  /// Suggested root account code band (1000–5000).
  String get defaultRootCode => switch (this) {
    AccountType.asset => '1000',
    AccountType.liability => '2000',
    AccountType.equity => '3000',
    AccountType.revenue => '4000',
    AccountType.expense => '5000',
  };
}
