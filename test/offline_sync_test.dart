import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/modules/inventory/data/adapters/inventory_item_adapter.dart';
import 'package:stock_count/modules/inventory/data/inventory_hive.dart';
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
    tempDir = await Directory.systemTemp.createTemp('stock_count_sync_');
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

  test('offline save enqueues; restart keeps queue; online syncs', () async {
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => DateTime.utc(2026, 8, 12, 12),
    );
    manager!.registerHandler(
      InventoryItemSyncHandler(repository: inventoryRepo, remoteProvider: () => remote),
    );
    await manager!.start(enabled: true);

    await inventoryRepo.save(
      InventoryItem(
        itemCode: 'SKU-1',
        itemName: 'Widget',
        systemQuantity: 10,
        actualQuantity: 9,
        mainQuantity: 9,
        subQuantity: 0,
      ),
    );

    final pending = await queue.peekReady();
    expect(pending, isNotEmpty);
    expect(pending.first.status, SyncStatus.pending);

    // App restart: new SyncQueue on the same durable box.
    final queueAfterRestart = SyncQueue(box: syncBox);
    final surviving = await queueAfterRestart.all();
    expect(surviving, isNotEmpty);

    connectivity.debugSetStatus(ConnectivityStatus.online);
    final result = await manager!.syncNow(notify: false);
    expect(result.outcome, SyncPassOutcome.completed);
    expect(result.uploaded, greaterThan(0));

    final stored = await inventoryRepo.getByCode('SKU-1');
    expect(stored?.syncStatus, SyncStatus.synced);
    expect(stored?.differenceBaseUnits, lessThan(0));
  });

  test('failed sync then manual retry succeeds', () async {
    remote = InMemoryRemoteSyncApi(simulateOffline: true);
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => DateTime.utc(2026, 8, 12, 12),
    );
    manager!.registerHandler(
      InventoryItemSyncHandler(repository: inventoryRepo, remoteProvider: () => remote),
    );
    await connectivity.start();
    connectivity.debugSetStatus(ConnectivityStatus.online);
    await manager!.setEnabled(true);

    await inventoryRepo.save(
      InventoryItem(
        itemCode: 'SKU-2',
        itemName: 'Gadget',
        systemQuantity: 5,
        actualQuantity: 5,
        mainQuantity: 5,
        subQuantity: 0,
      ),
    );

    final failedPass = await manager!.syncNow(notify: false);
    expect(failedPass.failed, greaterThan(0));
    expect((await queue.all()).first.status, SyncStatus.failed);

    remote = InMemoryRemoteSyncApi();
    manager!.registerHandler(
      InventoryItemSyncHandler(repository: inventoryRepo, remoteProvider: () => remote),
    );
    await manager!.retryFailed();
    expect(
      (await queue.all()).where((o) => o.status == SyncStatus.failed),
      isEmpty,
    );
  });

  test('divergent remote quantity marks conflict', () async {
    manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      clock: () => DateTime.utc(2026, 8, 12, 12),
    );
    manager!.registerHandler(
      InventoryItemSyncHandler(repository: inventoryRepo, remoteProvider: () => remote),
    );
    connectivity.debugSetStatus(ConnectivityStatus.online);
    await manager!.setEnabled(true);

    const id = 'fixed-id-1';
    await inventoryRepo.save(
      InventoryItem(
        id: id,
        itemCode: 'SKU-3',
        itemName: 'Bolt',
        systemQuantity: 1,
        actualQuantity: 95,
        mainQuantity: 95,
        subQuantity: 0,
        version: 1,
      ),
    );

    remote.seed(
      InventoryRepositoryImpl.entityType,
      RemoteEntityMeta(
        entityId: id,
        version: 5,
        updatedAt: DateTime.utc(2026, 8, 12, 11),
        payload: {'id': id, 'itemCode': 'SKU-3', 'actualQuantity': 97},
      ),
    );

    await manager!.syncNow(notify: false);
    final stored = await inventoryRepo.getById(id);
    expect(stored?.syncStatus, SyncStatus.conflict);
  });

  test('InventoryHive box survives reopen with pending sync fields', () async {
    await inventoryRepo.save(
      InventoryItem(
        itemCode: 'SKU-4',
        itemName: 'Nut',
        systemQuantity: 2,
        actualQuantity: 2,
        mainQuantity: 2,
        subQuantity: 0,
      ),
    );
    await Hive.box<InventoryItem>(InventoryHive.boxName).close();

    final reopened = await InventoryHive.openBox();
    final item = reopened.get('SKU-4');
    expect(item, isNotNull);
    expect(item!.syncStatus, SyncStatus.pending);
    expect(item.id, isNotEmpty);
  });
}
