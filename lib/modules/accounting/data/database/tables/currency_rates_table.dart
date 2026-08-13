import 'package:drift/drift.dart';

/// Exchange rates relative to the company base currency.
@DataClassName('CurrencyRateRow')
class CurrencyRates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// ISO-like currency code (e.g. `USD`). Unique.
  TextColumn get currencyCode => text().withLength(min: 3, max: 8).unique()();

  /// Units of **base** currency for 1 unit of [currencyCode].
  /// Example: base SAR, USD rate `3.75` means 1 USD = 3.75 SAR.
  RealColumn get rateToBase => real()();

  IntColumn get updatedAt => integer()();

  TextColumn get notes => text().nullable()();
}
