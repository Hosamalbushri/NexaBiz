import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/app/migration/migration_integrity_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2C-4 — Existing Database Upgrade / Migration Safety Test Suite', () {
    test('1. Fresh database creation path independence', () async {
      final db = NexabizDatabase.memory();
      
      // Verify tables exist
      final tables = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table'").get();
      final tableNames = tables.map((r) => r.read<String>('name')).toSet();

      expect(tableNames, contains('companies'));
      expect(tableNames, contains('users'));
      expect(tableNames, contains('products'));
      expect(tableNames, contains('stock_receipts'));
      expect(tableNames, contains('journal_entries'));

      await db.close();
    });

    test('2. Legacy integer schema -> Canonical UUID v7 migration succeeds with 0 FK violations', () async {
      // 1. Setup raw connection and create legacy schema tables + set user_version = 1
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = OFF;');
          rawDb.execute('''
            CREATE TABLE companies (
              id INTEGER PRIMARY KEY,
              code TEXT,
              name TEXT,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');

          rawDb.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY,
              email TEXT,
              name TEXT,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');

          rawDb.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY,
              item_code TEXT,
              name TEXT,
              pack_size INTEGER,
              price REAL,
              unit_cost REAL,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');

          rawDb.execute('''
            CREATE TABLE stock_receipts (
              id INTEGER PRIMARY KEY,
              receipt_number TEXT,
              status TEXT,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');

          rawDb.execute('''
            CREATE TABLE inventory_cost_layers (
              id INTEGER PRIMARY KEY,
              item_code TEXT,
              movement_uuid TEXT,
              movement_type TEXT,
              received_date INTEGER,
              received_qty REAL,
              remaining_qty REAL,
              unit_cost REAL,
              total_cost REAL,
              currency_code TEXT,
              exchange_rate REAL,
              unit_cost_inventory_currency REAL,
              total_cost_inventory_currency REAL,
              closed INTEGER,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');

          rawDb.execute('''
            CREATE TABLE journal_entries (
              id INTEGER PRIMARY KEY,
              voucher_number TEXT,
              voucher_type TEXT,
              currency_code TEXT,
              exchange_rate REAL,
              entry_date INTEGER,
              status TEXT,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');

          rawDb.execute('''
            CREATE TABLE journal_lines (
              id INTEGER PRIMARY KEY,
              journal_id INTEGER,
              account_id INTEGER,
              currency_code TEXT,
              debit REAL,
              credit REAL,
              base_debit REAL,
              base_credit REAL,
              exchange_rate REAL,
              company_id INTEGER,
              created_at INTEGER
            );
          ''');

          // Seed representative legacy records with INTEGER identities
          const now = 1600000000000;
          rawDb.execute("INSERT INTO companies (id, code, name, created_at, updated_at) VALUES (10, 'COMP-10', 'Legacy Company 10', $now, $now);");
          rawDb.execute("INSERT INTO users (id, email, name, created_at, updated_at) VALUES (5, 'admin@legacy.com', 'Admin User', $now, $now);");
          rawDb.execute("INSERT INTO products (id, item_code, name, pack_size, price, unit_cost, company_id, created_at, updated_at) VALUES (101, 'ITEM-MIG-101', 'Legacy Laptop', 1, 1000.0, 700.0, 10, $now, $now);");
          rawDb.execute("INSERT INTO stock_receipts (id, receipt_number, status, company_id, created_at, updated_at) VALUES (50, 'REC-LEG-50', 'posted', 10, $now, $now);");

          // Multi-currency purchase: 20 SAR * 140 YER/SAR = 2800 YER base equivalent
          rawDb.execute('''
            INSERT INTO inventory_cost_layers 
            (id, item_code, movement_uuid, movement_type, received_date, received_qty, remaining_qty, unit_cost, total_cost, currency_code, exchange_rate, unit_cost_inventory_currency, total_cost_inventory_currency, closed, company_id, created_at, updated_at)
            VALUES (30, 'ITEM-MIG-101', '50', 'receipt', $now, 1.0, 1.0, 20.0, 20.0, 'SAR', 140.0, 2800.0, 2800.0, 0, 10, $now, $now);
          ''');

          rawDb.execute("INSERT INTO journal_entries (id, voucher_number, voucher_type, currency_code, exchange_rate, entry_date, status, company_id, created_at, updated_at) VALUES (200, 'JE-LEG-200', 'journal', 'SAR', 140.0, $now, 'posted', 10, $now, $now);");
          rawDb.execute("INSERT INTO journal_lines (id, journal_id, account_id, currency_code, debit, credit, base_debit, base_credit, exchange_rate, company_id, created_at) VALUES (1001, 200, 500, 'SAR', 20.0, 0.0, 2800.0, 0.0, 140.0, 10, $now);");
          rawDb.execute("INSERT INTO journal_lines (id, journal_id, account_id, currency_code, debit, credit, base_debit, base_credit, exchange_rate, company_id, created_at) VALUES (1002, 200, 600, 'SAR', 0.0, 20.0, 0.0, 2800.0, 140.0, 10, $now);");

          // Set database user_version = 1 so Drift triggers onUpgrade(from: 1, to: 13)
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);

      // Trigger schema upgrade via customSelect or query to force opening
      await db.customSelect('SELECT COUNT(*) FROM companies;').getSingle();

      // 3. Verify SQLite foreign key integrity: PRAGMA foreign_key_check;
      await db.customStatement('PRAGMA foreign_keys = ON;');
      final fkViolations = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkViolations, isEmpty);

      // 4. Verify Row Counts preserved
      final compCount = (await db.customSelect('SELECT COUNT(*) as c FROM companies;').getSingle()).read<int>('c');
      expect(compCount, equals(1));

      final prodCount = (await db.customSelect('SELECT COUNT(*) as c FROM products;').getSingle()).read<int>('c');
      expect(prodCount, equals(1));

      final layerCount = (await db.customSelect('SELECT COUNT(*) as c FROM inventory_cost_layers;').getSingle()).read<int>('c');
      expect(layerCount, equals(1));

      final jeCount = (await db.customSelect('SELECT COUNT(*) as c FROM journal_entries;').getSingle()).read<int>('c');
      expect(jeCount, equals(1));

      final jlCount = (await db.customSelect('SELECT COUNT(*) as c FROM journal_lines;').getSingle()).read<int>('c');
      expect(jlCount, equals(2));

      // 5. Forensic Multi-Currency Verification (20 SAR * 140 YER/SAR = 2800 YER)
      final layerRow = await db.customSelect('SELECT * FROM inventory_cost_layers WHERE item_code = \'ITEM-MIG-101\';').getSingle();
      expect(layerRow.read<double>('unit_cost'), equals(20.0));
      expect(layerRow.read<double>('exchange_rate'), equals(140.0));
      expect(layerRow.read<double>('unit_cost_inventory_currency'), equals(2800.0));
      expect(layerRow.read<double>('total_cost_inventory_currency'), equals(2800.0));

      final jlRows = await db.customSelect('SELECT * FROM journal_lines;').get();
      final totalBaseDebit = jlRows.fold<double>(0.0, (sum, r) => sum + r.read<double>('base_debit'));
      final totalBaseCredit = jlRows.fold<double>(0.0, (sum, r) => sum + r.read<double>('base_credit'));

      expect(totalBaseDebit, equals(2800.0));
      expect(totalBaseCredit, equals(2800.0));
      expect(totalBaseDebit, equals(totalBaseCredit)); // Journal remains balanced!

      await db.close();
    });

    test('3. Idempotence & Re-open Safety: Re-opening migrated database preserves mappings and row counts', () async {
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
          rawDb.execute("INSERT INTO products (id, item_code, name, created_at, updated_at) VALUES (99, 'ITEM-IDEM-99', 'Idempotent Item', 1600000000000, 1600000000000);");
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );
      final db = NexabizDatabase.connect(executor);

      final row1 = await db.customSelect("SELECT id FROM products WHERE item_code = 'ITEM-IDEM-99'").getSingle();
      final mappedUuid1 = row1.read<String>('id');

      // Re-run migration simulation (idempotence check)
      final migrator = Migrator(db);
      await db.migration.onUpgrade(migrator, 12, 13);

      final row2 = await db.customSelect("SELECT id FROM products WHERE item_code = 'ITEM-IDEM-99'").getSingle();
      final mappedUuid2 = row2.read<String>('id');

      expect(mappedUuid1, equals(mappedUuid2)); // Deterministic UUID preserved!

      final count = (await db.customSelect("SELECT COUNT(*) as c FROM products WHERE item_code = 'ITEM-IDEM-99'").getSingle()).read<int>('c');
      expect(count, equals(1)); // No duplicate rows created!

      await db.close();
    });

    test('4. MigrationIntegrityValidator Post-Migration Financial Audit', () async {
      final db = NexabizDatabase.memory();
      final validator = MigrationIntegrityValidator(invDb: db);

      final preReport = await validator.auditPreMigration();
      expect(preReport.snapshot, isNotNull);

      // Verify post-migration audit succeeds with zero financial divergence
      await validator.verifyPostMigration(preReport.snapshot);
      await db.close();
    });
  });
}
