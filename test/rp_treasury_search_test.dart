import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_treasury_adapter.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  late AccountingDatabase db;
  late AccountRepositoryImpl repo;
  late AccountingRpTreasuryAdapter adapter;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rp_treasury_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    db = AccountingDatabase.memory();
    repo = AccountRepositoryImpl(db, syncQueue: queue);
    adapter = AccountingRpTreasuryAdapter(repo);
    await repo.ensureDefaultChartSeeded();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('searchPostingAccounts returns non-customer posting accounts', () async {
    final expenses = await repo.getByAccountCode('5000');
    await repo.insert(
      AccountDraft(
        parentId: expenses!.uuid,
        accountCode: '5101',
        name: 'Office Rent',
        accountType: AccountType.expense,
        isGroup: false,
      ),
    );

    final byCode = await adapter.searchPostingAccounts(
      '5101',
      languageCode: 'ar',
    );
    expect(byCode.any((a) => a.code == '5101'), isTrue);

    final byArabicCash = await adapter.searchPostingAccounts(
      'الصندوق',
      languageCode: 'ar',
    );
    expect(
      byArabicCash.any((a) => a.code == '1211' || a.systemKey == 'cash'),
      isTrue,
    );

    final bySalaries = await adapter.searchPostingAccounts(
      'رواتب',
      languageCode: 'ar',
      limit: 50,
    );
    expect(bySalaries.any((a) => a.systemKey == 'salaries'), isTrue);

    final broad = await adapter.searchPostingAccounts('5', languageCode: 'ar');
    expect(broad.any((a) => a.code.startsWith('5')), isTrue);
    expect(
      broad.every((a) => a.code.startsWith('1221')),
      isFalse,
      reason: 'search must not be limited to customer accounts',
    );
  });
}
