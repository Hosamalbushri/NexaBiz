import 'package:drift/drift.dart';

/// Daily history of exchange rates vs company base currency.
@DataClassName('CurrencyRateHistoryRow')
class CurrencyRateHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  /// UTC midnight of the rate day (milliseconds since epoch).
  IntColumn get asOfDate => integer()();

  /// Units of base currency for 1 unit of [currencyCode].
  RealColumn get rateToBase => real()();

  IntColumn get createdAt => integer()();

  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {currencyCode, asOfDate},
      ];
}
