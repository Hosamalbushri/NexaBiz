import 'package:drift/drift.dart';

/// Customers master (Customers module).
@DataClassName('CustomerRow')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID for offline-safe identity / sync.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Business code (e.g. `12210001` from parent CoA `1221`). Unique among non-deleted rows.
  TextColumn get customerCode => text().withLength(min: 1, max: 64).unique()();

  TextColumn get name => text().withLength(min: 1, max: 512)();

  TextColumn get phone => text().nullable()();

  TextColumn get email => text().nullable()();

  TextColumn get address => text().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Opaque Account.uuid (Accounting module). Null when unlinked.
  TextColumn get accountId => text().nullable()();

  /// External ERP id when data_source is external.
  TextColumn get externalId => text().nullable()();

  /// [CustomerDataSource.name]
  TextColumn get dataSource => text().withDefault(const Constant('local'))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// [SyncStatus.name] string.
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Soft-delete tombstone (UTC epoch ms). Null = active row.
  IntColumn get deletedAt => integer().nullable()();
}
