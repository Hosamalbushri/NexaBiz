import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Journal entry line (debit or credit against one account).
@DataClassName('JournalLineRow')
class JournalLines extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Parent [JournalEntries.id].
  TextColumn get entryId => text().withLength(min: 36, max: 36)();

  /// Posting account ID ([Accounts.id]).
  TextColumn get accountId => text().withLength(min: 36, max: 36)();

  RealColumn get debit => real().withDefault(const Constant(0))();

  RealColumn get credit => real().withDefault(const Constant(0))();

  /// Units of company base currency per 1 unit of [currencyCode] at booking.
  RealColumn get exchangeRateToBase => real().withDefault(const Constant(1))();

  /// Debit amount in company base currency.
  RealColumn get baseDebit => real().withDefault(const Constant(0))();

  /// Credit amount in company base currency.
  RealColumn get baseCredit => real().withDefault(const Constant(0))();

  TextColumn get lineDescription => text().nullable()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
