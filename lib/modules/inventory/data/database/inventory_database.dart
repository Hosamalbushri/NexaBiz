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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products (name)',
      );
    },
  );

  static QueryExecutor _openConnection() {
    // Avoid shareAcrossIsolates — it can leave the first watch hung before
    // any row (including an empty list) is emitted.
    return driftDatabase(name: 'inventory_products');
  }
}
