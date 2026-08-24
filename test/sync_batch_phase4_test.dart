import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/conflict_resolver.dart';
import 'package:stock_count/core/sync/sync_entity_handler.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';

class _CountingRemote extends InMemoryRemoteSyncApi {
  var pushCalls = 0;
  var batchCalls = 0;
  var getMetaCalls = 0;

  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    pushCalls++;
    return super.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncBatchPushItemResult>> pushBatch(
    List<SyncOperation> operations,
  ) async {
    batchCalls++;
    return super.pushBatch(operations);
  }

  @override
  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  }) async {
    getMetaCalls++;
    return super.getMeta(entityType: entityType, entityId: entityId);
  }
}

class _BatchHandler extends SyncEntityHandler {
  _BatchHandler(this._remote);

  final RemoteSyncApi _remote;
  var conflictProbes = 0;

  @override
  String get entityType => 'widget';

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) =>
      _remote.pull(entityType: entityType, since: since);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {}

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
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    conflictProbes++;
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return ConflictDecision.uploadLocal;
  }
}



void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;
  late StreamController<List<ConnectivityResult>> connectivityStream;
  late ConnectivityService connectivity;
  late _CountingRemote remote;
  SyncManager? manager;

  setUp(() async {
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(List.generate(32, (i) => i));
    tempDir = await Directory.systemTemp.createTemp('sync_batch_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    remote = _CountingRemote();
    connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
    connectivity = ConnectivityService(
      connectivityStream: connectivityStream.stream,
      initialResults: const [ConnectivityResult.wifi],
    );
  });

  tearDown(() async {
    HiveEncryptionKeyStore.debugFixedKey = null;
    await manager?.dispose();
    manager = null;
    await connectivity.dispose();
    await connectivityStream.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> enqueueCreates(int count, DateTime now) async {
    for (var i = 0; i < count; i++) {
      await queue.enqueue(
        SyncOperation(
          id: 'op-$i',
          entityType: 'widget',
          entityId: '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          type: SyncOperationType.create,
          status: SyncStatus.pending,
          payload: {'name': 'item-$i'},
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  test('batch upload uses pushBatch once for chunk of creates', () async {
    final now = DateTime.utc(2026, 8, 16, 10);
    await enqueueCreates(5, now);

    final handler = _BatchHandler(remote);
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      remoteProvider: () => remote,
      clock: () => now,
      batchChunkSize: 50,
    );
    manager!.registerHandler(handler);
    await manager!.start(enabled: true);

    final result = await manager!.syncNow(notify: false);
    expect(result.outcome, SyncPassOutcome.completed);
    expect(result.uploaded, 5);
    expect(remote.batchCalls, 1);
    // Creates (baseVersion 0) must not probe getMeta.
    expect(handler.conflictProbes, 0);
    expect(remote.getMetaCalls, 0);
    expect(await queue.all(), isEmpty);
  });

  test('100 creates: one batch call when chunkSize >= 100', () async {
    final now = DateTime.utc(2026, 8, 16, 11);
    await enqueueCreates(100, now);

    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      remoteProvider: () => remote,
      clock: () => now,
      batchChunkSize: 100,
    );
    manager!.registerHandler(_BatchHandler(remote));
    await manager!.start(enabled: true);

    final sw = Stopwatch()..start();
    final result = await manager!.syncNow(notify: false);
    sw.stop();

    expect(result.uploaded, 100);
    expect(remote.batchCalls, 1);
    expect(remote.pushCalls, 100); // in-memory batch still uses push under the hood
    // Soft budget for in-memory path (not a LAN measurement).
    expect(sw.elapsedMilliseconds, lessThan(5000));
  });

  test('update with baseVersion still probes conflict', () async {
    final now = DateTime.utc(2026, 8, 16, 12);
    remote.seed(
      'widget',
      RemoteEntityMeta(
        entityId: 'e-1',
        version: 1,
        updatedAt: now,
        payload: const {'name': 'old'},
      ),
    );
    await queue.enqueue(
      SyncOperation(
        id: 'upd-1',
        entityType: 'widget',
        entityId: 'e-1',
        type: SyncOperationType.update,
        status: SyncStatus.pending,
        payload: const {'name': 'new'},
        createdAt: now,
        updatedAt: now,
        baseVersion: 1,
      ),
    );

    final handler = _BatchHandler(remote);
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      remoteProvider: () => remote,
      clock: () => now,
    );
    manager!.registerHandler(handler);
    await manager!.start(enabled: true);

    await manager!.syncNow(notify: false);
    expect(handler.conflictProbes, 1);
    expect(remote.getMetaCalls, 1);
  });
}
