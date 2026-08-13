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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
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
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'customers_master');
  }
}
