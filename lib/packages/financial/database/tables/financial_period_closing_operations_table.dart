import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Period Closing Operations execution identity table (GATE-08 V4).
@DataClassName('FinancialPeriodClosingOperationData')
class FinancialPeriodClosingOperations extends Table {
  /// Primary key UUID v7 execution identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Target period ID.
  TextColumn get periodId => text().withLength(min: 36, max: 36)();

  /// Status: 'initiated', 'in_progress', 'completed', 'failed', 'aborted'.
  TextColumn get status => text().withLength(min: 1, max: 16)();

  /// Whether FX revaluation was requested (0 = false, 1 = true).
  BoolColumn get closeWithFx => boolean().withDefault(const Constant(false))();

  IntColumn get initiatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get initiatedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
