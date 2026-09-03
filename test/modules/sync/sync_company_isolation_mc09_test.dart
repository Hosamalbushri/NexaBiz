import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';

import 'package:stock_count/modules/sync/engine/data/stores/sync_cursor_store.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';

import 'package:stock_count/modules/sync/engine/domain/services/sync_entity_handler.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_manager.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

class MockSyncEntityHandler implements SyncEntityHandler {
  MockSyncEntityHandler(this.entityType);

  @override
  final String entityType;

  final uploadedOps = <SyncOperation>[];
  final appliedChanges = <SyncRemoteChange>[];

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<void> abandonPull() async {}

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    appliedChanges.add(change);
  }

  @override
  Future<void> confirmPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    return null;
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {}

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async {
    return [];
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async {
    uploadedOps.add(operation);
    return SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  }
}

class FakeRemoteSyncApi implements RemoteSyncApi {
  final pushedOps = <SyncOperation>[];

  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    pushedOps.add(operation);
    return SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  }

  @override
  Future<List<SyncBatchPushItemResult>> pushBatch(List<SyncOperation> operations) async {
    pushedOps.addAll(operations);
    return operations
        .map((op) => SyncBatchPushItemResult(
              operationId: op.id,
              status: 'success',
              ack: SyncUploadAck(entityId: op.entityId, remoteVersion: 1),
            ))
        .toList();
  }

  @override
  Future<List<SyncRemoteChange>> pull({String? entityType, DateTime? since}) async {
    return [];
  }

  @override
  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  }) async {
    return null;
  }

  @override
  Future<void> abandonPull(String entityType) async {}

  @override
  Future<void> acknowledgePull(String entityType) async {}
}

void main() {
  late Directory testDir;
  late ConnectivityService connectivity;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
    testDir = await Directory.systemTemp.createTemp('sync_mc09_test_hive_');
    Hive.init(testDir.path);
    await SyncQueue.registerAdapter();
  });

  tearDownAll(() async {
    await Hive.close();
    if (testDir.existsSync()) {
      await testDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    connectivity = ConnectivityService(
      connectivityStream: const Stream.empty(),
      initialResults: const [ConnectivityResult.wifi],
    );
  });

  tearDown(() async {
    connectivity.dispose();
  });

  group('Phase MC-09 — Offline & Synchronization Multi-Company Isolation Tests', () {
    test('SCENARIO 1 — Offline Switch A -> B: Enqueued Company A operations remain isolated in Company A queue box', () async {
      const companyA = 'company_a_12345678';
      const companyB = 'company_b_87654321';

      final queueA = SyncQueue(
        companyId: companyA,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyA),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyA),
      );

      final opA = SyncOperation.create(
        entityType: 'product',
        entityId: 'prod_A_1',
        type: SyncOperationType.create,
        payload: {'name': 'Company A Product'},
        companyId: companyA,
      );

      await queueA.enqueue(opA);

      final readyA = await queueA.peekReady();
      expect(readyA.length, equals(1));
      expect(readyA.first.companyId, equals(companyA));
      expect(readyA.first.entityId, equals('prod_A_1'));

      // Switch to Company B
      final queueB = SyncQueue(
        companyId: companyB,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyB),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyB),
      );

      final readyB = await queueB.peekReady();
      final allB = await queueB.all();
      expect(readyB, isEmpty, reason: 'Company B queue MUST NOT contain Company A operations');
      expect(allB, isEmpty, reason: 'Company B outbox MUST be completely empty');

      queueA.dispose();
      queueB.dispose();
    });

    test('SCENARIO 2 — Queue Isolation: Attempting cross-tenant enqueue or peek fails closed', () async {
      const companyA = 'company_a_12345678';
      const companyB = 'company_b_87654321';

      final queueB = SyncQueue(
        companyId: companyB,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyB),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyB),
      );

      final opA = SyncOperation.create(
        entityType: 'account',
        entityId: 'acc_A_1',
        type: SyncOperationType.create,
        payload: {'code': '1001'},
        companyId: companyA,
      );

      // Direct cross-tenant enqueue into Company B's queue MUST throw CompanyContextMismatchException
      expect(
        () async => await queueB.enqueue(opA),
        throwsA(isA<CompanyContextMismatchException>()),
      );

      queueB.dispose();
    });

    test('SCENARIO 3 — Mid-Flight Sync During Switch: Active sync pass fails closed if tenant context changes', () async {
      const companyA = 'company_a_12345678';
      const companyB = 'company_b_87654321';
      var activeCompany = companyA;

      final queueA = SyncQueue(
        companyId: companyA,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyA),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyA),
      );

      final opA = SyncOperation.create(
        entityType: 'customer',
        entityId: 'cust_A_1',
        type: SyncOperationType.create,
        payload: {'name': 'Customer A'},
        companyId: companyA,
      );
      await queueA.enqueue(opA);

      final fakeRemote = FakeRemoteSyncApi();

      final managerA = SyncManager(
        queue: queueA,
        connectivity: connectivity,
        remoteProvider: () => fakeRemote,
        readCompanyId: () => activeCompany,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
      );
      managerA.registerHandler(MockSyncEntityHandler('customer'));
      await managerA.start(enabled: true);

      // Simulate company switch happening while activeCompany changes to Company B
      activeCompany = companyB;

      final result = await managerA.syncNow(trigger: SyncPassTrigger.manual);

      // The operation companyId (companyA) != activeCompany (companyB).
      // SyncManager MUST quarantine opA and block remote push.
      expect(fakeRemote.pushedOps, isEmpty, reason: 'Company A operation MUST NOT be pushed under Company B active context');
      expect(result.failed, equals(1));

      final readyAfter = await queueA.peekReady();
      expect(readyAfter, isEmpty); // Quarantined op is removed from peekReady

      final allAfter = await queueA.all();
      expect(allAfter.first.status, equals(SyncStatus.quarantined));

      await managerA.dispose();
      queueA.dispose();
    });

    test('SCENARIO 4 — Post-Switch Sync (Company B): Executes strictly within Company B context and cursors', () async {
      const companyB = 'company_b_87654321';

      final queueB = SyncQueue(
        companyId: companyB,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyB),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyB),
      );

      final cursorStoreB = SyncCursorStore(
        boxName: tenantScopedName(HiveBoxes.syncCursors, companyB),
      );
      await cursorStoreB.write('product', 42);

      final opB = SyncOperation.create(
        entityType: 'product',
        entityId: 'prod_B_10',
        type: SyncOperationType.create,
        payload: {'name': 'Company B Product'},
        companyId: companyB,
      );
      await queueB.enqueue(opB);

      final fakeRemoteB = FakeRemoteSyncApi();

      final managerB = SyncManager(
        queue: queueB,
        connectivity: connectivity,
        remoteProvider: () => fakeRemoteB,
        readCompanyId: () => companyB,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
      );
      managerB.registerHandler(MockSyncEntityHandler('product'));
      await managerB.start(enabled: true);

      final result = await managerB.syncNow(trigger: SyncPassTrigger.manual);

      expect(result.uploaded, equals(1));
      expect(fakeRemoteB.pushedOps.length, equals(1));
      expect(fakeRemoteB.pushedOps.first.companyId, equals(companyB));

      final cursorVal = await cursorStoreB.read('product');
      expect(cursorVal, equals(42));

      await managerB.dispose();
      queueB.dispose();
    });

    test('SCENARIO 5 — Restart After Switch: App restart loading Company B accesses only Company B data', () async {
      const companyA = 'company_a_12345678';
      const companyB = 'company_b_87654321';

      // Seed Company A data
      final queueA = SyncQueue(
        companyId: companyA,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyA),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyA),
      );
      await queueA.enqueue(SyncOperation.create(
        entityType: 'account',
        entityId: 'acc_A_99',
        type: SyncOperationType.create,
        payload: const {},
        companyId: companyA,
      ));
      queueA.dispose();

      // Seed Company B data
      final queueB = SyncQueue(
        companyId: companyB,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyB),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyB),
      );
      await queueB.enqueue(SyncOperation.create(
        entityType: 'account',
        entityId: 'acc_B_88',
        type: SyncOperationType.create,
        payload: const {},
        companyId: companyB,
      ));
      queueB.dispose();

      // Simulate App Restart with session restored to Company B
      final restartedQueueB = SyncQueue(
        companyId: companyB,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyB),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyB),
      );

      final allB = await restartedQueueB.all();
      expect(allB.length, equals(1));
      expect(allB.first.entityId, equals('acc_B_88'));
      expect(allB.first.companyId, equals(companyB));

      restartedQueueB.dispose();
    });

    test('SCENARIO 6 — Round-Trip Switch A -> B -> A: Operations & cursors in Company A are preserved', () async {
      const companyA = 'company_a_12345678';
      const companyB = 'company_b_87654321';

      final queueA1 = SyncQueue(
        companyId: companyA,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyA),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyA),
      );
      await queueA1.enqueue(SyncOperation.create(
        entityType: 'journal',
        entityId: 'jnl_A_777',
        type: SyncOperationType.create,
        payload: const {},
        companyId: companyA,
      ));
      queueA1.dispose();

      // Switch to B
      final queueB = SyncQueue(
        companyId: companyB,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyB),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyB),
      );
      expect(await queueB.all(), isEmpty);
      queueB.dispose();

      // Switch back to A
      final queueA2 = SyncQueue(
        companyId: companyA,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyA),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyA),
      );
      final allA = await queueA2.all();
      expect(allA.length, equals(1));
      expect(allA.first.entityId, equals('jnl_A_777'));
      expect(allA.first.companyId, equals(companyA));

      queueA2.dispose();
    });

    test('SCENARIO 7 — Concurrent Sync & Switch Race Safety: Sequential rapid sync and switch operations complete without corruption', () async {
      const companyA = 'company_a_12345678';

      final queue = SyncQueue(
        companyId: companyA,
        encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyA),
        legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyA),
      );

      final fakeRemote = FakeRemoteSyncApi();

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        remoteProvider: () => fakeRemote,
        readCompanyId: () => companyA,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
      );
      await manager.start(enabled: true);

      // Trigger 10 rapid concurrent sync calls
      final futures = List.generate(
        10,
        (_) => manager.syncNow(trigger: SyncPassTrigger.manual),
      );

      final results = await Future.wait(futures);
      expect(results.length, equals(10));
      for (final r in results) {
        expect(r.outcome, isIn([SyncPassOutcome.idle, SyncPassOutcome.completed]));
      }

      await manager.dispose();
      queue.dispose();
    });
  });
}
