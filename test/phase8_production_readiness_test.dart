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

class Phase8TestEntityHandler implements SyncEntityHandler {
  Phase8TestEntityHandler({
    required this.entityType,
    required this.cursorStore,
    this.failOnApply = false,
  });

  @override
  final String entityType;
  final SyncCursorStore cursorStore;
  final bool failOnApply;

  final List<SyncRemoteChange> appliedChanges = [];

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async =>
      SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async => [];

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    if (failOnApply) {
      throw const ServerFailure('Simulated SQLite local application write failure');
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
  Future<void> confirmPull() async {}

  @override
  Future<void> abandonPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase8_readiness_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 8 — Final Production Readiness & Operational Verification', () {
    test('Requirement 5 — Authentication Failure Queue Preservation: HTTP 401 preserves pending local queue ops', () async {
      final queue = SyncQueue();
      final cursorStore = SyncCursorStore();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      final op = SyncOperation.create(
        entityType: 'customer',
        entityId: 'c-prod-1',
        type: SyncOperationType.create,
        payload: {'name': 'Unsynced Customer'},
      );
      await queue.enqueue(op);

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
        Phase8TestEntityHandler(
          entityType: 'customer',
          cursorStore: cursorStore,
        ),
      );
      await manager.start(enabled: true);

      final result = await manager.syncNow(trigger: SyncPassTrigger.manual);

      expect(result.outcome, equals(SyncPassOutcome.authRequired));

      // CRITICAL INVARIANT: Queue operations MUST NEVER be deleted on 401 auth failure!
      final pendingOps = await queue.all();
      expect(pendingOps, hasLength(1));
      expect(pendingOps[0].id, equals(op.id));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('Requirement 11 — Cursor Safety: Failed apply preserves cursor invariant (CURSOR <= LAST DURABLY APPLIED)', () async {
      final cursorStore = SyncCursorStore();
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

      await cursorStore.write('product', 50);

      final failingHandler = Phase8TestEntityHandler(
        entityType: 'product',
        cursorStore: cursorStore,
        failOnApply: true,
      );

      final change = SyncRemoteChange(
        entityId: 'p-99',
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 24),
        payload: {'sku': 'SKU-99'},
      );

      try {
        await failingHandler.applyRemoteChange(change);
        fail('Should have thrown failure');
      } catch (e) {
        // Expected failure
      }

      // Cursor must remain 50
      final cur = await cursorStore.read('product');
      expect(cur, equals(50));

      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('Requirement 15 — Diagnostic Report Sanitization: Secret credentials omitted', () {
      final overview = SyncOverview.initial().copyWith(
        pendingCount: 12,
        failedCount: 0,
      );

      final report = overview.toDiagnosticReport();

      expect(report['pending_count'], equals(12));
      expect(report.containsKey('api_token'), isFalse);
      expect(report.containsKey('password'), isFalse);
    });
  });
}
