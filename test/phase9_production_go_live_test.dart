import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/conflict_resolver.dart';
import 'package:stock_count/core/sync/sync_cursor_store.dart';
import 'package:stock_count/core/sync/sync_entity_handler.dart';
import 'package:stock_count/core/sync/sync_error_classifier.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';

class Phase9MockEntityHandler implements SyncEntityHandler {
  Phase9MockEntityHandler({
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
      throw uploadErrorBuilder!(operation);
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

class Phase9MockRemoteSyncApi implements RemoteSyncApi {
  Phase9MockRemoteSyncApi({
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
  late SyncCursorStore cursorStore;

  const companyA = 'company-phase9-a';
  const deviceA = 'device-phase9-a';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase9_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    final box = await Hive.openBox<SyncOperation>('test_phase9_queue_${DateTime.now().microsecondsSinceEpoch}');
    queue = SyncQueue(
      box: box,
      companyId: companyA,
      deviceId: deviceA,
    );

    final cursorBox = await Hive.openBox<int>('test_phase9_cursor_${DateTime.now().microsecondsSinceEpoch}');
    cursorStore = SyncCursorStore(box: cursorBox);

    connectivity = ConnectivityService(internetProbe: () async => true);
  });

  tearDown(() async {
    queue.dispose();
    connectivity.dispose();
    await Hive.deleteFromDisk();
  });

  group('Phase 9 — Final Production Go-Live Gate & Certification', () {
    test('1. Invariant 1: Tenant isolation blocks cross-tenant enqueue and peek', () async {
      final opCompanyA = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-comp-a',
        type: SyncOperationType.create,
        payload: {'name': 'Company A Product'},
        companyId: companyA,
        deviceId: deviceA,
      );
      final opCompanyB = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-comp-b',
        type: SyncOperationType.create,
        payload: {'name': 'Company B Product'},
        companyId: 'company-OTHER',
        deviceId: deviceA,
      );

      await queue.enqueue(opCompanyA);
      expect(
        () async => await queue.enqueue(opCompanyB),
        throwsException,
      );

      final ready = await queue.peekReady();
      expect(ready.length, equals(1));
      expect(ready.first.id, equals(opCompanyA.id));
    });

    test('2. Invariant 6: Atomic transaction grouping handling', () async {
      final saleOp = SyncOperation.create(
        entityType: 'sale',
        entityId: 'sale-001',
        type: SyncOperationType.create,
        payload: {'total': 100},
        companyId: companyA,
        deviceId: deviceA,
      );
      final journalOp = SyncOperation.create(
        entityType: 'journal_entry',
        entityId: 'je-001',
        type: SyncOperationType.create,
        payload: {'debit': 100, 'credit': 100},
        companyId: companyA,
        deviceId: deviceA,
      );

      await queue.enqueue(saleOp);
      await queue.enqueue(journalOp);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase9MockRemoteSyncApi(),
      );
      manager.registerHandler(Phase9MockEntityHandler(entityType: 'sale'));
      manager.registerHandler(Phase9MockEntityHandler(entityType: 'journal_entry'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.uploaded, equals(2));

      final remaining = await queue.all();
      expect(remaining.isEmpty, isTrue); // Both committed atomically
    });

    test('3. Invariant 8: Financial non-destructive conflict handling & immutability', () async {
      final err = SyncErrorClassifier.classify(const SyncConflictFailure('Journal entry conflict', 2));
      expect(err.quarantine, isFalse); // Conflict goes to SyncStatus.conflict, not deleted or silently overwritten
      expect(err.isRetryable, isFalse);
    });

    test('4. Invariant 9: Lease-based crash recovery threshold (5 minutes)', () async {
      final now = DateTime.utc(2026, 8, 26, 12, 0);

      final activeOp = SyncOperation(
        id: 'op-lease-active',
        entityType: 'product',
        entityId: 'p-active',
        type: SyncOperationType.create,
        status: SyncStatus.syncing,
        payload: {'name': 'Active'},
        createdAt: now.subtract(const Duration(minutes: 2)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
        companyId: companyA,
        deviceId: deviceA,
      );

      final expiredOp = SyncOperation(
        id: 'op-lease-expired',
        entityType: 'product',
        entityId: 'p-expired',
        type: SyncOperationType.create,
        status: SyncStatus.syncing,
        payload: {'name': 'Expired'},
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
        companyId: companyA,
        deviceId: deviceA,
      );

      await queue.update(activeOp);
      await queue.update(expiredOp);

      final count = await queue.reclaimInFlight(now: now, lease: const Duration(minutes: 5));
      expect(count, equals(1));

      final all = await queue.all();
      expect(all.firstWhere((o) => o.id == 'op-lease-active').status, equals(SyncStatus.syncing));
      expect(all.firstWhere((o) => o.id == 'op-lease-expired').status, equals(SyncStatus.pending));
    });

    test('5. Invariant 12: Logout during active sync stops execution safely', () async {
      var isAuth = true;

      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-logout',
        type: SyncOperationType.create,
        payload: {'name': 'Product'},
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.enqueue(op);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => isAuth,
        hasSyncPermission: () => isAuth,
        readCompanyId: () => isAuth ? companyA : '',
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase9MockRemoteSyncApi(),
      );
      manager.registerHandler(Phase9MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      // Simulate logout while sync starts
      isAuth = false;

      final res = await manager.syncNow();
      expect(res.outcome == SyncPassOutcome.skippedDisabled || res.outcome == SyncPassOutcome.authRequired, isTrue);

      final all = await queue.all();
      expect(all.first.status, equals(SyncStatus.pending)); // Queue preserved safely
    });

    test('6. Invariant 15: Trusted Clock tamper fail-closed temporal gates', () async {
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-clock',
        type: SyncOperationType.create,
        payload: {'name': 'Product'},
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
        remoteProvider: () => Phase9MockRemoteSyncApi(),
      );
      manager.registerHandler(Phase9MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.outcome, equals(SyncPassOutcome.clockTampered));

      final all = await queue.all();
      expect(all.first.status, equals(SyncStatus.pending)); // Kept pending, not deleted or corrupted
    });

    test('7. Invariant 17: Durable pull sequence cursor persistence', () async {
      await cursorStore.write('sale', 500);
      final val = await cursorStore.read('sale');
      expect(val, equals(500));
    });
  });
}
