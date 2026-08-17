import 'package:drift/drift.dart';

/// Fiscal year header (owns accounting periods).
@DataClassName('FiscalYearRow')
class FiscalYears extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get code => text().withLength(min: 1, max: 32)();

  TextColumn get name => text().withLength(min: 1, max: 128)();

  /// Inclusive start (UTC day epoch ms).
  IntColumn get startDate => integer()();

  /// Inclusive end (UTC day epoch ms).
  IntColumn get endDate => integer()();

  /// `open` | `closed`
  TextColumn get status => text().withLength(min: 1, max: 16)();

  TextColumn get baseCurrencyCode => text().withLength(min: 3, max: 8)();

  IntColumn get periodCount => integer()();

  /// `monthly` (extensible).
  TextColumn get periodFrequency =>
      text().withDefault(const Constant('monthly'))();

  BoolColumn get fxRevaluationEnabled =>
      boolean().withDefault(const Constant(false))();

  TextColumn get fxGainAccountUuid => text().nullable()();

  TextColumn get fxLossAccountUuid => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get closedAt => integer().nullable()();

  TextColumn get createdBy => text().nullable()();

  TextColumn get closedBy => text().nullable()();

  TextColumn get syncStatus =>
      text().withLength(min: 1, max: 16).withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();
}
