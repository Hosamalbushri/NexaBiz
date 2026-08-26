import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';

class _RecordingHandler extends SyncEntityHandler {
  _RecordingHandler(this._remote);

  final RemoteSyncApi _remote;
  final applied = <String>[];
  var conflictProbes = 0;

  @override
  String get entityType => 'account';

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) =>
      _remote.pull(entityType: entityType, since: since);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    applied.add(change.entityId);
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
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    conflictProbes++;
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return const ConflictResolver().resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: true,
      remotePayload: meta.payload,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;
  late StreamController<List<ConnectivityResult>> connectivityStream;
  late ConnectivityService connectivity;
  late InMemoryRemoteSyncApi remote;
  SyncManager? manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_create_idem_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    remote = InMemoryRemoteSyncApi();
    connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
    connectivity = ConnectivityService(
      connectivityStream: connectivityStream.stream,
      initialResults: const [ConnectivityResult.wifi],
    );
  });

  tearDown(() async {
    await manager?.dispose();
    manager = null;
    await connectivity.dispose();
    await connectivityStream.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('SyncOperation.create forces baseVersion 0', () {
    final op = SyncOperation.create(
      entityType: 'account',
      entityId: 'sys-cash',
      type: SyncOperationType.create,
      baseVersion: 7,
      payload: const {'name': 'Cash'},
    );
    expect(op.baseVersion, 0);
  });

  test('ConflictResolver never marks create as conflict', () {
    final op = SyncOperation(
      id: 'q1',
      entityType: 'account',
      entityId: 'sys-cash',
      type: SyncOperationType.create,
      status: SyncStatus.pending,
      payload: const {'name': 'Cash'},
      createdAt: DateTime.utc(2026, 8, 16),
      updatedAt: DateTime.utc(2026, 8, 16),
      baseVersion: 1,
    );
    final decision = const ConflictResolver().resolve(
      localOperation: op,
      remoteVersion: 9,
      remoteUpdatedAt: DateTime.utc(2026, 8, 17),
      preferServerWhenLocalSynced: true,
      remotePayload: const {'name': 'Cash (server)'},
    );
    expect(decision, ConflictDecision.uploadLocal);
  });

  test('InMemory create is idempotent when remote version advanced', () async {
    final now = DateTime.utc(2026, 8, 16);
    remote.seed(
      'account',
      RemoteEntityMeta(
        entityId: 'sys-cash',
        version: 2,
        updatedAt: now,
        payload: const {'name': 'Cash'},
      ),
    );
    final ack = await remote.push(
      entityType: 'account',
      operation: SyncOperation(
        id: 'create-b',
        entityType: 'account',
        entityId: 'sys-cash',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'Cash'},
        createdAt: now,
        updatedAt: now,
        baseVersion: 1,
      ),
    );
    expect(ack.remoteVersion, 2);
  });

  test('legacy create with baseVersion>0 uploads without conflict probe', () async {
    final now = DateTime.utc(2026, 8, 16, 13);
    remote.seed(
      'account',
      RemoteEntityMeta(
        entityId: 'sys-cash',
        version: 2,
        updatedAt: now,
        payload: const {'name': 'Cash'},
      ),
    );
    await queue.enqueue(
      SyncOperation(
        id: 'legacy-create',
        entityType: 'account',
        entityId: 'sys-cash',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'Cash'},
        createdAt: now,
        updatedAt: now,
        baseVersion: 1,
      ),
    );

    final handler = _RecordingHandler(remote);
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      remoteProvider: () => remote,
      clock: () => now,
    );
    manager!.registerHandler(handler);
    await manager!.start(enabled: true);

    final result = await manager!.syncNow(notify: false, download: false);
    expect(result.conflicts, 0);
    expect(result.uploaded, 1);
    expect(handler.conflictProbes, 0);
    expect(await queue.all(), isEmpty);
  });

  test('pull drops redundant local create queue ops', () async {
    final now = DateTime.utc(2026, 8, 16, 14);
    remote.seed(
      'account',
      RemoteEntityMeta(
        entityId: 'sys-cash',
        version: 1,
        updatedAt: now,
        payload: const {'name': 'Cash'},
      ),
    );
    await queue.enqueue(
      SyncOperation(
        id: 'seed-create',
        entityType: 'account',
        entityId: 'sys-cash',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'Cash'},
        createdAt: now,
        updatedAt: now,
        baseVersion: 0,
      ),
    );

    final handler = _RecordingHandler(remote);
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      remoteProvider: () => remote,
      clock: () => now,
    );
    manager!.registerHandler(handler);
    await manager!.start(enabled: true);

    final result = await manager!.syncNow(
      notify: false,
      upload: false,
      download: true,
    );
    expect(result.downloaded, 1);
    expect(handler.applied, ['sys-cash']);
    expect(await queue.all(), isEmpty);
  });
}
