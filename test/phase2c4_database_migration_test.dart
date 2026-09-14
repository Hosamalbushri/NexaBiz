import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/migration/legacy_database_migrator.dart';
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
      expect(tableNames, contains('sales'));
      expect(tableNames, contains('purchases'));
      expect(tableNames, contains('stock_movement_ledgers'));

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
            CREATE TABLE accounts (
              id INTEGER PRIMARY KEY,
              account_code TEXT,
              name TEXT,
              account_type TEXT,
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
          rawDb.execute("INSERT INTO accounts (id, account_code, name, account_type, company_id, created_at, updated_at) VALUES (500, '1000', 'Inventory Asset', 'asset', 10, $now, $now);");
          rawDb.execute("INSERT INTO accounts (id, account_code, name, account_type, company_id, created_at, updated_at) VALUES (600, '2000', 'Accounts Payable', 'payable', 10, $now, $now);");
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
      // Trigger schema upgrade via customSelect
      await db.customSelect('SELECT COUNT(*) FROM companies;').getSingle();

      // 3. Verify SQLite foreign key integrity: PRAGMA foreign_key_check;
      // Verify SQLite foreign key integrity: PRAGMA foreign_key_check;
      await db.customStatement('PRAGMA foreign_keys = ON;');
      final fkViolations = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkViolations, isEmpty);

      // 4. Verify Row Counts preserved
      // Verify Row Counts preserved
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
      final layerRow = await db.customSelect("SELECT * FROM inventory_cost_layers WHERE item_code = 'ITEM-MIG-101';").getSingle();
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
      final executor = LazyDatabase(() async {
        final rawDb = sqlite.sqlite3.openInMemory();
        rawDb.execute('PRAGMA foreign_keys = ON;');
        rawDb.execute('PRAGMA user_version = 1;');

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
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY,
            account_code TEXT,
            name TEXT,
            account_type TEXT,
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

        const now = 1600000000000;
        rawDb.execute("INSERT INTO companies (id, code, name, created_at, updated_at) VALUES (10, 'COMP-10', 'Validator Corp', $now, $now);");
        rawDb.execute("INSERT INTO accounts (id, account_code, name, account_type, company_id, created_at, updated_at) VALUES (500, '1230', 'Inventory Asset', 'asset', 10, $now, $now);");
        rawDb.execute("INSERT INTO accounts (id, account_code, name, account_type, company_id, created_at, updated_at) VALUES (600, '2000', 'Payable', 'payable', 10, $now, $now);");
        rawDb.execute("INSERT INTO products (id, item_code, name, pack_size, price, unit_cost, company_id, created_at, updated_at) VALUES (101, 'ITEM-VAL-101', 'Validator Product', 1, 100.0, 20.0, 10, $now, $now);");
        rawDb.execute("INSERT INTO stock_receipts (id, receipt_number, status, company_id, created_at, updated_at) VALUES (50, 'REC-VAL-50', 'posted', 10, $now, $now);");

        // Seed 20 SAR * 140 YER/SAR = 2800 YER multi-currency layer
        rawDb.execute('''
          INSERT INTO inventory_cost_layers 
          (id, item_code, movement_uuid, movement_type, received_date, received_qty, remaining_qty, unit_cost, total_cost, currency_code, exchange_rate, unit_cost_inventory_currency, total_cost_inventory_currency, closed, company_id, created_at, updated_at)
          VALUES (30, 'ITEM-VAL-101', '50', 'receipt', $now, 1.0, 1.0, 20.0, 20.0, 'SAR', 140.0, 2800.0, 2800.0, 0, 10, $now, $now);
        ''');

        rawDb.execute("INSERT INTO journal_entries (id, voucher_number, voucher_type, currency_code, exchange_rate, entry_date, status, company_id, created_at, updated_at) VALUES (200, 'JE-VAL-200', 'journal', 'SAR', 140.0, $now, 'posted', 10, $now, $now);");
        rawDb.execute("INSERT INTO journal_lines (id, journal_id, account_id, currency_code, debit, credit, base_debit, base_credit, exchange_rate, company_id, created_at) VALUES (1001, 200, 500, 'SAR', 20.0, 0.0, 2800.0, 0.0, 140.0, 10, $now);");
        rawDb.execute("INSERT INTO journal_lines (id, journal_id, account_id, currency_code, debit, credit, base_debit, base_credit, exchange_rate, company_id, created_at) VALUES (1002, 200, 600, 'SAR', 0.0, 20.0, 0.0, 2800.0, 140.0, 10, $now);");

        return NativeDatabase.opened(rawDb);
      });

      final db = NexabizDatabase.connect(executor);
      // Trigger migration execution
      await db.customSelect('SELECT COUNT(*) FROM companies;').getSingle();

      final validator = MigrationIntegrityValidator(invDb: db);

      final postReport = await validator.auditPreMigration();
      expect(postReport.snapshot, isNotNull);
      expect(postReport.snapshot.productCount, equals(1));
      expect(postReport.snapshot.receiptCount, equals(1));
      expect(postReport.snapshot.costLayerCount, equals(1));
      expect(postReport.snapshot.totalInventoryValuation, equals(20.0));
      expect(postReport.snapshot.totalGLBalance, equals(2800.0));
      expect(postReport.hasIssues, isFalse);

      // Verify post-migration audit succeeds with zero financial divergence
      await validator.verifyPostMigration(postReport.snapshot);

      // Verify SQLite PRAGMA foreign_key_check passes with zero violations
      final fkCheck = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkCheck, isEmpty);

      await db.close();
    });

    test('5. Real File SQLite Upgrade & Pre-Migration Backup Verification', () async {
      final tempDir = Directory.systemTemp.createTempSync('nexabiz_migration_test_');
      final dbFile = File('${tempDir.path}/legacy_v1.sqlite');

      // Step A: Create an authentic SQLite file on disk using sqlite3 C-bindings
      final rawDb = sqlite.sqlite3.open(dbFile.path);
      rawDb.execute('PRAGMA user_version = 1;');
      rawDb.execute('''
        CREATE TABLE companies (
          id INTEGER PRIMARY KEY,
          code TEXT,
          name TEXT,
          base_currency_code TEXT,
          inventory_currency_code TEXT,
          status TEXT,
          created_at INTEGER,
          updated_at INTEGER
        );
      ''');
      rawDb.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY,
          item_code TEXT,
          name TEXT,
          price REAL,
          unit_cost REAL,
          company_id INTEGER,
          created_at INTEGER,
          updated_at INTEGER
        );
      ''');
      rawDb.execute("INSERT INTO companies VALUES (1, 'CORP-A', 'Company A', 'YER', 'SAR', 'active', 1000, 1000);");
      rawDb.execute("INSERT INTO products VALUES (10, 'PROD-FILE-10', 'File Item 10', 500.0, 300.0, 1, 1000, 1000);");
      rawDb.dispose();

      expect(dbFile.existsSync(), isTrue);
      final initialSize = dbFile.lengthSync();
      expect(initialSize, greaterThan(0));

      // Step B: Open with Drift/NexabizDatabase which triggers upgrade from version 1 to 13
      final fileDb = NexabizDatabase.connect(NativeDatabase(dbFile));
      await fileDb.customSelect('SELECT COUNT(*) FROM companies;').getSingle();

      // Step C: Verify Pre-Migration Backup File was created on disk
      final backupFile = File('${dbFile.path}.pre_migration_v1.bak');
      expect(backupFile.existsSync(), isTrue, reason: 'Pre-migration backup file must exist on disk before upgrade!');
      expect(backupFile.lengthSync(), greaterThan(0), reason: 'Backup file must have non-zero length!');

      // Verify the backup file itself can be opened and contains the original legacy schema with INTEGER id
      final backupRaw = sqlite.sqlite3.open(backupFile.path);
      final backupColInfo = backupRaw.select('PRAGMA table_info(products);');
      final idTypeInBackup = backupColInfo.firstWhere((r) => r['name'] == 'id')['type'] as String;
      expect(idTypeInBackup.toUpperCase(), contains('INT'));
      final backupRows = backupRaw.select('SELECT * FROM products;');
      expect(backupRows.length, equals(1));
      expect(backupRows.first['id'], equals(10));
      backupRaw.dispose();

      // Step D: Verify upgraded file database has canonical UUID v7 schema
      final compRows = await fileDb.customSelect('SELECT * FROM companies;').get();
      expect(compRows.length, equals(1));
      final compUuid = compRows.first.read<String>('id');
      expect(compUuid.length, equals(36));

      final prodRows = await fileDb.customSelect('SELECT * FROM products;').get();
      expect(prodRows.length, equals(1));
      final prodUuid = prodRows.first.read<String>('id');
      expect(prodUuid.length, equals(36));
      expect(prodRows.first.read<String>('company_id'), equals(compUuid));

      await fileDb.close();
      tempDir.deleteSync(recursive: true);
    });

    test('6. Multi-Tenant Legacy ID Collision Safety (Company A Product 1 vs Company B Product 1)', () async {
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
            CREATE TABLE products (
              id INTEGER NOT NULL,
              item_code TEXT,
              name TEXT,
              price REAL,
              unit_cost REAL,
              company_id INTEGER NOT NULL,
              created_at INTEGER,
              updated_at INTEGER,
              PRIMARY KEY (company_id, id)
            );
          ''');
          rawDb.execute('''
            CREATE TABLE customers (
              id INTEGER NOT NULL,
              customer_code TEXT,
              name TEXT,
              company_id INTEGER NOT NULL,
              created_at INTEGER,
              updated_at INTEGER,
              PRIMARY KEY (company_id, id)
            );
          ''');
          rawDb.execute('''
            CREATE TABLE sales (
              id INTEGER NOT NULL,
              sale_number TEXT,
              customer_id INTEGER,
              currency_code TEXT,
              base_currency_code TEXT,
              total REAL,
              company_id INTEGER NOT NULL,
              created_at INTEGER,
              updated_at INTEGER,
              PRIMARY KEY (company_id, id)
            );
          ''');

          // Seed two distinct companies
          rawDb.execute("INSERT INTO companies VALUES (10, 'COMP-TEN', 'Company 10', 1000, 1000);");
          rawDb.execute("INSERT INTO companies VALUES (20, 'COMP-TWENTY', 'Company 20', 1000, 1000);");

          // Collision Scenario: Both companies have product id = 1, customer id = 1, and sale id = 1!
          rawDb.execute("INSERT INTO products VALUES (1, 'PROD-A', 'Tenant 10 Product 1', 100.0, 50.0, 10, 1000, 1000);");
          rawDb.execute("INSERT INTO products VALUES (1, 'PROD-B', 'Tenant 20 Product 1', 200.0, 80.0, 20, 1000, 1000);");

          rawDb.execute("INSERT INTO customers VALUES (1, 'CUST-A', 'Tenant 10 Customer 1', 10, 1000, 1000);");
          rawDb.execute("INSERT INTO customers VALUES (1, 'CUST-B', 'Tenant 20 Customer 1', 20, 1000, 1000);");

          rawDb.execute("INSERT INTO sales VALUES (1, 'INV-10-1', 1, 'SAR', 'YER', 100.0, 10, 1000, 1000);");
          rawDb.execute("INSERT INTO sales VALUES (1, 'INV-20-1', 1, 'SAR', 'YER', 200.0, 20, 1000, 1000);");

          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);
      // Trigger migration
      await db.customSelect('SELECT COUNT(*) FROM companies;').getSingle();

      // Verify row counts: both rows for product 1 and customer 1 and sale 1 were preserved without collision!
      final prods = await db.customSelect('SELECT * FROM products ORDER BY price;').get();
      expect(prods.length, equals(2));
      final prod10Uuid = prods[0].read<String>('id');
      final prod20Uuid = prods[1].read<String>('id');
      expect(prod10Uuid, isNot(equals(prod20Uuid)));

      final custs = await db.customSelect('SELECT * FROM customers ORDER BY customer_code;').get();
      expect(custs.length, equals(2));
      final cust10Uuid = custs[0].read<String>('id');
      final cust20Uuid = custs[1].read<String>('id');
      expect(cust10Uuid, isNot(equals(cust20Uuid)));

      final sales = await db.customSelect('SELECT * FROM sales ORDER BY total;').get();
      expect(sales.length, equals(2));
      final sale10CustId = sales[0].read<String>('customer_id');
      final sale20CustId = sales[1].read<String>('customer_id');

      // Crucial Multi-Tenant Isolation Check:
      // Sale 10 refers to Tenant 10's Customer 1 UUID, and Sale 20 refers to Tenant 20's Customer 1 UUID!
      expect(sale10CustId, equals(cust10Uuid));
      expect(sale20CustId, equals(cust20Uuid));

      await db.close();
    });

    test('7. Complete ERP Lifecycle Preservation: Sales, Purchases, Ledgers, and 20 SAR x 140 = 2800 YER Valuation', () async {
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = OFF;');
          rawDb.execute('''
            CREATE TABLE companies (
              id INTEGER PRIMARY KEY,
              code TEXT,
              name TEXT,
              base_currency_code TEXT,
              inventory_currency_code TEXT,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE warehouses (
              id INTEGER PRIMARY KEY,
              warehouse_code TEXT,
              name TEXT,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE accounts (
              id INTEGER PRIMARY KEY,
              account_code TEXT,
              name TEXT,
              account_type TEXT,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY,
              item_code TEXT,
              name TEXT,
              price REAL,
              unit_cost REAL,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE purchases (
              id INTEGER PRIMARY KEY,
              purchase_number TEXT,
              currency_code TEXT,
              base_currency_code TEXT,
              exchange_rate REAL,
              subtotal REAL,
              total REAL,
              warehouse_id INTEGER,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE purchase_items (
              id INTEGER PRIMARY KEY,
              purchase_id INTEGER,
              product_id INTEGER,
              item_code TEXT,
              product_name TEXT,
              quantity REAL,
              unit_price REAL,
              total REAL,
              company_id INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE stock_movement_ledgers (
              id INTEGER PRIMARY KEY,
              company_id INTEGER,
              warehouse_id INTEGER,
              product_id INTEGER,
              item_code TEXT,
              quantity REAL,
              direction TEXT,
              movement_type TEXT,
              posting_date INTEGER,
              source_document_id INTEGER,
              source_document_type TEXT,
              source_line_uuid TEXT,
              unit_cost REAL,
              total_cost REAL,
              base_total_cost REAL,
              inventory_currency_id TEXT,
              document_currency_id TEXT,
              unit_cost_document_currency REAL,
              total_cost_document_currency REAL,
              exchange_rate REAL,
              costing_method_used TEXT,
              created_at INTEGER
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
            CREATE TABLE sales (
              id INTEGER PRIMARY KEY,
              sale_number TEXT,
              currency_code TEXT,
              base_currency_code TEXT,
              exchange_rate REAL,
              subtotal REAL,
              total REAL,
              company_id INTEGER,
              created_at INTEGER,
              updated_at INTEGER
            );
          ''');
          rawDb.execute('''
            CREATE TABLE sale_items (
              id INTEGER PRIMARY KEY,
              sale_id INTEGER,
              product_id INTEGER,
              item_code TEXT,
              product_name TEXT,
              quantity REAL,
              unit_price REAL,
              total REAL,
              company_id INTEGER
            );
          ''');

          // Seed ERP documents
          const now = 1600000000000;
          rawDb.execute("INSERT INTO companies VALUES (1, 'CORP-1', 'Main Company', 'YER', 'SAR', $now, $now);");
          rawDb.execute("INSERT INTO warehouses VALUES (10, 'WH-MAIN', 'Main Warehouse', 1, $now, $now);");
          rawDb.execute("INSERT INTO accounts VALUES (100, 'ACC-101', 'Cash Desk', 'asset', 1, $now, $now);");
          rawDb.execute("INSERT INTO products VALUES (50, 'LAPTOP-PRO', 'Pro Laptop', 50.0, 20.0, 1, $now, $now);");

          // Purchase of 1 unit @ 20 SAR, exchange rate 140 YER/SAR -> 2800 YER
          rawDb.execute("INSERT INTO purchases VALUES (1, 'PUR-001', 'SAR', 'YER', 140.0, 20.0, 20.0, 10, 1, $now, $now);");
          rawDb.execute("INSERT INTO purchase_items VALUES (1, 1, 50, 'LAPTOP-PRO', 'Pro Laptop', 1.0, 20.0, 20.0, 1);");

          // Movement ledger with 20 SAR * 140 YER/SAR = 2800 YER valuation
          rawDb.execute('''
            INSERT INTO stock_movement_ledgers VALUES (
              1, 1, 10, 50, 'LAPTOP-PRO', 1.0, 'inbound', 'receipt', $now, 1, 'purchases', '1',
              2800.0, 2800.0, 2800.0, 'YER', 'SAR', 20.0, 20.0, 140.0, 'fifo', $now
            );
          ''');

          // Cost layer with 20 SAR * 140 = 2800 YER
          rawDb.execute('''
            INSERT INTO inventory_cost_layers VALUES (
              1, 'LAPTOP-PRO', '1', 'receipt', $now, 1.0, 1.0, 20.0, 20.0, 'SAR', 140.0, 2800.0, 2800.0, 0, 1, $now, $now
            );
          ''');

          // Sale invoice
          rawDb.execute("INSERT INTO sales VALUES (1, 'SALE-001', 'SAR', 'YER', 140.0, 50.0, 50.0, 1, $now, $now);");
          rawDb.execute("INSERT INTO sale_items VALUES (1, 1, 50, 'LAPTOP-PRO', 'Pro Laptop', 1.0, 50.0, 50.0, 1);");

          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);
      await db.customSelect('SELECT COUNT(*) FROM companies;').getSingle();

      // 1. Verify row counts across all modules
      expect((await db.customSelect('SELECT COUNT(*) as c FROM purchases;').getSingle()).read<int>('c'), equals(1));
      expect((await db.customSelect('SELECT COUNT(*) as c FROM purchase_items;').getSingle()).read<int>('c'), equals(1));
      expect((await db.customSelect('SELECT COUNT(*) as c FROM sales;').getSingle()).read<int>('c'), equals(1));
      expect((await db.customSelect('SELECT COUNT(*) as c FROM sale_items;').getSingle()).read<int>('c'), equals(1));
      expect((await db.customSelect('SELECT COUNT(*) as c FROM stock_movement_ledgers;').getSingle()).read<int>('c'), equals(1));
      expect((await db.customSelect('SELECT COUNT(*) as c FROM inventory_cost_layers;').getSingle()).read<int>('c'), equals(1));

      // 2. Strict Financial Valuation Check: 20 SAR * 140 YER/SAR = 2800 YER
      final costLayer = await db.customSelect("SELECT * FROM inventory_cost_layers WHERE item_code = 'LAPTOP-PRO';").getSingle();
      expect(costLayer.read<double>('unit_cost'), equals(20.0));
      expect(costLayer.read<double>('exchange_rate'), equals(140.0));
      expect(costLayer.read<double>('unit_cost_inventory_currency'), equals(2800.0));
      expect(costLayer.read<double>('total_cost_inventory_currency'), equals(2800.0));

      final ledger = await db.customSelect("SELECT * FROM stock_movement_ledgers WHERE item_code = 'LAPTOP-PRO';").getSingle();
      expect(ledger.read<double>('unit_cost'), equals(2800.0));
      expect(ledger.read<double>('total_cost'), equals(2800.0));
      expect(ledger.read<double>('exchange_rate'), equals(140.0));
      expect(ledger.read<double>('unit_cost_document_currency'), equals(20.0));
      expect(ledger.read<double>('total_cost_document_currency'), equals(20.0));

      await db.close();
    });

    test('8. Crash Recovery & Interrupted Migration Replay', () async {
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
          rawDb.execute("INSERT INTO products VALUES (1, 'PROD-RECOVER-1', 'Product 1', 1000, 1000);");
          rawDb.execute("INSERT INTO products VALUES (2, 'PROD-RECOVER-2', 'Product 2', 1000, 1000);");
          // Simulate crash right after rename
          rawDb.execute('ALTER TABLE products RENAME TO _legacy_products;');
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);
      // Reopen and trigger migration
      final migrator = LegacyDatabaseMigrator(db);
      await migrator.migrateFromLegacy(
        migrator: Migrator(db),
        fromVersion: 1,
        toVersion: 13,
      );

      // Verify products table was created, populated from _legacy_products, and _legacy_products was dropped!
      final pExists = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='products';").get();
      final legacyExists = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='_legacy_products';").get();

      expect(pExists.isNotEmpty, isTrue, reason: 'products table must exist after recovery');
      expect(legacyExists.isEmpty, isTrue, reason: 'temporary legacy table must be cleaned up after recovery');

      final count = (await db.customSelect('SELECT COUNT(*) as c FROM products;').getSingle()).read<int>('c');
      expect(count, equals(2), reason: 'All rows from crashed migration must be recovered!');

      await db.close();
    });

    test('9. Fail-Closed Unmigrated Legacy Table Guard', () async {
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = OFF;');
          // An unhandled table with INTEGER id column
          rawDb.execute('''
            CREATE TABLE legacy_unhandled_table (
              id INTEGER PRIMARY KEY,
              note TEXT
            );
          ''');
          rawDb.execute("INSERT INTO legacy_unhandled_table VALUES (1, 'Mystery Data');");
          rawDb.execute('PRAGMA user_version = 1;');
        },
      );

      final db = NexabizDatabase.connect(executor);
      final migrator = LegacyDatabaseMigrator(db);

      // Must throw StateError refusing to allow corrupted/partial database to open
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
