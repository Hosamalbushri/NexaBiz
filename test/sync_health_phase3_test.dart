import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/conflict_resolver.dart';
import 'package:stock_count/core/sync/sync_cursor_store.dart';
import 'package:stock_count/core/sync/sync_entity_handler.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class _FakeHandler extends SyncEntityHandler {
  _FakeHandler(this._remote);

  final RemoteSyncApi _remote;
  Object? uploadError;
  final applied = <String>[];

  @override
  String get entityType => 'widget';

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async {
    final err = uploadError;
    if (err != null) {
      throw err;
    }
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
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    return ConflictDecision.uploadLocal;
  }
}

class _AuthFailingRemote extends InMemoryRemoteSyncApi {
  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    throw const AuthenticationFailure('expired');
  }

  @override
  Future<List<SyncRemoteChange>> pull({
    required String entityType,
    DateTime? since,
  }) async {
    return const [];
  }
}

class _ForbiddenRemote extends InMemoryRemoteSyncApi {
  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    throw const AuthorizationFailure('no permission');
  }

  @override
  Future<List<SyncRemoteChange>> pull({
    required String entityType,
    DateTime? since,
  }) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late Box<int> cursorBox;
  late SyncQueue queue;
  late StreamController<List<ConnectivityResult>> connectivityStream;
  late ConnectivityService connectivity;
  SyncManager? manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_health_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    cursorBox = await Hive.openBox<int>('sync_cursors');
    queue = SyncQueue(box: syncBox);
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

  test('cursor store survives box reopen', () async {
    final store = SyncCursorStore(box: cursorBox);
    await store.write('product', 42);
    expect(await store.read('product'), 42);

    final again = SyncCursorStore(box: cursorBox);
    expect(await again.read('product'), 42);
  });

  test('reclaimInFlight resets syncing to pending', () async {
    final now = DateTime.utc(2026, 8, 16, 1);
    await queue.enqueue(
      SyncOperation(
        id: 'op-1',
        entityType: 'widget',
        entityId: 'e-1',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'a'},
        createdAt: now,
        updatedAt: now,
      ),
    );
    final pending = (await queue.all()).first;
    await queue.update(
      pending.copyWith(status: SyncStatus.syncing, updatedAt: now),
    );

    expect(await queue.peekReady(now: now), isEmpty);
    final recovered = await queue.reclaimInFlight(now: now);
    expect(recovered, 1);
    final ready = await queue.peekReady(now: now);
    expect(ready, hasLength(1));
    expect(ready.first.status, SyncStatus.pending);
  });

  test('start reclaims stuck syncing ops', () async {
    final now = DateTime.utc(2026, 8, 16, 2);
    await syncBox.put(
      'stuck',
      SyncOperation(
        id: 'stuck',
        entityType: 'widget',
        entityId: 'e-2',
        type: SyncOperationType.update,
        status: SyncStatus.syncing,
        payload: const {'name': 'b'},
        createdAt: now,
        updatedAt: now,
      ),
    );

    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => now,
    );
    manager!.registerHandler(_FakeHandler(InMemoryRemoteSyncApi()));
    await manager!.start(enabled: true);

    final ready = await queue.peekReady(now: now);
    expect(ready.map((o) => o.id), contains('stuck'));
  });

  test('401 during upload returns authRequired and keeps pending', () async {
    final now = DateTime.utc(2026, 8, 16, 3);
    await queue.enqueue(
      SyncOperation(
        id: 'auth-op',
        entityType: 'widget',
        entityId: 'e-3',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'c'},
        createdAt: now,
        updatedAt: now,
      ),
    );

    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => now,
    );
    manager!.registerHandler(_FakeHandler(_AuthFailingRemote()));
    await manager!.start(enabled: true);

    final result = await manager!.syncNow(notify: false);
    expect(result.outcome, SyncPassOutcome.authRequired);

    final ops = await queue.all();
    expect(ops.single.status, SyncStatus.pending);
    expect(ops.single.nextRetryAt, isNull);
  });

  test('403 during upload marks rejected without backoff', () async {
    final now = DateTime.utc(2026, 8, 16, 4);
    await queue.enqueue(
      SyncOperation(
        id: 'forbid-op',
        entityType: 'widget',
        entityId: 'e-4',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'd'},
        createdAt: now,
        updatedAt: now,
      ),
    );

    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => now,
    );
    manager!.registerHandler(_FakeHandler(_ForbiddenRemote()));
    await manager!.start(enabled: true);

    final result = await manager!.syncNow(notify: false);
    expect(result.outcome, SyncPassOutcome.failed);

    final ops = await queue.all();
    expect(ops.single.status, SyncStatus.rejected);
    expect(ops.single.nextRetryAt, isNull);
  });
}
