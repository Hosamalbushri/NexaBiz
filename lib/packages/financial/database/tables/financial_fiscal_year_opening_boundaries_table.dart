import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Fiscal Year Opening Boundaries derived projection table (GATE-08 V4).
/// Represents permanent account opening balances snapshot for performance optimization (Model A).
@DataClassName('FinancialFiscalYearOpeningBoundaryData')
class FinancialFiscalYearOpeningBoundaries extends Table {
  /// Primary key UUID v7.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Target fiscal year ID.
  TextColumn get fiscalYearId => text().withLength(min: 36, max: 36)();

  /// Permanent account ID.
  TextColumn get accountId => text().withLength(min: 36, max: 36)();

  /// Optional projection subject ID (validated at domain layer).
  TextColumn get subjectId => text().nullable()();

  /// Currency ISO code.
  TextColumn get currencyCode => text()();

  /// Opening balance scaled by 10^8 ($10^8$ integer scale).
  Int64Column get openingBalanceScaled => int64()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
