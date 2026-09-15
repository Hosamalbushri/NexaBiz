import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// General Ledger Account balances table.
/// Balances and totals are stored as INTEGER scaled by 10^8 (`balance_scaled`, `debit_total_scaled`, `credit_total_scaled`).
@DataClassName('FinancialAccountBalanceData')
class FinancialAccountBalances extends Table {
  /// Canonical UUID v7 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Account ID in FinancialAccounts.
  TextColumn get accountId => text()();

  /// Currency ISO code (functional or account fixed currency).
  TextColumn get currencyCode => text().withLength(min: 1, max: 8)();

  /// Accumulated net balance scaled by 10^8.
  Int64Column get balanceScaled => int64().withDefault(Constant(BigInt.zero))();

  /// Total cumulative debit postings scaled by 10^8.
  Int64Column get debitTotalScaled => int64().withDefault(Constant(BigInt.zero))();

  /// Total cumulative credit postings scaled by 10^8.
  Int64Column get creditTotalScaled => int64().withDefault(Constant(BigInt.zero))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, accountId, currencyCode},
      ];
}
