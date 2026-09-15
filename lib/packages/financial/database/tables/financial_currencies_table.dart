import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Currencies table.
@DataClassName('FinancialCurrencyData')
class FinancialCurrencies extends Table {
  /// Canonical UUID primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Currency ISO/Standard Code (e.g., USD, YER, SAR).
  TextColumn get code => text().withLength(min: 1, max: 8)();

  /// Arabic display name.
  TextColumn get nameAr => text().withDefault(const Constant(''))();

  /// English display name.
  TextColumn get nameEn => text().withDefault(const Constant(''))();

  /// Display symbol (e.g. $, ر.ي, ر.س).
  TextColumn get symbol => text().withLength(min: 1, max: 16)();

  /// Minor unit decimal places (typically 2, or 3 for KWD/BHD/OMR, 0 for JPY).
  IntColumn get decimalPlaces => integer().withDefault(const Constant(2))();

  /// Whether this currency is active for company transactions.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Company scope (nullable for system-wide currencies).
  TextColumn get companyId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, code},
      ];
}
