import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/domain/models/account_tree_node.dart';
import 'package:stock_count/modules/accounting/domain/services/account_code_generator.dart';
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

    test('seeds trading VAT and operational system accounts', () async {
      await repo.ensureDefaultChartSeeded();

      Future<void> expectSystem({
        required String code,
        required bool isGroup,
      }) async {
        final account = await repo.getByAccountCode(code);
        expect(account, isNotNull, reason: 'missing $code');
        expect(account!.isSystemAccount, isTrue);
        expect(account.isGroup, isGroup, reason: code);
      }

      await expectSystem(code: '1210', isGroup: true); // cash boxes
      await expectSystem(code: '1213', isGroup: false); // petty cash
      await expectSystem(code: '1235', isGroup: false); // inventory in transit
      await expectSystem(code: '1250', isGroup: false); // VAT input
      await expectSystem(code: '1260', isGroup: false); // prepaid
      await expectSystem(code: '1290', isGroup: false); // other current assets
      await expectSystem(code: '2111', isGroup: true); // suppliers group
      await expectSystem(code: '2130', isGroup: false); // VAT output
      await expectSystem(code: '2140', isGroup: false); // accrued expenses
      await expectSystem(code: '2150', isGroup: false); // customer advances
      await expectSystem(code: '2210', isGroup: false); // long-term loans
      await expectSystem(code: '4200', isGroup: true); // other revenue group
      await expectSystem(code: '4210', isGroup: false); // purchase discounts
      await expectSystem(code: '4220', isGroup: false); // FX gains
      await expectSystem(code: '5150', isGroup: false); // inventory adjustments
      await expectSystem(code: '5160', isGroup: false); // sales returns
      await expectSystem(code: '5170', isGroup: false); // sales discounts
      await expectSystem(code: '5500', isGroup: false); // bank charges
      await expectSystem(code: '5910', isGroup: false); // FX losses

      final cashBoxes = await repo.getByAccountCode('1210');
      final cash = await repo.getByAccountCode('1211');
      final bank = await repo.getByAccountCode('1212');
      final currentAssets = await repo.getByAccountCode('1200');
      expect(cashBoxes!.parentId, currentAssets!.uuid);
      expect(cash!.parentId, cashBoxes.uuid);
      expect(bank!.parentId, cashBoxes.uuid);

      final purchaseDiscounts = await repo.getByAccountCode('4210');
      final fxGain = await repo.getByAccountCode('4220');
      final otherRevenue = await repo.getByAccountCode('4200');
      expect(purchaseDiscounts!.parentId, otherRevenue!.uuid);
      expect(fxGain!.parentId, otherRevenue.uuid);

      final fxLoss = await repo.getByAccountCode('5910');
      final expenses = await repo.getByAccountCode('5000');
      expect(fxLoss!.parentId, expenses!.uuid);

      final suppliers = await repo.getByAccountCode('2111');
      final currentLiabilities = await repo.getByAccountCode('2100');
      expect(suppliers!.parentId, currentLiabilities!.uuid);
    });

    test('inserts missing trading seeds on existing charts', () async {
      await repo.ensureDefaultChartSeeded();
      final before = await repo.getAll();
      await db.customStatement(
        "DELETE FROM accounts WHERE account_code IN ('1250','2130','2111')",
      );
      final mid = await repo.getAll();
      expect(mid.length, before.length - 3);

      await repo.ensureDefaultChartSeeded();
      expect(await repo.getByAccountCode('1250'), isNotNull);
      expect(await repo.getByAccountCode('2130'), isNotNull);
      expect(await repo.getByAccountCode('2111'), isNotNull);
      final after = await repo.getAll();
      expect(after.length, before.length);
    });

    test('seeds default chart with pending sync queue entries', () async {
      await repo.ensureDefaultChartSeeded();
      final cash = await repo.getByAccountCode('1211');
      expect(cash, isNotNull);
      expect(cash!.syncStatus, SyncStatus.pending);
      expect(cash.isSystemAccount, isTrue);

      final pending = await queue.peekReady();
      expect(pending.where((op) => op.entityType == 'account'), isNotEmpty);
      expect(
        pending.any((op) => op.entityId == cash.uuid),
        isTrue,
      );
    });

    test('system account UUIDs are stable across installs', () async {
      await repo.ensureDefaultChartSeeded();
      final cash = await repo.getByAccountCode('1211');
      expect(cash!.uuid, systemAccountUuid('cash'));
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
      expect(
        pending.any(
          (op) => op.entityType == 'account' && op.entityId == created.uuid,
        ),
        isTrue,
      );
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

    test('AccountCodeGenerator sequences from parent account code', () async {
      await repo.ensureDefaultChartSeeded();
      final customers = await repo.getByAccountCode('1221');
      expect(customers, isNotNull);

      final generator = AccountCodeGenerator(repo);
      final first = await generator.generate(
        parentAccountCode: customers!.accountCode,
        parentAccountId: customers.uuid,
      );
      expect(first, '12210001');

      await repo.insert(
        AccountDraft(
          parentId: customers.uuid,
          accountCode: first,
          name: 'Customer One',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      final second = await generator.generate(
        parentAccountCode: customers.accountCode,
        parentAccountId: customers.uuid,
      );
      expect(second, '12210002');

      // Under cash boxes, continue after the highest sibling (1213 → 1214).
      final cashBoxes = await repo.getByAccountCode('1210');
      final cashBoxChild = await generator.generate(
        parentAccountCode: cashBoxes!.accountCode,
        parentAccountId: cashBoxes.uuid,
      );
      expect(cashBoxChild, '1214');
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

    test('re-insert same code after soft delete revives tombstone', () async {
      await repo.ensureDefaultChartSeeded();
      final assets = await repo.getByAccountCode('1000');
      final created = await repo.insert(
        AccountDraft(
          parentId: assets!.uuid,
          accountCode: '1411',
          name: 'Temp Import',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      final originalUuid = created.uuid;
      await repo.softDelete(created.id);
      expect(await repo.getByAccountCode('1411'), isNull);

      final revived = await repo.insert(
        AccountDraft(
          parentId: assets.uuid,
          accountCode: '1411',
          name: 'Temp Import Again',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      expect(revived.uuid, originalUuid);
      expect(revived.isDeleted, isFalse);
      expect(revived.isActive, isTrue);
      expect(revived.name, 'Temp Import Again');
      expect(await repo.getByAccountCode('1411'), isNotNull);
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
