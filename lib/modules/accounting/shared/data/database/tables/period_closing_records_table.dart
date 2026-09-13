import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Immutable closing result for one accounting period (idempotent).
@DataClassName('PeriodClosingRecordRow')
class PeriodClosingRecords extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  TextColumn get fiscalYearId => text().withLength(min: 36, max: 36)();

  TextColumn get periodId => text().withLength(min: 36, max: 36)();

  IntColumn get closingDate => integer()();

  /// `completed` | `failed`
  TextColumn get status => text().withLength(min: 1, max: 16)();

  BoolColumn get fxRevaluationEnabled =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get fxRevaluationExecuted =>
      boolean().withDefault(const Constant(false))();

  TextColumn get fxSkipReason => text().nullable()();

  RealColumn get fxGain => real().withDefault(const Constant(0))();

  RealColumn get fxLoss => real().withDefault(const Constant(0))();

  RealColumn get netFxDifference => real().withDefault(const Constant(0))();

  TextColumn get journalEntryId => text().nullable()();

  TextColumn get createdBy => text().nullable()();

  IntColumn get createdAt => integer()();

  /// Company / Tenant owner ID for local multi-tenant data isolation.
  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
