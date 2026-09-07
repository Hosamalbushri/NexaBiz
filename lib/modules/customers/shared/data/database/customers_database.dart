import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';

import 'tables/customers_table.dart';

part 'customers_database.g.dart';

@DriftDatabase(tables: [Customers])
class CustomersDatabase extends _$CustomersDatabase {
  CustomersDatabase({String? name, QueryExecutor? executor})
    : super(executor ?? _openConnection(name ?? 'customers_master'));

  /// In-memory database for tests.
  CustomersDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await _createIndexes();
      }
      if (from < 3) {
        await m.addColumn(customers, customers.companyId);
        await customStatement(
          "UPDATE customers SET company_id = 'local-company' WHERE company_id IS NULL",
        );
      }
    },
    beforeOpen: (details) async {
      try {
        final rows = await customSelect('PRAGMA table_info(customers)').get();
        final existingColumns = rows.map((r) => r.read<String>('name')).toSet();

        if (!existingColumns.contains('company_id')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN company_id TEXT;",
          );
        }
        if (!existingColumns.contains('status')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN status TEXT DEFAULT 'active';",
          );
        }
        if (!existingColumns.contains('is_active')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN is_active INTEGER DEFAULT 1;",
          );
        }
        if (!existingColumns.contains('data_source')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN data_source TEXT DEFAULT 'local';",
          );
        }
        if (!existingColumns.contains('sync_status')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN sync_status TEXT DEFAULT 'synced';",
          );
        }
        if (!existingColumns.contains('version')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN version INTEGER DEFAULT 1;",
          );
        }
        if (!existingColumns.contains('deleted_at')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN deleted_at INTEGER;",
          );
        }
        if (!existingColumns.contains('last_synced_at')) {
          await customStatement(
            "ALTER TABLE customers ADD COLUMN last_synced_at INTEGER;",
          );
        }

        // Sanitize any null values on guaranteed existing columns
        await customStatement(
          "UPDATE customers SET status = 'active' WHERE status IS NULL;",
        );
        await customStatement(
          "UPDATE customers SET is_active = 1 WHERE is_active IS NULL;",
        );
        await customStatement(
          "UPDATE customers SET data_source = 'local' WHERE data_source IS NULL;",
        );
        await customStatement(
          "UPDATE customers SET sync_status = 'synced' WHERE sync_status IS NULL;",
        );
        await customStatement(
          "UPDATE customers SET version = 1 WHERE version IS NULL;",
        );
        await customStatement(
          "UPDATE customers SET company_id = 'default' WHERE company_id IS NULL;",
        );
      } catch (_) {
        // Fallback for safety during initial creation or memory DBs
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_sync ON customers (sync_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_external '
      'ON customers (external_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_account '
      'ON customers (account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers (phone)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_customers_active_alive '
      'ON customers (is_active) WHERE deleted_at IS NULL',
    );
  }

  static QueryExecutor _openConnection(String name) {
    return encryptedDriftDatabase(name: name);
  }
}
