import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/products_table.dart';

part 'inventory_database.g.dart';

@DriftDatabase(tables: [Products])
class InventoryDatabase extends _$InventoryDatabase {
  InventoryDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// In-memory database for tests.
  InventoryDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createSearchIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await customStatement(
          "ALTER TABLE products ADD COLUMN uuid TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          "ALTER TABLE products ADD COLUMN sync_status TEXT NOT NULL "
          "DEFAULT 'synced'",
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN last_synced_at INTEGER NULL',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN deleted_at INTEGER NULL',
        );
        await customStatement(
          "UPDATE products SET uuid = printf("
          "'00000000-0000-4000-8000-%012d', id) "
          "WHERE uuid IS NULL OR uuid = ''",
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_products_uuid '
          'ON products (uuid)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_sync ON products (sync_status)',
        );
      }
      if (from < 3) {
        await _createSearchIndexes();
      }
    },
  );

  Future<void> _createSearchIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_name ON products (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_sync ON products (sync_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_alive '
      'ON products (item_code) WHERE deleted_at IS NULL',
    );
  }

  static QueryExecutor _openConnection() {
    // Avoid shareAcrossIsolates — it can leave the first watch hung before
    // any row (including an empty list) is emitted.
    return driftDatabase(name: 'inventory_products');
  }
}
