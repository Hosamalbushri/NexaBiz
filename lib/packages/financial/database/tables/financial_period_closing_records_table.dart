import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Period Closing Records completed fact table (GATE-08 V4).
@DataClassName('FinancialPeriodClosingRecordData')
class FinancialPeriodClosingRecords extends Table {
  /// Primary key UUID v7.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Fiscal year ID.
  TextColumn get fiscalYearId => text().withLength(min: 36, max: 36)();

  /// Period ID.
  TextColumn get periodId => text().withLength(min: 36, max: 36)();

  /// Reference to execution identity.
  TextColumn get closingOperationId => text().withLength(min: 36, max: 36)();

  /// UTC day epoch ms closing date.
  IntColumn get closingDate => integer()();

  /// Whether FX revaluation was executed (0 = false, 1 = true).
  BoolColumn get fxRevaluationExecuted => boolean().withDefault(const Constant(false))();

  /// Optional FX revaluation journal entry ID.
  TextColumn get journalEntryId => text().nullable()();

  TextColumn get createdBy => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, periodId},
      ];
}
