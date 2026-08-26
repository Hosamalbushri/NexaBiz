import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';
import 'package:stock_count/core/time/domain/trusted_clock.dart';

class Phase7MockEntityHandler implements SyncEntityHandler {
  Phase7MockEntityHandler({
    required this.entityType,
    this.uploadAckBuilder,
    this.uploadErrorBuilder,
  });

  @override
  final String entityType;
  final SyncUploadAck Function(SyncOperation op)? uploadAckBuilder;
  final Exception Function(SyncOperation op)? uploadErrorBuilder;

  final List<SyncOperation> uploadedOps = [];
  final List<SyncRemoteChange> appliedRemoteChanges = [];

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async {
    uploadedOps.add(operation);
    if (uploadErrorBuilder != null) {
      final err = uploadErrorBuilder!(operation);
      throw err;
    }
    if (uploadAckBuilder != null) {
      return uploadAckBuilder!(operation);
    }
    return SyncUploadAck(
      entityId: operation.entityId,
      remoteVersion: (operation.baseVersion) + 1,
    );
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async => [];

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    appliedRemoteChanges.add(change);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<void> markLocalConflict({
    required String entityId,
    String? message,
  }) async {}

  @override
  Future<void> confirmPull() async {}

  @override
  Future<void> abandonPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async => null;
}

class Phase7MockRemoteSyncApi implements RemoteSyncApi {
  Phase7MockRemoteSyncApi({
    this.batchPushHandler,
    this.pullHandler,
  });

  final Future<List<SyncBatchPushItemResult>> Function(List<SyncOperation> ops)? batchPushHandler;
  final Future<List<SyncRemoteChange>> Function()? pullHandler;

  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    return SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  }

  @override
  Future<List<SyncBatchPushItemResult>> pushBatch(List<SyncOperation> operations) async {
    if (batchPushHandler != null) {
      return await batchPushHandler!(operations);
    }
    return operations
        .map(
          (op) => SyncBatchPushItemResult(
            operationId: op.id,
            status: 'success',
            ack: SyncUploadAck(entityId: op.entityId, remoteVersion: op.baseVersion + 1),
          ),
        )
        .toList();
  }

  @override
  Future<List<SyncRemoteChange>> pull({
    String? entityType,
    DateTime? since,
  }) async {
    if (pullHandler != null) {
      return await pullHandler!();
    }
    return [];
  }

  @override
  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  }) async => null;

  @override
  Future<void> acknowledgePull(String entityType) async {}

  @override
  Future<void> abandonPull(String entityType) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SyncQueue queue;
  late ConnectivityService connectivity;

  const companyA = 'company-phase7-a';
  const deviceA = 'device-phase7-a';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase7_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    final box = await Hive.openBox<SyncOperation>('test_sync_queue_${DateTime.now().microsecondsSinceEpoch}');
    queue = SyncQueue(
      box: box,
      companyId: companyA,
      deviceId: deviceA,
    );

    connectivity = ConnectivityService(internetProbe: () async => true);
  });

  tearDown(() async {
    queue.dispose();
    connectivity.dispose();
    await Hive.deleteFromDisk();
  });

  group('Phase 7 — Production Synchronization Reliability & Recovery', () {
    test('1. SyncErrorClassifier maps failures correctly to retryable or quarantine policies', () {
      final netErr = SyncErrorClassifier.classify(const NetworkFailure());
      expect(netErr.isRetryable, isTrue);
      expect(netErr.quarantine, isFalse);

      final tenantErr = SyncErrorClassifier.classify(const AuthorizationFailure.withDetails(code: 'tenant_mismatch'));
      expect(tenantErr.isRetryable, isFalse);
      expect(tenantErr.quarantine, isTrue);

      final authErr = SyncErrorClassifier.classify(const AuthenticationFailure());
      expect(authErr.requiresAuthentication, isTrue);
      expect(authErr.quarantine, isFalse);
    });

    test('2. Lease-based crash recovery ignores active leases and reclaims expired leases (> 5 min)', () async {
      final now = DateTime.utc(2026, 8, 26, 12, 0);

      // Active lease op (updated 1 min ago)
      final activeOp = SyncOperation(
        id: 'op-active',
        entityType: 'product',
        entityId: 'p1',
        type: SyncOperationType.create,
        status: SyncStatus.syncing,
        payload: {'name': 'Active Product'},
        createdAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
        companyId: companyA,
        deviceId: deviceA,
      );

      // Expired lease op (updated 10 min ago)
      final expiredOp = SyncOperation(
        id: 'op-expired',
        entityType: 'product',
        entityId: 'p2',
        type: SyncOperationType.create,
        status: SyncStatus.syncing,
        payload: {'name': 'Expired Product'},
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
        companyId: companyA,
        deviceId: deviceA,
      );

      await queue.update(activeOp);
      await queue.update(expiredOp);

      final reclaimed = await queue.reclaimInFlight(now: now, lease: const Duration(minutes: 5));
      expect(reclaimed, equals(1));

      final all = await queue.all();
      final op1 = all.firstWhere((o) => o.id == 'op-active');
      final op2 = all.firstWhere((o) => o.id == 'op-expired');

      expect(op1.status, equals(SyncStatus.syncing));
      expect(op2.status, equals(SyncStatus.pending));
    });

    test('3. Bounded exponential backoff caps at 60 seconds with jitter', () {
      final backoffAttempt1 = syncBackoffForAttempt(1);
      final backoffAttempt10 = syncBackoffForAttempt(10);

      expect(backoffAttempt1.inSeconds, lessThanOrEqualTo(3));
      expect(backoffAttempt10.inSeconds, lessThanOrEqualTo(61)); // 60s base + jitter ms
      expect(backoffAttempt10.inSeconds, greaterThanOrEqualTo(60));
    });

    test('4. Operations reaching max retry attempts (5) are automatically quarantined', () async {
      final op = SyncOperation(
        id: 'op-max-retry',
        entityType: 'product',
        entityId: 'p-retry',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: {'sku': 'SKU-RETRY'},
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        attemptCount: 4, // 5th attempt will fail
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.update(op);

      final handler = Phase7MockEntityHandler(entityType: 'product');
      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase7MockRemoteSyncApi(
          batchPushHandler: (ops) async => [
            SyncBatchPushItemResult(
              operationId: ops.first.id,
              status: 'error',
              failure: const ServerFailure('Internal Server Error 500'),
            ),
          ],
        ),
      );
      manager.registerHandler(handler);
      await manager.setEnabled(true);

      final result = await manager.syncNow();
      expect(result.failed, equals(1));

      final all = await queue.all();
      final updated = all.firstWhere((o) => o.id == 'op-max-retry');
      expect(updated.status, equals(SyncStatus.quarantined));
      expect(updated.lastError, contains('Exceeded max retry attempts'));
    });

    test('5. Quarantine isolation & resetQuarantine controlled recovery', () async {
      await queue.quarantine('op-quarantine-test', error: 'Manual Quarantine Test');
      
      final op = SyncOperation(
        id: 'op-quarantine-test',
        entityType: 'product',
        entityId: 'p-q',
        type: SyncOperationType.create,
        status: SyncStatus.quarantined,
        payload: {'name': 'Quarantined Product'},
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.update(op);

      final readyBefore = await queue.peekReady();
      expect(readyBefore.any((o) => o.id == 'op-quarantine-test'), isFalse);

      await queue.resetQuarantine('op-quarantine-test');

      final readyAfter = await queue.peekReady();
      expect(readyAfter.any((o) => o.id == 'op-quarantine-test'), isTrue);
      expect(readyAfter.firstWhere((o) => o.id == 'op-quarantine-test').status, equals(SyncStatus.pending));
    });

    test('6. Concurrent syncNow calls reuses ongoing Future (Sync Mutex)', () async {
      final completer = Completer<List<SyncBatchPushItemResult>>();
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-mutex',
        type: SyncOperationType.create,
        payload: {'name': 'Mutex Product'},
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.enqueue(op);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase7MockRemoteSyncApi(
          batchPushHandler: (ops) => completer.future,
        ),
      );
      manager.registerHandler(Phase7MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final f1 = manager.syncNow();
      final f2 = manager.syncNow(); // Concurrent invocation

      expect(identical(f1, f2), isTrue);

      completer.complete([
        SyncBatchPushItemResult(
          operationId: op.id,
          status: 'success',
          ack: SyncUploadAck(entityId: 'p-mutex', remoteVersion: 1),
        ),
      ]);

      final res1 = await f1;
      final res2 = await f2;
      expect(res1.uploaded, equals(1));
      expect(res2.uploaded, equals(1));
    });

    test('7. Partial batch failure acknowledges success items and retains failed items', () async {
      final op1 = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-batch-1',
        type: SyncOperationType.create,
        payload: {'sku': 'P1'},
        companyId: companyA,
        deviceId: deviceA,
      );
      final op2 = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-batch-2',
        type: SyncOperationType.create,
        payload: {'sku': 'P2'},
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.enqueue(op1);
      await queue.enqueue(op2);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase7MockRemoteSyncApi(
          batchPushHandler: (ops) async => [
            SyncBatchPushItemResult(
              operationId: ops[0].id,
              status: 'success',
              ack: SyncUploadAck(entityId: ops[0].entityId, remoteVersion: 1),
            ),
            SyncBatchPushItemResult(
              operationId: ops[1].id,
              status: 'error',
              failure: const ServerFailure('Database lock timeout 500'),
            ),
          ],
        ),
      );
      manager.registerHandler(Phase7MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.uploaded, equals(1));
      expect(res.failed, equals(1));

      final remaining = await queue.all();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals(op2.id));
      expect(remaining.first.status, equals(SyncStatus.failed));
    });

    test('8. Cross-tenant or cross-device operations are immediately quarantined', () async {
      final box = await Hive.openBox<SyncOperation>('test_phase7_spoof_${DateTime.now().microsecondsSinceEpoch}');
      final unscopedQueue = SyncQueue(box: box, companyId: null, deviceId: deviceA);

      final crossTenantOp = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-cross',
        type: SyncOperationType.create,
        payload: {'sku': 'CROSS'},
        companyId: 'company-OTHER',
        deviceId: deviceA,
      );
      await unscopedQueue.update(crossTenantOp);

      final manager = SyncManager(
        queue: unscopedQueue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase7MockRemoteSyncApi(),
      );
      manager.registerHandler(Phase7MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.failed, equals(1));

      final all = await unscopedQueue.all();
      final item = all.firstWhere((o) => o.id == crossTenantOp.id);
      expect(item.status, equals(SyncStatus.quarantined));
      expect(item.lastError, contains('Cross-tenant operation upload blocked'));
    });

    test('9. TrustedClock tamper detection blocks sync without quarantining valid queue', () async {
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-clock',
        type: SyncOperationType.create,
        payload: {'sku': 'CLOCK'},
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.enqueue(op);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.tampered,
        isTimeTrusted: () => false,
        remoteProvider: () => Phase7MockRemoteSyncApi(),
      );
      manager.registerHandler(Phase7MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.outcome, equals(SyncPassOutcome.clockTampered));

      final all = await queue.all();
      expect(all.first.status, equals(SyncStatus.pending)); // Remained pending, not deleted or quarantined
    });
  });
}
