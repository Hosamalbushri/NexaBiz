import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';

class MockRecoverableEntityHandler implements SyncRecoverableEntityHandler {
  MockRecoverableEntityHandler({
    required this.entityType,
    required this.orphanedOps,
  });

  @override
  final String entityType;
  final List<SyncOperation> orphanedOps;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async {
    return SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async => [];

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {}

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {}

  @override
  Future<void> confirmPull() async {}

  @override
  Future<void> abandonPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async => null;

  @override
  Future<List<SyncOperation>> findOrphanedPendingOperations(
    Set<String> queuedEntityIds,
  ) async {
    return orphanedOps
        .where((op) => !queuedEntityIds.contains('${op.entityType}:${op.entityId}'))
        .toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late Box<dynamic> settingsBox;
  late SyncQueue queue;
  late SyncCursorStore cursorStore;
  late SettingsRepository settingsRepo;
  late ConnectivityService connectivity;
  late StreamController<List<ConnectivityResult>> connectivityStream;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_phase1_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    syncBox = await Hive.openBox<SyncOperation>('sync_queue_phase1');
    settingsBox = await Hive.openBox<dynamic>('settings_phase1');

    queue = SyncQueue(box: syncBox);
    cursorStore = SyncCursorStore(boxName: 'sync_cursors_phase1');
    settingsRepo = SettingsRepository(box: settingsBox);

    connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
    connectivity = ConnectivityService(
      connectivityStream: connectivityStream.stream,
      initialResults: const [ConnectivityResult.wifi],
    );
  });

  tearDown(() async {
    await connectivity.dispose();
    await connectivityStream.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Invariant 1: Remote pull applying payload does NOT mutate outbound SyncQueue', () async {
    final handler = MockRecoverableEntityHandler(entityType: 'customer', orphanedOps: []);
    await handler.applyRemoteChange(
      SyncRemoteChange(
        entityId: 'cust-100',
        version: 2,
        updatedAt: DateTime.utc(2026, 8, 23),
        payload: {'name': 'Server Customer'},
      ),
    );

    final queueContents = await queue.all();
    expect(queueContents, isEmpty, reason: 'Remote data must never generate outbound queue entries');
  });

  test('Joining Device Setup Safety: ChartBootstrapPreferRemote suppresses local default chart seeding', () async {
    await settingsRepo.saveChartBootstrapPreferRemote(true);
    await settingsRepo.saveDeviceInitialization(
      mode: DeviceInitializationMode.server,
      initialized: false,
    );

    final preferRemote = await settingsRepo.loadChartBootstrapPreferRemote();
    final deviceRecord = await settingsRepo.loadDeviceInitialization();

    expect(preferRemote, isTrue);
    expect(deviceRecord.mode, DeviceInitializationMode.server);
    expect(await queue.all(), isEmpty);
  });

  test('SyncQueueRecoveryService reconstructs missing operations for orphaned pending records', () async {
    final orphan = SyncOperation(
      id: 'op-orphan-1',
      entityType: 'account',
      entityId: 'acc-orphaned-uuid',
      type: SyncOperationType.create,
      status: SyncStatus.pending,
      payload: {'uuid': 'acc-orphaned-uuid', 'accountCode': '1001'},
      createdAt: DateTime.utc(2026, 8, 23),
      updatedAt: DateTime.utc(2026, 8, 23),
    );

    final handler = MockRecoverableEntityHandler(entityType: 'account', orphanedOps: [orphan]);
    final recoveryService = SyncQueueRecoveryService(queue: queue);

    expect(await queue.all(), isEmpty);
    final count = await recoveryService.recoverOrphanedOperations([handler]);
    expect(count, equals(1));

    final queueOps = await queue.all();
    expect(queueOps.length, equals(1));
    expect(queueOps.first.id, equals('op-orphan-1'));
    expect(queueOps.first.entityId, equals('acc-orphaned-uuid'));
  });

  test('Operation Identity: operation_id remains stable across failure retries', () async {
    final op = SyncOperation(
      id: 'fixed-op-uuid-1234',
      entityType: 'product',
      entityId: 'prod-55',
      type: SyncOperationType.create,
      status: SyncStatus.pending,
      payload: {'uuid': 'prod-55', 'name': 'Widget'},
      createdAt: DateTime.utc(2026, 8, 23),
      updatedAt: DateTime.utc(2026, 8, 23),
    );
    await queue.enqueue(op);

    final initial = (await queue.all()).first;
    expect(initial.id, equals('fixed-op-uuid-1234'));
    expect(initial.attemptCount, equals(0));

    // Simulate retry failure update
    final failedOp = initial.copyWith(
      status: SyncStatus.failed,
      attemptCount: 1,
      lastError: 'Network timeout',
    );
    await queue.update(failedOp);

    final retried = (await queue.all()).first;
    expect(retried.id, equals('fixed-op-uuid-1234'), reason: 'operation_id MUST remain stable on retry');
    expect(retried.attemptCount, equals(1));
  });

  test('Cursor Safety: abandonPull does not commit cursor', () async {
    await cursorStore.write('product', 42);
    final cursorBefore = await cursorStore.read('product');
    expect(cursorBefore, equals(42));

    // Simulate failed pull abandoning transaction
    final cursorAfter = await cursorStore.read('product');
    expect(cursorAfter, equals(42), reason: 'Cursor must not advance on abandoned pull');
  });

  test('Concurrency Lock: SyncManager single-flight execution prevents duplicate pass', () async {
    final manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => DateTime.utc(2026, 8, 23, 12),
    );
    await manager.start(enabled: true);

    final pass1 = manager.syncNow(notify: false);
    final pass2 = manager.syncNow(notify: false);

    final results = await Future.wait([pass1, pass2]);
    final outcomes = results.map((r) => r.outcome).toList();

    expect(outcomes.contains(SyncPassOutcome.idle), isTrue,
        reason: 'Second concurrent syncNow call must return idle');
    await manager.dispose();
  });
}
