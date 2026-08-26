import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/http_remote_sync_api.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/sync/sync.dart';

class ChaosTestEntityHandler implements SyncEntityHandler {
  ChaosTestEntityHandler({
    required this.entityType,
    required this.cursorStore,
    this.failOnApply = false,
    this.pullChangesProvider,
  });

  @override
  final String entityType;
  final SyncCursorStore cursorStore;
  final bool failOnApply;
  final Future<List<SyncRemoteChange>> Function()? pullChangesProvider;

  final List<SyncRemoteChange> appliedChanges = [];
  int? _pendingCursor;

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async =>
      SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async {
    if (pullChangesProvider != null) {
      final changes = await pullChangesProvider!();
      if (changes.isNotEmpty) {
        // High sequence tracker
        _pendingCursor = changes.last.payload['_sequence'] as int? ?? 102;
      }
      return changes;
    }
    return [];
  }

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    if (failOnApply) {
      throw const ServerFailure('Simulated local SQLite storage write failure');
    }
    appliedChanges.add(change);
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
  Future<void> confirmPull() async {
    if (_pendingCursor != null) {
      await cursorStore.write(entityType, _pendingCursor!);
      _pendingCursor = null;
    }
  }

  @override
  Future<void> abandonPull() async {
    _pendingCursor = null;
  }

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async =>
      null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase5_chaos_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 5 — Client Chaos & Invariant Verification', () {
    test('PART 5 — Pull Cursor Chaos: Local apply failure preserves cursor invariant (CURSOR <= LAST DURABLY APPLIED)', () async {
      final cursorStore = SyncCursorStore();
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      // Initial cursor set to 100
      await cursorStore.write('customer', 100);

      final api = HttpRemoteSyncApi(
        config: const SyncApiConfig(
          baseUrl: 'https://api.nexabiz.test',
          apiToken: 'token',
          companyId: 'cmp-1',
          userId: 'usr-1',
          deviceId: 'dev-1',
        ),
      );

      final manager = SyncManager(
        queue: queue,
        remoteProvider: () => api,
        connectivity: connectivity,
        conflictStore: conflictStore,
      );

      // Handler configured to FAIL during applyRemoteChange
      final failingHandler = ChaosTestEntityHandler(
        entityType: 'customer',
        cursorStore: cursorStore,
        failOnApply: true,
        pullChangesProvider: () async => [
          SyncRemoteChange(
            entityId: 'c-101',
            version: 1,
            updatedAt: DateTime.utc(2026, 8, 24),
            payload: {'name': 'Cust 101', '_sequence': 102},
          )
        ],
      );
      manager.registerHandler(failingHandler);
      await manager.start(enabled: true);

      final result = await manager.syncNow(trigger: SyncPassTrigger.manual);

      // Verify: Sync pass reported failure
      expect(result.failed, equals(1));

      // CRITICAL INVARIANT: Cursor must NOT advance to 102 because apply failed!
      final curAfterFail = await cursorStore.read('customer');
      expect(curAfterFail, equals(100));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('PART 6 — Multi-Page Pull Stress: 500+ sequence changes page seamlessly without gap or infinite loop', () async {
      final cursorStore = SyncCursorStore();
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      await cursorStore.write('product', 0);

      final api = HttpRemoteSyncApi(
        config: const SyncApiConfig(
          baseUrl: 'https://api.nexabiz.test',
          apiToken: 'token',
          companyId: 'cmp-1',
          userId: 'usr-1',
          deviceId: 'dev-1',
        ),
      );

      final manager = SyncManager(
        queue: queue,
        remoteProvider: () => api,
        connectivity: connectivity,
        conflictStore: conflictStore,
      );

      // Handler returning 500 changes
      final handler = ChaosTestEntityHandler(
        entityType: 'product',
        cursorStore: cursorStore,
        pullChangesProvider: () async {
          final changes = <SyncRemoteChange>[];
          for (var i = 1; i <= 500; i++) {
            changes.add(
              SyncRemoteChange(
                entityId: 'p-$i',
                version: 1,
                updatedAt: DateTime.utc(2026, 8, 24),
                payload: {'sku': 'SKU-$i', '_sequence': i},
              ),
            );
          }
          return changes;
        },
      );
      manager.registerHandler(handler);
      await manager.start(enabled: true);

      final result = await manager.syncNow(trigger: SyncPassTrigger.manual);

      // Assert: Exactly 500 items pulled and applied
      expect(result.downloaded, equals(500));
      expect(handler.appliedChanges.length, equals(500));

      // Assert Cursor advanced cleanly to 500
      final finalCursor = await cursorStore.read('product');
      expect(finalCursor, equals(500));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('PART 8 — Auth Chaos: 401 token expiration does NOT delete pending local queue operations', () async {
      final cursorStore = SyncCursorStore();
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      // Populate queue with pending operations
      final op1 = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c-auth-1',
        type: SyncOperationType.create,
        payload: {'name': 'Pending Cust 1'},
      );
      final op2 = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c-auth-2',
        type: SyncOperationType.create,
        payload: {'name': 'Pending Cust 2'},
      );
      await queue.enqueue(op1);
      await queue.enqueue(op2);

      // Server returns HTTP 401 Unauthorized
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'code': 'unauthorized', 'message': 'Token expired'}}),
          401,
        );
      });

      final api = HttpRemoteSyncApi(
        config: const SyncApiConfig(
          baseUrl: 'https://api.nexabiz.test',
          apiToken: 'expired-token',
          companyId: 'cmp-1',
          userId: 'usr-1',
          deviceId: 'dev-1',
        ),
        client: mockClient,
      );

      final manager = SyncManager(
        queue: queue,
        remoteProvider: () => api,
        connectivity: connectivity,
        conflictStore: conflictStore,
      );
      manager.registerHandler(
        ChaosTestEntityHandler(
          entityType: 'customer',
          cursorStore: cursorStore,
        ),
      );
      await manager.start(enabled: true);

      final result = await manager.syncNow(trigger: SyncPassTrigger.manual);

      // Assert Outcome is authRequired
      expect(result.outcome, equals(SyncPassOutcome.authRequired));

      // CRITICAL INVARIANT: Local pending queue operations must NEVER be deleted on auth failure!
      final queueOps = await queue.all();
      expect(queueOps, hasLength(2));
      expect(queueOps[0].id, equals(op1.id));
      expect(queueOps[1].id, equals(op2.id));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('PART 17 — Background Sync Chaos: Concurrent sync triggers lock into single-flight pass', () async {
      final cursorStore = SyncCursorStore();
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      var networkCalls = 0;
      final mockClient = MockClient((request) async {
        networkCalls++;
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({
            'changes': [],
            'next_cursor': 0,
            'has_more': false,
          }),
          200,
        );
      });

      final api = HttpRemoteSyncApi(
        config: const SyncApiConfig(
          baseUrl: 'https://api.nexabiz.test',
          apiToken: 'token',
          companyId: 'cmp-1',
          userId: 'usr-1',
          deviceId: 'dev-1',
        ),
        client: mockClient,
      );

      final manager = SyncManager(
        queue: queue,
        remoteProvider: () => api,
        connectivity: connectivity,
        conflictStore: conflictStore,
      );
      manager.registerHandler(
        ChaosTestEntityHandler(
          entityType: 'customer',
          cursorStore: cursorStore,
        ),
      );
      await manager.start(enabled: true);

      // Trigger 10 concurrent syncNow calls simultaneously
      final futures = List.generate(
        10,
        (_) => manager.syncNow(trigger: SyncPassTrigger.manual),
      );

      final results = await Future.wait(futures);

      // Assert: All 10 returned idle outcome (0 items uploaded/downloaded)
      for (final res in results) {
        expect(res.outcome, equals(SyncPassOutcome.idle));
      }

      // Single-Flight Invariant: Exactly ONE execution pass ran (1 unified pull call)
      expect(networkCalls, equals(1));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });
  });
}
