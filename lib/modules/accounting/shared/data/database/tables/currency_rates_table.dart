import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Exchange rates relative to the company base currency.
@DataClassName('CurrencyRateRow')
class CurrencyRates extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// ISO-like currency code (e.g. `USD`). Unique per company.
  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  /// Units of **base** currency for 1 unit of [currencyCode].
  /// Example: base SAR, USD rate `3.75` means 1 USD = 3.75 SAR.
  RealColumn get rateToBase => real()();

  IntColumn get updatedAt => integer()();

  TextColumn get notes => text().nullable()();

  TextColumn get syncStatus => text()
      .withLength(min: 1, max: 16)
      .withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, currencyCode},
      ];
}
