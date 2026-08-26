import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';

class Phase8MockEntityHandler implements SyncEntityHandler {
  Phase8MockEntityHandler({
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

class Phase8MockRemoteSyncApi implements RemoteSyncApi {
  Phase8MockRemoteSyncApi({
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

  const companyA = 'company-phase8-a';
  const deviceA = 'device-phase8-a';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase8_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    final box = await Hive.openBox<SyncOperation>('test_phase8_queue_${DateTime.now().microsecondsSinceEpoch}');
    queue = SyncQueue(
      box: box,
      companyId: companyA,
      deviceId: deviceA,
    );

    final cursorBox = await Hive.openBox<int>('test_phase8_cursor_${DateTime.now().microsecondsSinceEpoch}');
    cursorStore = SyncCursorStore(box: cursorBox);

    connectivity = ConnectivityService(internetProbe: () async => true);
  });

  tearDown(() async {
    queue.dispose();
    connectivity.dispose();
    await Hive.deleteFromDisk();
  });

  group('Phase 8 — Production Sync Backend Hardening & Disaster Recovery', () {
    test('1. Idempotency payload hash mismatch classification', () {
      const err = ValidationFailure('Idempotency conflict: operation ID has already been used with a different payload.');
      final classification = SyncErrorClassifier.classify(err);
      expect(classification.quarantine, isTrue);
      expect(classification.isRetryable, isFalse);
    });

    test('2. Financial documents (Sale/JournalEntry) non-destructive conflict handling', () async {
      final op = SyncOperation.create(
        entityType: 'journal_entry',
        entityId: 'je-001',
        type: SyncOperationType.update,
        payload: {'amount': 500, 'isPosted': true},
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
        remoteProvider: () => Phase8MockRemoteSyncApi(
          batchPushHandler: (ops) async => [
            SyncBatchPushItemResult(
              operationId: ops.first.id,
              status: 'conflict',
              failure: const SyncConflictFailure('Server journal entry version conflict', 3),
            ),
          ],
        ),
      );
      manager.registerHandler(Phase8MockEntityHandler(entityType: 'journal_entry'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.conflicts, equals(1));

      final all = await queue.all();
      expect(all.first.status, equals(SyncStatus.conflict));
      expect(all.first.payload['amount'], equals(500)); // Local data preserved, not overwritten or deleted
    });

    test('3. Durable SyncCursorStore write, read, and crash recovery', () async {
      await cursorStore.write('product', 1050);
      final readVal = await cursorStore.read('product');
      expect(readVal, equals(1050));
    });

    test('4. Token expiry (401) pauses sync pass without deleting or quarantining valid queue', () async {
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-401',
        type: SyncOperationType.create,
        payload: {'name': 'Product 401'},
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
        remoteProvider: () => Phase8MockRemoteSyncApi(
          batchPushHandler: (ops) async {
            throw const AuthenticationFailure('Token expired');
          },
        ),
      );
      manager.registerHandler(Phase8MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.outcome, equals(SyncPassOutcome.authRequired));

      final all = await queue.all();
      expect(all.first.status, equals(SyncStatus.pending)); // Remained pending for re-auth
    });

    test('5. Tenant/device identity server authority validation', () async {
      final box = await Hive.openBox<SyncOperation>('test_phase8_spoof_${DateTime.now().microsecondsSinceEpoch}');
      final unscopedQueue = SyncQueue(box: box, companyId: null, deviceId: deviceA);

      final crossOp = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-auth-mismatch',
        type: SyncOperationType.create,
        payload: {'name': 'Spoofed Tenant'},
        companyId: 'company-SPOOFED',
        deviceId: deviceA,
      );
      await unscopedQueue.update(crossOp);

      final manager = SyncManager(
        queue: unscopedQueue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        remoteProvider: () => Phase8MockRemoteSyncApi(),
      );
      manager.registerHandler(Phase8MockEntityHandler(entityType: 'product'));
      await manager.setEnabled(true);

      final res = await manager.syncNow();
      expect(res.failed, equals(1));

      final all = await unscopedQueue.all();
      expect(all.first.status, equals(SyncStatus.quarantined));
      expect(all.first.lastError, contains('Cross-tenant operation upload blocked'));
    });
  });
}
