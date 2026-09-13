import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Daily history of exchange rates vs company base currency.
@DataClassName('CurrencyRateHistoryRow')
class CurrencyRateHistory extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  /// UTC midnight of the rate day (milliseconds since epoch).
  IntColumn get asOfDate => integer()();

  /// Units of base currency for 1 unit of [currencyCode].
  RealColumn get rateToBase => real()();

  IntColumn get createdAt => integer()();

  TextColumn get notes => text().nullable()();

  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, currencyCode, asOfDate},
      ];
}
