import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Exchange Rates table.
/// Rate is stored as INTEGER scaled by 10^8 (`rate_scaled`).
@DataClassName('FinancialExchangeRateData')
class FinancialExchangeRates extends Table {
  /// Canonical UUID v7 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Source currency ISO code (e.g. USD).
  TextColumn get fromCurrencyCode => text().withLength(min: 1, max: 8)();

  /// Destination currency ISO code (e.g. YER).
  TextColumn get toCurrencyCode => text().withLength(min: 1, max: 8)();

  /// Exchange rate value scaled by 10^8 (INTEGER).
  /// Example: 1 SAR = 140 YER => rateScaled = 14000000000.
  Int64Column get rateScaled => int64()();

  /// Timestamp when this rate became effective.
  DateTimeColumn get effectiveAt => dateTime()();

  /// Rate source/reference (e.g., 'manual', 'central_bank').
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// Whether this rate is an immutable transaction snapshot.
  BoolColumn get isImmutableSnapshot => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, fromCurrencyCode, toCurrencyCode, effectiveAt},
      ];
}
