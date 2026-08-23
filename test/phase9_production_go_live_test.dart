import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/http_remote_sync_api.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/sync/conflict_resolver.dart';
import 'package:stock_count/core/sync/sync_conflict_store.dart';
import 'package:stock_count/core/sync/sync_cursor_store.dart';
import 'package:stock_count/core/sync/sync_entity_handler.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_request_context.dart';
import 'package:stock_count/core/sync/sync_status.dart';

class Phase9TestEntityHandler implements SyncEntityHandler {
  Phase9TestEntityHandler({
    required this.entityType,
    required this.cursorStore,
  });

  @override
  final String entityType;
  final SyncCursorStore cursorStore;
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
    tempDir = await Directory.systemTemp.createTemp('phase9_golive_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 9 — Production Go-Live Verification Suite', () {
    test('Requirement 1 — Authentication Failure Queue Preservation: HTTP 401 token expiration does NOT delete pending local queue operations', () async {
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
        entityId: 'c-golive-1',
        type: SyncOperationType.create,
        payload: {'name': 'GoLive Customer'},
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
        Phase9TestEntityHandler(
          entityType: 'customer',
          cursorStore: cursorStore,
        ),
      );
      await manager.start(enabled: true);

      final result = await manager.syncNow(trigger: SyncPassTrigger.manual);

      expect(result.outcome, equals(SyncPassOutcome.authRequired));

      final pendingOps = await queue.all();
      expect(pendingOps, hasLength(1));
      expect(pendingOps[0].id, equals(op.id));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('Requirement 2 — Cursor Safety Invariant: Local cursor read is accurate and safe', () async {
      final cursorStore = SyncCursorStore();
      await cursorStore.write('sale', 100);

      final cur = await cursorStore.read('sale');
      expect(cur, equals(100));
    });

    test('Requirement 3 — Diagnostic Sanitization: Secret credentials omitted in diagnostic snapshot', () {
      final overview = SyncOverview.initial().copyWith(
        pendingCount: 5,
        failedCount: 0,
      );

      final report = overview.toDiagnosticReport();

      expect(report['pending_count'], equals(5));
      expect(report.containsKey('api_token'), isFalse);
      expect(report.containsKey('password'), isFalse);
      expect(report.containsKey('authorization'), isFalse);
    });
  });
}
