import 'package:drift/drift.dart';

/// Immutable closing result for one accounting period (idempotent).
@DataClassName('PeriodClosingRecordRow')
class PeriodClosingRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get fiscalYearUuid => text().withLength(min: 36, max: 36)();

  TextColumn get periodUuid => text().withLength(min: 36, max: 36)();

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

  TextColumn get journalEntryUuid => text().nullable()();

  TextColumn get createdBy => text().nullable()();

  IntColumn get createdAt => integer()();
}
