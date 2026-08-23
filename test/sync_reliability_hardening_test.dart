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
import 'package:stock_count/core/sync/conflict_resolver.dart';
import 'package:stock_count/core/sync/sync_conflict_record.dart';
import 'package:stock_count/core/sync/sync_conflict_store.dart';
import 'package:stock_count/core/sync/sync_entity_handler.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_request_context.dart';
import 'package:stock_count/core/sync/sync_status.dart';

class TestSyncEntityHandler implements SyncEntityHandler {
  TestSyncEntityHandler({required this.entityType});

  @override
  final String entityType;

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async =>
      SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);

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
  Future<void> markLocalConflict({
    required String entityId,
    String? message,
  }) async {}

  @override
  Future<void> confirmPull() async {}

  @override
  Future<void> abandonPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async =>
      null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase4_hardening_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 4 — Error Taxonomy & Reliability Hardening', () {
    test('HttpRemoteSyncApi parses HTTP 429 Retry-After into RateLimitFailure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'message': 'Too Many Requests'}}),
          429,
          headers: {'retry-after': '60'},
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

      final op = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c1',
        type: SyncOperationType.create,
        payload: {'name': 'Test'},
      );

      expect(
        () => api.push(entityType: 'customer', operation: op),
        throwsA(
          isA<RateLimitFailure>().having(
            (e) => e.retryAfterSeconds,
            'retryAfterSeconds',
            60,
          ),
        ),
      );
    });

    test('HttpRemoteSyncApi parses pushBatch 409 conflict metadata correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'operation_id': 'op-batch-1',
                'status': 'conflict',
                'conflict': {
                  'entity_type': 'customer',
                  'entity_id': 'c-100',
                  'server_version': 5,
                  'client_base_version': 2,
                  'server_record': {'name': 'Server Customer'},
                },
                'error': {'message': 'Version conflict'},
              }
            ]
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

      final op = SyncOperation(
        id: 'op-batch-1',
        entityType: 'customer',
        entityId: 'c-100',
        type: SyncOperationType.update,
        baseVersion: 2,
        payload: {'name': 'Client Customer'},
        status: SyncStatus.pending,
        createdAt: DateTime.utc(2026, 8, 24),
        updatedAt: DateTime.utc(2026, 8, 24),
      );

      final results = await api.pushBatch([op]);
      expect(results, hasLength(1));
      expect(results.first.isConflict, isTrue);

      final failure = results.first.failure as SyncConflictFailure;
      expect(failure.serverVersion, equals(5));
      expect(failure.clientBaseVersion, equals(2));
      expect(failure.serverRecord?['name'], equals('Server Customer'));
    });

    test('Non-retryable HTTP 422 ValidationFailure marks operation as SyncStatus.rejected', () async {
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'operation_id': 'op-val-1',
                'status': 'error',
                'error': {
                  'code': 'validation_error',
                  'message': 'Invalid tax number format',
                },
              }
            ]
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
        clock: () => DateTime.utc(2026, 8, 24, 12),
      );
      manager.registerHandler(TestSyncEntityHandler(entityType: 'customer'));
      await manager.start(enabled: true);

      final op = SyncOperation(
        id: 'op-val-1',
        entityType: 'customer',
        entityId: 'cust-val',
        type: SyncOperationType.create,
        payload: {'name': 'Bad Tax Customer'},
        status: SyncStatus.pending,
        createdAt: DateTime.utc(2026, 8, 24),
        updatedAt: DateTime.utc(2026, 8, 24),
      );
      await queue.enqueue(op);

      final result = await manager.syncNow(trigger: SyncPassTrigger.manual);
      expect(result.failed, equals(1));

      final ops = await queue.all();
      expect(ops, hasLength(1));
      expect(ops.first.status, equals(SyncStatus.rejected));
      expect(ops.first.nextRetryAt, isNull); // Non-retryable: nextRetryAt cleared

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('Derived sync phase evaluation handles all operational health states', () {
      expect(
        deriveSyncPhase(
          isOnline: false,
          isSyncing: false,
          pendingCount: 2,
          failedCount: 0,
          conflictCount: 0,
        ),
        equals(SyncPhase.offline),
      );

      expect(
        deriveSyncPhase(
          isOnline: true,
          isSyncing: true,
          pendingCount: 2,
          failedCount: 0,
          conflictCount: 0,
        ),
        equals(SyncPhase.syncing),
      );

      expect(
        deriveSyncPhase(
          isOnline: true,
          isSyncing: false,
          pendingCount: 0,
          failedCount: 0,
          conflictCount: 1,
        ),
        equals(SyncPhase.conflict),
      );

      expect(
        deriveSyncPhase(
          isOnline: true,
          isSyncing: false,
          pendingCount: 1,
          failedCount: 1,
          conflictCount: 0,
        ),
        equals(SyncPhase.failed),
      );

      expect(
        deriveSyncPhase(
          isOnline: true,
          isSyncing: false,
          pendingCount: 0,
          failedCount: 0,
          conflictCount: 0,
        ),
        equals(SyncPhase.idleSynced),
      );
    });
  });
}
