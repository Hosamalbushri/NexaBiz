import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue mockSyncQueue;
  late ImportSyncBridge syncBridge;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('import_sync_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    syncBox = await Hive.openBox<SyncOperation>('sync_queue_import_test');
    mockSyncQueue = SyncQueue(
      box: syncBox,
      companyId: 'COMP-001',
      deviceId: 'DEV-99',
    );
    syncBridge = ImportSyncBridge(syncQueue: mockSyncQueue);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 22 — Universal Import Engine Offline & Sync Integration Tests', () {
    test(
      '1. Offline Import: ImportSyncMode.local sets pending status and enqueues SyncOperation',
      () async {
        const companyId = 'COMP-001';
        const entityId = 'PROD-UUID-001';

        final meta = syncBridge.resolveMetadata(
          uuid: entityId,
          companyId: companyId,
          syncMode: ImportSyncMode.local,
        );

        expect(meta.syncStatus, SyncStatus.pending);
        expect(meta.version, 1);
        expect(meta.companyId, companyId);
        expect(meta.uuid, entityId);

        await syncBridge.processSyncQueue(
          entityType: 'product',
          entityId: entityId,
          companyId: companyId,
          syncMode: ImportSyncMode.local,
          operationType: SyncOperationType.create,
          payload: {
            'uuid': entityId,
            'itemCode': 'SKU-001',
            'name': 'Offline Widget',
          },
        );

        final ops = await mockSyncQueue.all();
        expect(ops.length, 1);
        expect(ops.first.entityType, 'product');
        expect(ops.first.entityId, entityId);
        expect(ops.first.type, SyncOperationType.create);
        expect(ops.first.status, SyncStatus.pending);
        expect(ops.first.companyId, companyId);
      },
    );

    test(
      '2. Duplicate Prevention: SYNCED and REMOTE modes set synced status and DO NOT enqueue into SyncQueue',
      () async {
        const companyId = 'COMP-001';
        const syncedUuid = 'PROD-UUID-SYNCED';
        const remoteUuid = 'PROD-UUID-REMOTE';

        // Synced import
        final syncedMeta = syncBridge.resolveMetadata(
          uuid: syncedUuid,
          companyId: companyId,
          syncMode: ImportSyncMode.synced,
        );
        expect(syncedMeta.syncStatus, SyncStatus.synced);

        await syncBridge.processSyncQueue(
          entityType: 'product',
          entityId: syncedUuid,
          companyId: companyId,
          syncMode: ImportSyncMode.synced,
          operationType: SyncOperationType.create,
          payload: {'uuid': syncedUuid},
        );

        // Remote import
        final remoteMeta = syncBridge.resolveMetadata(
          uuid: remoteUuid,
          companyId: companyId,
          syncMode: ImportSyncMode.remote,
          version: 5,
        );
        expect(remoteMeta.syncStatus, SyncStatus.synced);
        expect(remoteMeta.version, 5);

        await syncBridge.processSyncQueue(
          entityType: 'product',
          entityId: remoteUuid,
          companyId: companyId,
          syncMode: ImportSyncMode.remote,
          operationType: SyncOperationType.create,
          payload: {'uuid': remoteUuid, 'version': 5},
        );

        // Verify ZERO outbox ops created
        final ops = await mockSyncQueue.all();
        expect(
          ops,
          isEmpty,
          reason:
              'Synced and Remote imports must NEVER create outbox sync operations.',
        );
      },
    );

    test(
      '3. Synchronization Pipeline: peekReady picks up offline operations for upload',
      () async {
        const companyId = 'COMP-001';

        await syncBridge.processSyncQueue(
          entityType: 'account',
          entityId: 'ACC-1000',
          companyId: companyId,
          syncMode: ImportSyncMode.local,
          operationType: SyncOperationType.create,
          payload: {'code': '1000', 'name': 'Assets'},
        );

        final readyOps = await mockSyncQueue.peekReady();
        expect(readyOps.length, 1);
        expect(readyOps.first.entityType, 'account');
        expect(readyOps.first.entityId, 'ACC-1000');

        // Simulate remote sync acknowledgment (removal from queue)
        await mockSyncQueue.remove(readyOps.first.id);
        final remaining = await mockSyncQueue.all();
        expect(remaining, isEmpty);
      },
    );

    test(
      '4. Company Isolation: Cross-tenant enqueue throws TenantIsolationException',
      () async {
        const targetCompany = 'COMP-TENANT-A';
        const attackerCompany = 'COMP-TENANT-B';

        final isolatedQueue = SyncQueue(box: syncBox, companyId: targetCompany);
        final isolatedBridge = ImportSyncBridge(syncQueue: isolatedQueue);

        expect(
          () async => await isolatedBridge.processSyncQueue(
            entityType: 'product',
            entityId: 'ATTACK-PROD',
            companyId: attackerCompany,
            syncMode: ImportSyncMode.local,
            operationType: SyncOperationType.create,
            payload: {'uuid': 'ATTACK-PROD'},
          ),
          throwsA(isA<TenantIsolationException>()),
        );
      },
    );

    test(
      '5. Metadata Preservation: UUID, companyId, version, deletedAt, and timestamps are preserved',
      () async {
        const companyId = 'COMP-001';
        const uuid = 'STABLE-UUID-777';
        final now = DateTime.now().toUtc();
        final deletedAt = now.add(const Duration(minutes: 10));

        final meta = syncBridge.resolveMetadata(
          uuid: uuid,
          companyId: companyId,
          syncMode: ImportSyncMode.remote,
          version: 12,
          createdAt: now,
          updatedAt: now,
          deletedAt: deletedAt,
        );

        expect(meta.uuid, uuid);
        expect(meta.companyId, companyId);
        expect(meta.syncStatus, SyncStatus.synced);
        expect(meta.version, 12);
        expect(meta.createdAt, now);
        expect(meta.updatedAt, now);
        expect(meta.deletedAt, deletedAt);
      },
    );
  });
}
