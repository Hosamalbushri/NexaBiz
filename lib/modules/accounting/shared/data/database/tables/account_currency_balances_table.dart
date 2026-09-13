import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Table storing per-account and per-currency aggregate balances (Accounting module).
@DataClassName('AccountCurrencyBalanceRow')
class AccountCurrencyBalances extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Posting account ID ([Accounts.id]).
  TextColumn get accountId => text().withLength(min: 36, max: 36)();

  /// ISO currency code (e.g. 'YER', 'SAR', 'USD').
  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  /// Aggregate total debit in this currency.
  RealColumn get totalDebit => real().withDefault(const Constant(0))();

  /// Aggregate total credit in this currency.
  RealColumn get totalCredit => real().withDefault(const Constant(0))();

  /// Net balance in this currency (debit - credit).
  RealColumn get netBalance => real().withDefault(const Constant(0))();

  /// Company / Tenant owner ID for multi-tenant isolation.
  TextColumn get companyId => text().nullable()();

  /// Last updated UTC epoch ms.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, accountId, currencyCode},
      ];
}
