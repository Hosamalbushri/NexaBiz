import 'package:drift/drift.dart';

/// Chart of Accounts table (Accounting module).
@DataClassName('AccountRow')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID for offline-safe identity / sync / future FKs.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Parent account UUID; null for roots.
  TextColumn get parentId => text().nullable()();

  TextColumn get accountCode => text().withLength(min: 1, max: 32).unique()();

  TextColumn get name => text().withLength(min: 1, max: 512)();

  TextColumn get description => text().nullable()();

  /// [AccountType.name]
  TextColumn get accountType => text().withLength(min: 1, max: 32)();

  /// [NormalBalance.name]
  TextColumn get normalBalance => text().withLength(min: 1, max: 16)();

  IntColumn get level => integer().withDefault(const Constant(0))();

  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  BoolColumn get isSystemAccount =>
      boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// [SyncStatus.name]
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Soft-delete tombstone (UTC epoch ms). Null = not deleted.
  IntColumn get deletedAt => integer().nullable()();
}
