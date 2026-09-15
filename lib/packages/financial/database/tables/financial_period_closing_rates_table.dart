import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Period Closing Rates snapshot table (GATE-08 V4).
/// Stores closing rates scaled by 10^8 as INTEGER.
@DataClassName('FinancialPeriodClosingRateData')
class FinancialPeriodClosingRates extends Table {
  /// Primary key UUID v7.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Reference to closing operation ID.
  TextColumn get closingOperationId => text().withLength(min: 36, max: 36)();

  /// Source currency ISO code.
  TextColumn get fromCurrencyCode => text()();

  /// Target currency ISO code.
  TextColumn get toCurrencyCode => text()();

  /// Scaled exchange rate ($10^8$ integer scale).
  Int64Column get exchangeRateScaled => int64()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, closingOperationId, fromCurrencyCode, toCurrencyCode},
      ];
}
