import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/migration/legacy_database_migrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Physical Schema & FK Audit', () async {
    final freshDb = NexabizDatabase.memory();

    // Query all tables from sqlite_master
    final tables = await freshDb
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
        )
        .get();

    final tableNames = tables.map((r) => r.read<String>('name')).toList();
    print(
      'PHYSICAL_AUDIT: Total physical SQLite tables created: ${tableNames.length}',
    );
    print('PHYSICAL_AUDIT: Tables: $tableNames');

    int totalFks = 0;
    final fksByTable = <String, List<Map<String, dynamic>>>{};
    for (final t in tableNames) {
      final fkList = await freshDb
          .customSelect('PRAGMA foreign_key_list($t);')
          .get();
      if (fkList.isNotEmpty) {
        fksByTable[t] = fkList.map((r) => r.data).toList();
        totalFks += fkList.length;
      }
    }
    print(
      'PHYSICAL_AUDIT: Tables with physical SQLite foreign keys: ${fksByTable.keys.toList()}',
    );
    for (final entry in fksByTable.entries) {
      print('PHYSICAL_AUDIT:   Table: ${entry.key} -> FKs: ${entry.value}');
    }
    print(
      'PHYSICAL_AUDIT: Total foreign keys across entire database: $totalFks',
    );

    await freshDb.close();
  });

  test('Failure Injection & Crash Audit', () async {
    final failExecutor = NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = OFF;');
        rawDb.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            item_code TEXT,
            name TEXT,
            created_at INTEGER,
            updated_at INTEGER
          );
        ''');
        rawDb.execute(
          "INSERT INTO products VALUES (1, 'PROD-1', 'Product 1', 1000, 1000);",
        );
        rawDb.execute(
          "INSERT INTO products VALUES (2, 'PROD-2', 'Product 2', 1000, 1000);",
        );
        rawDb.execute('PRAGMA user_version = 1;');
      },
    );

    final failDb = NexabizDatabase.connect(failExecutor);
    // Simulate crash after rename
    await failDb.customStatement(
      'ALTER TABLE products RENAME TO _legacy_products;',
    );
    await failDb.close();

    // Reopen
    final recoverDb = NexabizDatabase.connect(failExecutor);
    final pExists = await recoverDb
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='products';",
        )
        .get();
    final legacyExists = await recoverDb
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='_legacy_products';",
        )
        .get();
    print(
      'FAILURE_INJECTION: products exists: ${pExists.isNotEmpty}, _legacy_products exists: ${legacyExists.isNotEmpty}',
    );

    final migrator = LegacyDatabaseMigrator(recoverDb);
    await migrator.migrateFromLegacy(
      migrator: Migrator(recoverDb),
      fromVersion: 1,
      toVersion: 13,
    );

    final prodExistsAfter = await recoverDb
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='products';",
        )
        .get();
    print(
      'FAILURE_INJECTION: After migration re-run, products table exists: ${prodExistsAfter.isNotEmpty}',
    );
    await recoverDb.close();
  });

  test('Unmigrated Tables (Sales) Legacy Schema Upgrade', () async {
    final unmigratedExecutor = NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = OFF;');
        rawDb.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY,
            invoice_number TEXT,
            total_amount REAL,
            company_id INTEGER
          );
        ''');
        rawDb.execute("INSERT INTO sales VALUES (1, 'INV-001', 500.0, 10);");
        rawDb.execute('PRAGMA user_version = 1;');
      },
    );

    final unmigratedDb = NexabizDatabase.connect(unmigratedExecutor);
    try {
      await unmigratedDb.customSelect('SELECT 1;').get();
      final sInfo = await unmigratedDb
          .customSelect('PRAGMA table_info(sales);')
          .get();
      print(
        'UNMIGRATED_SALES: sales columns: ${sInfo.map((r) => "${r.read<String>('name')}:${r.read<String>('type')}").toList()}',
      );
      final sRows = await unmigratedDb
          .customSelect('SELECT * FROM sales;')
          .get();
      print(
        'UNMIGRATED_SALES: sales rows: ${sRows.map((r) => r.data).toList()}',
      );
    } catch (e) {
      print('UNMIGRATED_SALES: Failed with error: $e');
    } finally {
      await unmigratedDb.close();
    }
  });

  test('Multi-Tenant Legacy ID Collision in _legacy_id_mappings', () async {
    final mapDb = NexabizDatabase.memory();
    await mapDb.customStatement('''
      CREATE TABLE IF NOT EXISTS _legacy_id_mappings (
        entity_type TEXT NOT NULL,
        legacy_id TEXT NOT NULL,
        new_uuid TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (entity_type, legacy_id),
        UNIQUE (entity_type, new_uuid)
      );
    ''');
    // Tenant A product id 1
    await mapDb.customStatement(
      "INSERT INTO _legacy_id_mappings VALUES ('products', '1', 'uuid-prod-1-tenant-A', 1000);",
    );
    try {
      // Tenant B product id 1
      await mapDb.customStatement(
        "INSERT INTO _legacy_id_mappings VALUES ('products', '1', 'uuid-prod-1-tenant-B', 1000);",
      );
      print('MAPPING_COLLISION: Inserted duplicate legacy_id!');
    } catch (e) {
      print(
        'MAPPING_COLLISION: Collision as expected: PRIMARY KEY (entity_type, legacy_id) rejects same legacy_id from different tenant! Error: $e',
      );
    }
    await mapDb.close();
  });
}
