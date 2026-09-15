import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Period Closing Attempts failure audit log table (GATE-08 V4).
@DataClassName('FinancialPeriodClosingAttemptData')
class FinancialPeriodClosingAttempts extends Table {
  /// Primary key UUID v7.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Target period ID.
  TextColumn get periodId => text().withLength(min: 36, max: 36)();

  /// Reference to closing operation ID (if initiated).
  TextColumn get closingOperationId => text().nullable()();

  /// UTC epoch ms timestamp of attempt.
  IntColumn get attemptedAt => integer()();

  /// Status: 'failed', 'aborted'.
  TextColumn get status => text().withLength(min: 1, max: 16)();

  /// Reason for failure/abort.
  TextColumn get failureReason => text()();

  TextColumn get attemptedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
