import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/core/utils/id_parser.dart';
import 'package:stock_count/modules/inventory/data/adapters/inventory_item_adapter.dart';
import 'package:stock_count/modules/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:stock_count/modules/inventory/data/sync/inventory_sync_handlers.dart';
import 'package:stock_count/modules/inventory/domain/entities/inventory_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;
  late InMemoryRemoteSyncApi remote;
  late ConnectivityService connectivity;
  late StreamController<List<ConnectivityResult>> connectivityStream;
  late InventoryRepositoryImpl inventoryRepo;
  SyncManager? manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexa_phase3_fail_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InventoryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    remote = InMemoryRemoteSyncApi();
    connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
    connectivity = ConnectivityService(
      connectivityStream: connectivityStream.stream,
      initialResults: const [ConnectivityResult.none],
    );
    inventoryRepo = InventoryRepositoryImpl(syncQueue: queue);
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

  test('App Kill During Sync: stuck syncing ops are reclaimed to pending on restart', () async {
    // Manually place a operation into 'syncing' status simulating app crash during network call
    final op = SyncOperation.create(
      entityType: 'inventory_item',
      entityId: 'crash-sku-1',
      type: SyncOperationType.create,
      payload: {'itemCode': 'CRASH-1', 'actualQuantity': 10},
    ).copyWith(status: SyncStatus.syncing);

    await syncBox.put(op.id, op);

    // Initial state before recovery
    expect(syncBox.get(op.id)?.status, SyncStatus.syncing);

    // Simulate app restart by initializing fresh queue & calling reclaimInFlight
    final recoveredCount = await queue.reclaimInFlight(now: DateTime.utc(2026, 8, 22));
    expect(recoveredCount, equals(1));
    expect(syncBox.get(op.id)?.status, SyncStatus.pending);
    expect(syncBox.get(op.id)?.nextRetryAt, isNull);
  });

  test('Concurrent syncNow calls execute safely without duplicate triggers', () async {
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => DateTime.utc(2026, 8, 22),
    );
    manager!.registerHandler(
      InventoryItemSyncHandler(repository: inventoryRepo, remoteProvider: () => remote),
    );
    connectivity.debugSetStatus(ConnectivityStatus.online);
    await manager!.start(enabled: true);

    await inventoryRepo.save(
      InventoryItem(
        itemCode: 'CONCUR-1',
        itemName: 'Concurrent Item',
        systemQuantity: 5,
        actualQuantity: 5,
        mainQuantity: 5,
        subQuantity: 0,
      ),
    );

    // Fire 3 simultaneous syncNow calls
    final futures = Future.wait([
      manager!.syncNow(notify: false),
      manager!.syncNow(notify: false),
      manager!.syncNow(notify: false),
    ]);

    final results = await futures;
    // Exactly one pass should run and complete, others should yield idle/skipped
    final completedCount = results.where((r) => r.outcome == SyncPassOutcome.completed).length;
    expect(completedCount, equals(1));
  });

  test('IdParser resilience under malformed and boundary inputs', () {
    expect(IdParser.extractNumericId(123), equals(123));
    expect(IdParser.extractNumericId('456'), equals(456));
    expect(IdParser.extractNumericId('/api/v1/invoices/789'), equals(789));
    expect(IdParser.extractNumericId('https://nexabiz.app/v1/orders/101112?ref=push#tag'), equals(101112));
    expect(IdParser.extractNumericId('/api/v1/orders/'), isNull);
    expect(IdParser.extractNumericId('invalid-string'), isNull);
    expect(IdParser.extractNumericId(null), isNull);
  });
}
