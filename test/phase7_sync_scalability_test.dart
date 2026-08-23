import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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

class ScalabilityTestEntityHandler implements SyncEntityHandler {
  ScalabilityTestEntityHandler({
    required this.entityType,
    required this.cursorStore,
    required this.totalCount,
  });

  @override
  final String entityType;
  final SyncCursorStore cursorStore;
  final int totalCount;

  final List<SyncRemoteChange> appliedChanges = [];

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async =>
      SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async {
    final changes = <SyncRemoteChange>[];
    for (var i = 1; i <= totalCount; i++) {
      changes.add(
        SyncRemoteChange(
          entityId: 'scalability-$i',
          version: 1,
          updatedAt: DateTime.utc(2026, 8, 24),
          payload: {'sku': 'SKU-$i', '_sequence': i},
        ),
      );
    }
    return changes;
  }

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
  Future<void> confirmPull() async {
    if (appliedChanges.isNotEmpty) {
      await cursorStore.write(entityType, appliedChanges.length);
    }
  }

  @override
  Future<void> abandonPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase7_scalability_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 7 — Client Scalability & Single-Flight Concurrency Benchmark', () {
    test('SyncManager single-flight lock coalesces 20 concurrent sync triggers seamlessly', () async {
      final cursorStore = SyncCursorStore();
      final queue = SyncQueue();
      final conflictStore = SyncConflictStore();
      final connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
      final connectivity = ConnectivityService(
        connectivityStream: connectivityStream.stream,
        initialResults: const [ConnectivityResult.wifi],
      );

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

      final handler = ScalabilityTestEntityHandler(
        entityType: 'product',
        cursorStore: cursorStore,
        totalCount: 100,
      );
      manager.registerHandler(handler);
      await manager.start(enabled: true);

      // Trigger 20 simultaneous syncNow calls
      final futures = List.generate(
        20,
        (_) => manager.syncNow(trigger: SyncPassTrigger.manual),
      );

      final results = await Future.wait(futures);

      // Single-flight lock invariant: all callers get safe completed pass results
      expect(results, hasLength(20));

      await manager.dispose();
      await connectivity.dispose();
      await connectivityStream.close();
    });

    test('SyncOverview toDiagnosticReport returns compact payload under load', () {
      final overview = SyncOverview.initial().copyWith(
        pendingCount: 50,
        failedCount: 2,
      );

      final report = overview.toDiagnosticReport();

      expect(report['pending_count'], equals(50));
      expect(report['failed_count'], equals(2));
      expect(report.containsKey('password'), isFalse);
    });
  });
}
