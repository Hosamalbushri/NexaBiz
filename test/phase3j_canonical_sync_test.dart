import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_overview.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_manager.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

class _FakeConnectivityService implements ConnectivityService {
  @override
  bool get isOnline => true;

  @override
  ConnectivityStatus get current => ConnectivityStatus.online;

  @override
  Stream<ConnectivityStatus> get onStatusChanged => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  void debugSetStatus(ConnectivityStatus status) {}

  @override
  Future<void> dispose() async {}
}

class _InMemorySyncQueue implements SyncQueue {
  final Map<String, SyncOperation> _ops = {};

  @override
  String? get companyId => null;

  @override
  String? get deviceId => null;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    _ops[operation.id] = operation;
  }

  @override
  Future<void> remove(String id) async {
    _ops.remove(id);
  }

  @override
  Future<void> update(SyncOperation operation) async {
    _ops[operation.id] = operation;
  }

  @override
  Future<List<SyncOperation>> all() async => _ops.values.toList();

  @override
  Future<List<SyncOperation>> peekAll() async => _ops.values.toList();

  @override
  Future<List<SyncOperation>> peekReady({DateTime? now}) async {
    final refTime = now ?? DateTime.now().toUtc();
    return _ops.values
        .where((op) =>
            op.status == SyncStatus.pending &&
            (op.nextRetryAt == null || !op.nextRetryAt!.isAfter(refTime)))
        .toList();
  }

  @override
  Future<int> reclaimInFlight({DateTime? now, Duration lease = const Duration(minutes: 5)}) async {
    final refTime = now ?? DateTime.now().toUtc();
    final timeoutThreshold = refTime.subtract(lease);
    var reclaimed = 0;
    for (final op in _ops.values.toList()) {
      if (op.status == SyncStatus.syncing &&
          op.updatedAt.isBefore(timeoutThreshold)) {
        _ops[op.id] = op.copyWith(
          status: SyncStatus.pending,
          clearNextRetryAt: true,
        );
        reclaimed++;
      }
    }
    return reclaimed;
  }

  @override
  Future<void> quarantine(String id, {required String error}) async {
    final op = _ops[id];
    if (op != null) {
      _ops[id] = op.copyWith(
        status: SyncStatus.quarantined,
        lastError: error,
      );
    }
  }

  @override
  Future<void> clearSynced() async {
    _ops.removeWhere((_, op) => op.status == SyncStatus.synced);
  }

  @override
  Future<int> countByStatus(SyncStatus status) async {
    return _ops.values.where((op) => op.status == status).length;
  }

  @override
  Future<void> removeForEntity({required String entityType, required String entityId}) async {
    _ops.removeWhere((_, op) => op.entityType == entityType && op.entityId == entityId);
  }

  @override
  Future<void> resetQuarantine(String id) async {
    final op = _ops[id];
    if (op != null) {
      _ops[id] = op.copyWith(status: SyncStatus.pending, clearLastError: true);
    }
  }

  @override
  void dispose() {}

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<void> removeCreatesForEntity({
    required String entityType,
    required String entityId,
  }) async {
    _ops.removeWhere(
      (_, op) =>
          op.entityType == entityType &&
          op.entityId == entityId &&
          op.type == SyncOperationType.create,
    );
  }
}

void main() {
  late _InMemorySyncQueue queue;
  late _FakeConnectivityService connectivity;

  setUp(() {
    queue = _InMemorySyncQueue();
    connectivity = _FakeConnectivityService();
  });

  group('Phase 3J — Canonical Sync & Replication Baseline Tests', () {
    test('Sync operation uses stable 36-character UUID v4 identity', () {
      final entityUuid = generateUuidV4();
      final companyId = generateUuidV4();

      final op = SyncOperation.create(
        entityType: 'product',
        entityId: entityUuid,
        type: SyncOperationType.create,
        payload: {'name': 'Test Product'},
        companyId: companyId,
      );

      expect(op.id.length, equals(36));
      expect(op.entityId.length, equals(36));
      expect(op.companyId?.length, equals(36));
    });

    test('Sync pass fails-closed when company scope is missing (System Scope)', () async {
      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => '', // Empty / missing company scope
      );

      await manager.setEnabled(true);
      final result = await manager.syncNow();

      expect(result.outcome, equals(SyncPassOutcome.skippedDisabled));
    });

    test('Cross-tenant operation upload is quarantined during sync pass', () async {
      final activeCompanyId = 'company-active-3j';
      final crossCompanyId = 'company-other-3j';

      final entityUuid = generateUuidV4();

      final op = SyncOperation.create(
        entityType: 'product',
        entityId: entityUuid,
        type: SyncOperationType.create,
        payload: {'name': 'Cross Tenant Product'},
        companyId: crossCompanyId, // Mismatched company ID
      );

      await queue.enqueue(op);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readCompanyId: () => activeCompanyId,
      );

      await manager.setEnabled(true);
      await manager.syncNow();

      final allOps = await queue.all();
      final quarantinedOp = allOps.firstWhere((o) => o.entityId == entityUuid);

      expect(quarantinedOp.status, equals(SyncStatus.quarantined));
      expect(quarantinedOp.lastError, contains('Cross-tenant operation upload blocked'));
    });

    test('Reclaim in-flight operations resets stuck operations back to pending', () async {
      final opUuid = generateUuidV4();
      final now = DateTime.now().toUtc();
      final oldTime = now.subtract(const Duration(minutes: 10));

      final stuckOp = SyncOperation(
        id: opUuid,
        entityType: 'sale',
        entityId: generateUuidV4(),
        type: SyncOperationType.create,
        payload: {'total': 100.0},
        status: SyncStatus.syncing,
        baseVersion: 1,
        attemptCount: 1,
        createdAt: oldTime,
        updatedAt: oldTime,
      );

      await queue.enqueue(stuckOp);
      await queue.reclaimInFlight(now: now);

      final allOps = await queue.all();
      final reclaimedOp = allOps.firstWhere((o) => o.id == opUuid);

      expect(reclaimedOp.status, equals(SyncStatus.pending));
    });
  });
}
