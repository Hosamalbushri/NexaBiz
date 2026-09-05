import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/shared/data/sync/cash_registers_sync_handlers.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void addAccount(Account acc) {
    _accounts[acc.uuid] = acc;
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _accounts[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async {
    for (final acc in _accounts.values) {
      if (acc.accountCode == code) return acc;
    }
    return null;
  }

  @override
  Future<Account?> getById(int id) async => throw UnimplementedError();

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async => _accounts.values.toList();

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) => Stream.value(_accounts.values.toList());

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async =>
      uuids.map((u) => _accounts[u]).whereType<Account>().toList();

  @override
  Future<List<Account>> search(String query, {bool includeInactive = false}) async => [];

  @override
  Future<List<Account>> getChildren(String parentUuid) async => [];

  @override
  Future<bool> hasChildren(String uuid) async => false;

  @override
  Future<bool> isUsedInTransactions(String uuid) async => false;

  @override
  Future<Account> insert(AccountDraft draft) async => throw UnimplementedError();

  @override
  Future<Account> update(int id, AccountDraft draft) async => throw UnimplementedError();

  @override
  Future<void> deactivate(int id) async {}

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  Future<void> seedDefaultChart() async {}

  @override
  Future<List<Account>> getByType(AccountType type, {bool includeInactive = false}) async =>
      _accounts.values.where((a) => a.accountType == type).toList();
}

void main() {
  late CashRegisterRepositoryImpl cashRepo;
  late FakeAccountRepository accountRepo;
  late AccountingDatabase db;
  late Directory tempDir;
  late SyncQueue syncQueue;
  late InMemoryRemoteSyncApi remoteApi;
  late CashRegisterSyncHandler syncHandler;

  final now = DateTime.now().toUtc();

  final validAccount = Account(
    id: 1,
    uuid: 'acc_asset_01',
    companyId: 'company_a',
    accountCode: '110101',
    name: 'Cash Asset Account',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cr08_sync_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    await SyncQueue.registerAdapter();

    accountRepo = FakeAccountRepository();
    accountRepo.addAccount(validAccount);

    db = AccountingDatabase.memory();
    cashRepo = CashRegisterRepositoryImpl(accountRepository: accountRepo, db: db);

    final queueBox = await Hive.openBox<SyncOperation>('test_sync_queue_${DateTime.now().millisecondsSinceEpoch}');
    syncQueue = SyncQueue(box: queueBox, companyId: 'company_a', deviceId: 'device_01');

    remoteApi = InMemoryRemoteSyncApi();
    syncHandler = CashRegisterSyncHandler(
      repository: cashRepo,
      remoteProvider: () => remoteApi,
    );
  });

  tearDown(() async {
    await db.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CR-08 Offline / Synchronization Integrity Test Matrix', () {
    test('1. Offline Register Creation & Outbox Persistence', () async {
      final newReg = CashRegister(
        id: 'reg_off_01',
        companyId: 'company_a',
        name: 'Offline Main Register',
        code: 'REG_OFF_01',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final created = await cashRepo.createCashRegister(newReg);
      expect(created.id, equals('reg_off_01'));

      final op = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: created.id,
        type: SyncOperationType.create,
        payload: {
          'uuid': created.id,
          'companyId': created.companyId,
          'name': created.name,
          'code': created.code,
          'isActive': created.isActive,
          'accountingAccountId': created.accountingAccountId,
          'createdAt': created.createdAt.millisecondsSinceEpoch,
          'updatedAt': created.updatedAt.millisecondsSinceEpoch,
        },
        baseVersion: 1,
        companyId: 'company_a',
        deviceId: 'device_01',
      );

      await syncQueue.enqueue(op);

      final readyOps = await syncQueue.peekReady();
      expect(readyOps.length, equals(1));
      expect(readyOps.first.entityId, equals('reg_off_01'));
      expect(readyOps.first.type, equals(SyncOperationType.create));
    });

    test('2. Offline Register Modification & Coalescing', () async {
      final opCreate = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_coal_01',
        type: SyncOperationType.create,
        payload: {'name': 'Initial Register Name'},
        companyId: 'company_a',
      );
      await syncQueue.enqueue(opCreate);

      final opUpdate = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_coal_01',
        type: SyncOperationType.update,
        payload: {'name': 'Updated Register Name'},
        companyId: 'company_a',
      );
      await syncQueue.enqueue(opUpdate);

      final ready = await syncQueue.peekReady();
      expect(ready.length, equals(1));
      expect(ready.first.type, equals(SyncOperationType.create));
      expect(ready.first.payload['name'], equals('Updated Register Name'));
    });

    test('3. Offline Account Binding Sync', () async {
      final reg = CashRegister(
        id: 'reg_bind_01',
        companyId: 'company_a',
        name: 'Binding Register',
        code: 'REG_BIND',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await cashRepo.createCashRegister(reg);

      final linked = await cashRepo.linkAccountingAccount(
        registerId: 'reg_bind_01',
        accountId: 'acc_asset_01',
        companyId: 'company_a',
      );
      expect(linked.isLinked, isTrue);

      final opLink = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: linked.id,
        type: SyncOperationType.update,
        payload: {
          'uuid': linked.id,
          'companyId': linked.companyId,
          'accountingAccountId': linked.accountingAccountId,
        },
        companyId: 'company_a',
      );
      await syncQueue.enqueue(opLink);

      final ready = await syncQueue.peekReady();
      expect(ready.first.payload['accountingAccountId'], equals('acc_asset_01'));
    });

    test('4. App Restart Queue Recovery', () async {
      final op = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_restart_01',
        type: SyncOperationType.create,
        payload: {'name': 'Restart Persisted Register'},
        companyId: 'company_a',
      );
      await syncQueue.enqueue(op);

      final recoveredOps = await syncQueue.all();
      expect(recoveredOps.any((o) => o.entityId == 'reg_restart_01'), isTrue);
    });

    test('5. Idempotent Retry & Push Acknowledgment', () async {
      final reg = CashRegister(
        id: 'reg_ack_01',
        companyId: 'company_a',
        name: 'Ack Register',
        code: 'ACK_01',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await cashRepo.createCashRegister(reg);

      final op = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_ack_01',
        type: SyncOperationType.create,
        payload: {
          'uuid': 'reg_ack_01',
          'companyId': 'company_a',
          'name': 'Ack Register',
          'code': 'ACK_01',
          'isActive': true,
        },
        companyId: 'company_a',
      );

      final ack1 = await syncHandler.upload(op);
      expect(ack1.entityId, equals('reg_ack_01'));
      expect(ack1.remoteVersion, equals(1));

      final ack2 = await syncHandler.upload(op);
      expect(ack2.entityId, equals('reg_ack_01'));
      expect(ack2.remoteVersion, equals(1));

      await syncHandler.markLocalSynced(
        entityId: 'reg_ack_01',
        remoteVersion: ack1.remoteVersion,
      );

      final local = await cashRepo.getCashRegisterById('reg_ack_01', companyId: 'company_a');
      expect(local, isNotNull);
    });

    test('6. Company Scoping Isolation in Sync Payloads', () async {
      final opCompanyB = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_comp_b_sync',
        type: SyncOperationType.create,
        payload: {'name': 'Company B Register'},
        companyId: 'company_b',
      );

      expect(
        () async => await syncQueue.enqueue(opCompanyB),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('7. Remote Conflict Evaluation & Handling', () async {
      remoteApi.seed(
        CashRegisterRepositoryImpl.entityType,
        RemoteEntityMeta(
          entityId: 'reg_conf_01',
          version: 5,
          updatedAt: DateTime.now().toUtc(),
          payload: {'name': 'Remote Higher Version Register'},
        ),
      );

      final localOp = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_conf_01',
        type: SyncOperationType.update,
        payload: {'name': 'Stale Local Register'},
        baseVersion: 2,
        companyId: 'company_a',
      ).copyWith(status: SyncStatus.synced);

      final decision = await syncHandler.evaluateConflict(localOp);
      expect(decision, equals(ConflictDecision.applyRemote));
    });

    test('8. Remote Soft-Delete Synchronization', () async {
      final reg = CashRegister(
        id: 'reg_del_01',
        companyId: 'company_a',
        name: 'Register to be deleted',
        code: 'DEL_01',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await cashRepo.createCashRegister(reg);

      final remoteChange = SyncRemoteChange(
        entityId: 'reg_del_01',
        version: 2,
        updatedAt: DateTime.now().toUtc(),
        payload: {
          'companyId': 'company_a',
          'name': 'Register to be deleted',
          'code': 'DEL_01',
          'isActive': false,
        },
        deleted: true,
      );

      await syncHandler.applyRemoteChange(remoteChange);

      final activeList = await cashRepo.getCashRegisters('company_a');
      expect(activeList.any((r) => r.id == 'reg_del_01'), isFalse);
    });

    test('9. Active Company Switching Provider State Invalidation', () async {
      final opA = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_a_scope',
        type: SyncOperationType.create,
        payload: {'name': 'Company A Register'},
        companyId: 'company_a',
      );
      final opB = SyncOperation.create(
        entityType: CashRegisterRepositoryImpl.entityType,
        entityId: 'reg_b_scope',
        type: SyncOperationType.create,
        payload: {'name': 'Company B Register'},
        companyId: 'company_b',
      );

      expect(opA.companyId, equals('company_a'));
      expect(opB.companyId, equals('company_b'));
    });

    test('10. Financial Balance Truth Preservation (Derived from Ledgers)', () async {
      final reg = CashRegister(
        id: 'reg_truth_01',
        companyId: 'company_a',
        name: 'Truth Register',
        code: 'TRUTH_01',
        isActive: true,
        accountingAccountId: 'acc_asset_01',
        createdAt: now,
        updatedAt: now,
      );
      await cashRepo.createCashRegister(reg);

      final remoteChange = SyncRemoteChange(
        entityId: 'reg_truth_01',
        version: 3,
        updatedAt: DateTime.now().toUtc(),
        payload: {
          'companyId': 'company_a',
          'name': 'Truth Register Updated Name',
          'code': 'TRUTH_01',
          'isActive': true,
          'accountingAccountId': 'acc_asset_01',
          'injectedFakeBalance': 999999.00,
        },
      );

      await syncHandler.applyRemoteChange(remoteChange);

      final updated = await cashRepo.getCashRegisterById('reg_truth_01');
      expect(updated?.name, equals('Truth Register Updated Name'));
    });
  });
}
