import 'package:drift/drift.dart';

/// Exchange rates relative to the company base currency.
@DataClassName('CurrencyRateRow')
class CurrencyRates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Sync identity (stable across devices). Business key remains [currencyCode].
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// ISO-like currency code (e.g. `USD`). Unique.
  TextColumn get currencyCode => text().withLength(min: 3, max: 8).unique()();

  /// Units of **base** currency for 1 unit of [currencyCode].
  /// Example: base SAR, USD rate `3.75` means 1 USD = 3.75 SAR.
  RealColumn get rateToBase => real()();

  IntColumn get updatedAt => integer()();

  TextColumn get notes => text().nullable()();

  TextColumn get syncStatus =>
      text().withLength(min: 1, max: 16).withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  TextColumn get companyId => text().nullable()();
}
