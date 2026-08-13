import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/domain/models/account_tree_node.dart';
import 'package:stock_count/modules/accounting/domain/services/account_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  late AccountingDatabase db;
  late AccountRepositoryImpl repo;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('accounting_coa_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    db = AccountingDatabase.memory();
    repo = AccountRepositoryImpl(db, syncQueue: queue);
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AccountType / NormalBalance', () {
    test('normal balances follow accounting rules', () {
      expect(AccountType.asset.normalBalance, NormalBalance.debit);
      expect(AccountType.expense.normalBalance, NormalBalance.debit);
      expect(AccountType.liability.normalBalance, NormalBalance.credit);
      expect(AccountType.equity.normalBalance, NormalBalance.credit);
      expect(AccountType.revenue.normalBalance, NormalBalance.credit);
    });
  });

  group('AccountValidator', () {
    const validator = AccountValidator();

    test('rejects empty name and code', () {
      expect(
        () => validator.validateDraft(
          const AccountDraft(
            accountCode: '',
            name: 'Cash',
            accountType: AccountType.asset,
            isGroup: false,
          ),
        ),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.invalidAccountCode,
          ),
        ),
      );
      expect(
        () => validator.validateDraft(
          const AccountDraft(
            accountCode: '1111',
            name: '  ',
            accountType: AccountType.asset,
            isGroup: false,
          ),
        ),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.invalidName,
          ),
        ),
      );
    });

    test('rejects type mismatch with parent', () {
      final parent = _fakeAccount(
        uuid: 'p1',
        code: '1000',
        type: AccountType.asset,
        isGroup: true,
      );
      expect(
        () => validator.validateHierarchy(
          draft: const AccountDraft(
            parentId: 'p1',
            accountCode: '4001',
            name: 'Bad',
            accountType: AccountType.revenue,
            isGroup: false,
          ),
          parent: parent,
          existing: null,
          allAccounts: [parent],
        ),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.typeMismatch,
          ),
        ),
      );
    });

    test('protects system accounts from code/type changes', () {
      final existing = _fakeAccount(
        uuid: 's1',
        code: '1211',
        type: AccountType.asset,
        isSystem: true,
      );
      expect(
        () => validator.assertSystemAccountEditable(
          existing: existing,
          draft: const AccountDraft(
            accountCode: '9999',
            name: 'Cash',
            accountType: AccountType.asset,
            isGroup: false,
          ),
          isDeactivating: false,
        ),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.systemAccountProtected,
          ),
        ),
      );
    });
  });

  group('AccountRepositoryImpl', () {
    test(
      'inserts newly added system account customers under current assets',
      () async {
        await repo.ensureDefaultChartSeeded();
        final customers = await repo.getByAccountCode('1221');
        expect(customers, isNotNull);
        expect(customers!.isSystemAccount, isTrue);
        expect(customers.isGroup, isTrue);
        final currentAssets = await repo.getByAccountCode('1200');
        expect(customers.parentId, currentAssets!.uuid);
        final receivable = await repo.getByAccountCode('1220');
        expect(receivable, isNotNull);
        expect(
          customers.accountCode.compareTo(receivable!.accountCode),
          greaterThan(0),
        );
        expect(customers.accountCode.compareTo('1230'), lessThan(0));
      },
    );

    test(
      'aligns system customers account to group on existing charts',
      () async {
        await repo.ensureDefaultChartSeeded();
        await db.customStatement(
          "UPDATE accounts SET is_group = 0 WHERE account_code = '1221'",
        );
        final asPosting = await repo.getByAccountCode('1221');
        expect(asPosting!.isGroup, isFalse);

        await repo.ensureDefaultChartSeeded();
        final aligned = await repo.getByAccountCode('1221');
        expect(aligned!.isGroup, isTrue);
      },
    );

    test('seeds default chart once', () async {
      await repo.ensureDefaultChartSeeded();
      final first = await repo.getAll();
      expect(first, isNotEmpty);
      expect(first.any((a) => a.accountCode == '1211'), isTrue);
      expect(first.where((a) => a.isSystemAccount), isNotEmpty);

      await repo.ensureDefaultChartSeeded();
      final second = await repo.getAll();
      expect(second.length, first.length);
    });

    test('creates posting account under group with pending sync', () async {
      await repo.ensureDefaultChartSeeded();
      final currentAssets = await repo.getByAccountCode('1200');
      expect(currentAssets, isNotNull);
      expect(currentAssets!.isGroup, isTrue);

      final created = await repo.insert(
        AccountDraft(
          parentId: currentAssets.uuid,
          accountCode: '1240',
          name: 'Petty Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      expect(created.accountType, AccountType.asset);
      expect(created.normalBalance, NormalBalance.debit);
      expect(created.level, currentAssets.level + 1);
      expect(created.syncStatus, SyncStatus.pending);

      final pending = await queue.peekReady();
      expect(pending, isNotEmpty);
      expect(pending.first.entityType, 'account');
      expect(pending.first.entityId, created.uuid);
    });

    test('rejects duplicate account codes', () async {
      await repo.ensureDefaultChartSeeded();
      expect(
        () => repo.insert(
          const AccountDraft(
            accountCode: '1211',
            name: 'Duplicate Cash',
            accountType: AccountType.asset,
            isGroup: false,
          ),
        ),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.duplicateAccountCode,
          ),
        ),
      );
    });

    test('rejects children under posting accounts', () async {
      await repo.ensureDefaultChartSeeded();
      final cash = await repo.getByAccountCode('1211');
      expect(cash!.isGroup, isFalse);
      expect(
        () => repo.insert(
          AccountDraft(
            parentId: cash.uuid,
            accountCode: '1211-1',
            name: 'Invalid child',
            accountType: AccountType.asset,
            isGroup: false,
          ),
        ),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.groupRequiredForChildren,
          ),
        ),
      );
    });

    test('soft delete and deactivate protect system accounts', () async {
      await repo.ensureDefaultChartSeeded();
      final cash = await repo.getByAccountCode('1211');
      expect(
        () => repo.softDelete(cash!.id),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.systemAccountProtected,
          ),
        ),
      );
      expect(
        () => repo.deactivate(cash!.id),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.systemAccountProtected,
          ),
        ),
      );
    });

    test('offline create survives reopen of same DB state', () async {
      await repo.ensureDefaultChartSeeded();
      final assets = await repo.getByAccountCode('1000');
      final created = await repo.insert(
        AccountDraft(
          parentId: assets!.uuid,
          accountCode: '1300',
          name: 'Other Assets',
          accountType: AccountType.asset,
          isGroup: true,
        ),
      );

      // Simulate "restart" by reading again from the same in-memory DB
      // and durable sync queue box.
      final after = await repo.getByUuid(created.uuid);
      expect(after, isNotNull);
      expect(after!.name, 'Other Assets');
      expect(after.syncStatus, SyncStatus.pending);

      final survivingQueue = SyncQueue(box: syncBox);
      final ops = await survivingQueue.all();
      expect(ops.any((o) => o.entityId == created.uuid), isTrue);
    });

    test('search matches name and code', () async {
      await repo.ensureDefaultChartSeeded();
      final byName = await repo.search('cash');
      expect(byName.any((a) => a.accountCode == '1211'), isTrue);
      final byCode = await repo.search('4100');
      expect(byCode.any((a) => a.name == 'Sales Revenue'), isTrue);
    });

    test('soft delete user account', () async {
      await repo.ensureDefaultChartSeeded();
      final assets = await repo.getByAccountCode('1000');
      final created = await repo.insert(
        AccountDraft(
          parentId: assets!.uuid,
          accountCode: '1400',
          name: 'Temp Group',
          accountType: AccountType.asset,
          isGroup: true,
        ),
      );
      await repo.softDelete(created.id);
      expect(await repo.getById(created.id), isNull);
      final tombstone = await repo.getByUuid(created.uuid);
      expect(tombstone!.isDeleted, isTrue);
    });
  });

  group('AccountTreeNode', () {
    test('builds hierarchy forest', () async {
      await repo.ensureDefaultChartSeeded();
      final all = await repo.getAll();
      final forest = AccountTreeNode.buildForest(all);
      expect(forest.length, 5);
      expect(forest.map((n) => n.account.accountCode).toList(), [
        '1000',
        '2000',
        '3000',
        '4000',
        '5000',
      ]);
      final assets = forest.firstWhere((n) => n.account.accountCode == '1000');
      expect(assets.children, isNotEmpty);
    });
  });
}

Account _fakeAccount({
  required String uuid,
  required String code,
  required AccountType type,
  bool isGroup = false,
  bool isSystem = false,
  String? parentId,
}) {
  final now = DateTime.utc(2026, 8, 12);
  return Account(
    id: 1,
    uuid: uuid,
    parentId: parentId,
    accountCode: code,
    name: code,
    accountType: type,
    normalBalance: type.normalBalance,
    level: parentId == null ? 0 : 1,
    isGroup: isGroup,
    isActive: true,
    isSystemAccount: isSystem,
    createdAt: now,
    updatedAt: now,
  );
}
