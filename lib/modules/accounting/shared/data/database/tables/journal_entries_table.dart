import 'package:drift/drift.dart';

/// Journal entry header (Accounting ledger).
@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Business date (UTC epoch ms, date portion).
  IntColumn get entryDate => integer()();

  TextColumn get voucherNumber => text().withLength(min: 1, max: 64)();

  /// Display type e.g. بيع آجل
  TextColumn get voucherType => text().withLength(min: 1, max: 64)();

  TextColumn get description => text().nullable()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  BoolColumn get isPosted => boolean().withDefault(const Constant(true))();

  /// Origin module document type (`sale`, …).
  TextColumn get sourceType => text().nullable()();

  /// Origin document UUID.
  TextColumn get sourceId => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// [SyncStatus.name]
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  TextColumn get companyId => text().nullable()();

  IntColumn get deletedAt => integer().nullable()();
}
