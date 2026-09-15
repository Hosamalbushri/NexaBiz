import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Fiscal Periods table (GATE-08 V4).
@DataClassName('FinancialFiscalPeriodData')
class FinancialFiscalPeriods extends Table {
  /// Primary key UUID v7 identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Owning fiscal year ID.
  TextColumn get fiscalYearId => text().withLength(min: 36, max: 36)();

  /// Period number (1..N).
  IntColumn get periodNumber => integer()();

  /// Period display name (e.g. 'January 2026').
  TextColumn get name => text().withLength(min: 1, max: 64)();

  /// UTC day epoch ms start date.
  IntColumn get startDate => integer()();

  /// UTC day epoch ms end date.
  IntColumn get endDate => integer()();

  /// Status: 'draft', 'open', 'closing', 'closed', 'reopened', 'locked'.
  TextColumn get status => text().withLength(min: 1, max: 16)();

  IntColumn get openedAt => integer().nullable()();
  IntColumn get closedAt => integer().nullable()();
  IntColumn get reopenedAt => integer().nullable()();
  TextColumn get reopenReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, fiscalYearId, periodNumber},
      ];
}
