import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase db;
  late AccountRepositoryImpl repo;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    db = AccountingDatabase.memory();
    repo = AccountRepositoryImpl(
      db,
      readCompanyId: () => 'test_company_new_123',
    );
  });

  tearDown(() async {
    await db.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ensureDefaultChartSeeded does NOT seed accounts when company has 0 accounts', () async {
    // 1. Initial state: zero accounts
    final initialAccounts = await repo.getAll();
    expect(initialAccounts, isEmpty);

    // 2. Call ensureDefaultChartSeeded (simulates company creation / setup / page load)
    await repo.ensureDefaultChartSeeded();

    // 3. Accounts MUST still be 0 (no automatic background seeding)
    final afterEnsure = await repo.getAll();
    expect(afterEnsure, isEmpty);
  });

  test('seedDefaultChart ONLY seeds accounts when explicitly invoked by user', () async {
    // 1. Initial state: zero accounts
    expect(await repo.getAll(), isEmpty);

    // 2. Explicit user action: click "Seed Default Chart"
    await repo.seedDefaultChart();

    // 3. Accounts generated only after explicit invocation
    final accounts = await repo.getAll();
    expect(accounts.isNotEmpty, true);
    expect(accounts.length, greaterThanOrEqualTo(40));
  });
}
