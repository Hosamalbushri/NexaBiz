import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/migration/legacy_database_migrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2C-4 Failure Injection Test Suite', () {
    test('1. Interrupted Migration Replay: Mid-migration crash recovery', () async {
      final executor = NativeDatabase.memory(
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
          rawDb.execute("INSERT INTO products VALUES (101, 'PROD-CRASH-1', 'Product 1', 1000, 1000);");
          rawDb.execute("INSERT INTO products VALUES (102, 'PROD-CRASH-2', 'Product 2', 1000, 1000);");
          
          // Simulate crash right after rename
          rawDb.execute('ALTER TABLE products RENAME TO _legacy_products;');
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);
      final migrator = LegacyDatabaseMigrator(db);
      await migrator.migrateFromLegacy(
        migrator: Migrator(db),
        fromVersion: 1,
        toVersion: 13,
      );

      final pExists = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='products';").get();
      final legacyExists = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='_legacy_products';").get();

      expect(pExists.isNotEmpty, isTrue);
      expect(legacyExists.isEmpty, isTrue);

      final count = (await db.customSelect('SELECT COUNT(*) as c FROM products;').getSingle()).read<int>('c');
      expect(count, equals(2));

      await db.close();
    });

    test('2. Fail-Closed Unmigrated Legacy Table Guard: Unknown integer table triggers StateError', () async {
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = OFF;');
          rawDb.execute('''
            CREATE TABLE unmigrated_mystery_table (
              id INTEGER PRIMARY KEY,
              secret_data TEXT
            );
          ''');
          rawDb.execute("INSERT INTO unmigrated_mystery_table VALUES (1, 'Secret');");
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);
      final migrator = LegacyDatabaseMigrator(db);

      expect(
        () => migrator.migrateFromLegacy(
          migrator: Migrator(db),
          fromVersion: 1,
          toVersion: 13,
        ),
        throwsA(isA<StateError>()),
      );

      await db.close();
    });
  });
}
