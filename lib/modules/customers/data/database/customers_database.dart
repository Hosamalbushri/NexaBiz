import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/customers_table.dart';

part 'customers_database.g.dart';

@DriftDatabase(tables: [Customers])
class CustomersDatabase extends _$CustomersDatabase {
  CustomersDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// In-memory database for tests.
  CustomersDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

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

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'customers_master');
  }
}
