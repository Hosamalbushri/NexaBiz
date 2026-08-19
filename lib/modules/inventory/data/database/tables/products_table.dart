import 'package:drift/drift.dart';

/// Products master catalog (Inventory module).
@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID for offline-safe identity / sync.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get itemCode => text().withLength(min: 1, max: 128).unique()();

  TextColumn get name => text().withLength(min: 1, max: 512)();

  TextColumn get barcode => text().nullable().unique()();

  IntColumn get packSize => integer()();

  RealColumn get price => real()();

  /// Perpetual inventory: sellable quantity on hand (main-unit equivalents).
  RealColumn get onHandQty => real().withDefault(const Constant(0))();

  /// Unit cost for COGS (company base currency per main unit).
  RealColumn get unitCost => real().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// [SyncStatus.name] string.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Soft-delete tombstone (UTC epoch ms). Null = active.
  IntColumn get deletedAt => integer().nullable()();
}
