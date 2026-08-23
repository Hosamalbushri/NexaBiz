import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/sync/sync_conflict_record.dart';
import 'package:stock_count/core/sync/sync_conflict_store.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';

import 'dart:io';
import 'package:hive/hive.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('conflict_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('SyncConflictStore & Conflict Recovery State Machine', () {
    test('SyncConflictStore saves and retrieves conflict records', () async {
      final store = SyncConflictStore();
      final record = SyncConflictRecord(
        operationId: 'op-conf-1',
        entityType: 'customer',
        entityId: 'cust-100',
        baseVersion: 1,
        serverVersion: 2,
        localPayload: {'name': 'Local Name'},
        remotePayload: {'name': 'Server Name'},
        conflictingFields: ['name'],
        createdAt: DateTime.utc(2026, 8, 23, 12, 0),
      );

      await store.save(record);
      final retrieved = await store.getByOperationId('op-conf-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.entityType, 'customer');
      expect(retrieved.serverVersion, 2);
      expect(retrieved.mergeStatus, 'unresolved');
    });

    test('resolveConflict replaces conflict operation with new operation on updated base_version', () async {
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.none],
      );

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        conflictStore: conflictStore,
        clock: () => DateTime.utc(2026, 8, 23, 12),
      );

      final originalOp = SyncOperation.create(
        entityType: 'customer',
        entityId: 'cust-200',
        type: SyncOperationType.update,
        baseVersion: 1,
        payload: {'uuid': 'cust-200', 'name': 'Stale Name'},
      );
      await queue.enqueue(originalOp);

      // Simulate 409 conflict recorded in conflict store
      final conflictRec = SyncConflictRecord(
        operationId: originalOp.id,
        entityType: 'customer',
        entityId: 'cust-200',
        baseVersion: 1,
        serverVersion: 2,
        localPayload: {'name': 'Stale Name'},
        remotePayload: {'name': 'Server Name'},
        conflictingFields: ['name'],
        createdAt: DateTime.utc(2026, 8, 23, 12),
      );
      await conflictStore.save(conflictRec);

      // Resolve conflict by picking server payload or custom merged payload
      await manager.resolveConflict(
        operationId: originalOp.id,
        resolutionStrategy: 'client_selected',
        resolvedPayload: {'uuid': 'cust-200', 'name': 'Resolved Name'},
      );

      final ops = await queue.all();
      expect(ops, hasLength(1));
      expect(ops.first.id, isNot(equals(originalOp.id))); // NEW operation_id generated
      expect(ops.first.baseVersion, equals(2)); // Updated base_version
      expect(ops.first.payload['name'], equals('Resolved Name'));
      expect(ops.first.status, equals(SyncStatus.pending));

      final updatedRec = await conflictStore.getByOperationId(originalOp.id);
      expect(updatedRec?.mergeStatus, equals('client_selected'));
      expect(updatedRec?.resolvedOperationId, equals(ops.first.id));

      await connectivity.dispose();
      await connectivityStream.close();
    });
  });
}
