import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Companies table in `nexabiz.sqlite`.
@DataClassName('CompanyData')
class Companies extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Unique company code.
  TextColumn get code => text().unique()();

  /// Company display name.
  TextColumn get name => text()();

  /// Financial reporting base currency (e.g. YER).
  TextColumn get baseCurrencyCode => text().withDefault(const Constant('YER'))();

  /// Inventory valuation currency (e.g. SAR).
  TextColumn get inventoryCurrencyCode => text().withDefault(const Constant('SAR'))();

  /// Company status: 'active', 'disabled', 'archived'.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Epoch timestamp of company creation.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Epoch timestamp of last company update.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {id},
      ];
}
