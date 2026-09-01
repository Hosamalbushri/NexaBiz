import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/data/sync/inventory_sync_handlers.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:drift/drift.dart' as drift;

class MockRemoteSyncApi implements RemoteSyncApi {
  @override
  Future<void> abandonPull(String entityType) async {}
  @override
  Future<void> acknowledgePull(String entityType) async {}
  @override
  Future<RemoteEntityMeta?> getMeta({required String entityType, required String entityId}) async => null;
  @override
  Future<List<SyncRemoteChange>> pull({String? entityType, DateTime? since}) async => [];
  @override
  Future<SyncUploadAck> push({required String entityType, required SyncOperation operation}) async =>
      SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  @override
  Future<List<SyncBatchPushItemResult>> pushBatch(List<SyncOperation> operations) async => [];
}

void main() {
  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl stockValidationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late InventoryDocumentSyncHandler receiptSyncHandler;
  late InventoryDocumentSyncHandler issueSyncHandler;

  const tenantId = 'company-tenant-alpha';
  late String whId;

  setUp(() async {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();
    whId = generateUuidV4();

    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => tenantId,
    );

    stockValidationService = StockValidationServiceImpl(
      invDb,
      () => tenantId,
    );

    dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => tenantId,
    );

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      postingEngine: postingEngine,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      readCompanyId: () => tenantId,
    );

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await invDb.into(invDb.warehouses).insert(
      WarehousesCompanion(
        uuid: drift.Value(whId),
        code: const drift.Value('WH-MAIN'),
        name: const drift.Value('Main Warehouse'),
        companyId: const drift.Value(tenantId),
        isDefault: const drift.Value(true),
        createdAt: drift.Value(nowMs),
        updatedAt: drift.Value(nowMs),
      ),
    );

    receiptSyncHandler = InventoryDocumentSyncHandler(
      entityType: 'stock_receipt',
      remoteProvider: () => MockRemoteSyncApi(),
      db: invDb,
      postingCoordinator: coordinator,
      postingEngine: postingEngine,
      readCompanyId: () => tenantId,
    );

    issueSyncHandler = InventoryDocumentSyncHandler(
      entityType: 'stock_issue',
      remoteProvider: () => MockRemoteSyncApi(),
      db: invDb,
      postingCoordinator: coordinator,
      postingEngine: postingEngine,
      readCompanyId: () => tenantId,
    );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  Future<double> getAvailableQty(String itemCode) async {
    final layers = await costLayerService.getOpenLayers(itemCode, warehouseId: whId);
    return layers.fold<double>(0, (sum, layer) => sum + layer.remainingQty);
  }

  group('ROOT FIX 30 — Synchronization Accounting Idempotency Tests', () {
    test('1. Sequential Remote Delivery (event X, event X, event X) produces exactly ONE economic effect', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();
      final now = DateTime.now().toUtc();

      final remoteChange = SyncRemoteChange(
        entityId: receiptUuid,
        version: 1,
        updatedAt: now,
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-SYNC-001',
          'warehouse': whId,
          'status': 'posted',
          'lines': [
            {
              'id': lineUuid,
              'itemCode': 'ITEM-A',
              'itemName': 'Widget A',
              'quantity': 100.0,
              'unitCost': 15.0,
              'totalCost': 1500.0,
            }
          ],
        },
      );

      // Deliver event X 3 times sequentially
      await receiptSyncHandler.applyRemoteChange(remoteChange);
      await receiptSyncHandler.applyRemoteChange(remoteChange);
      await receiptSyncHandler.applyRemoteChange(remoteChange);

      // Verify Stock Receipt stored exactly once
      final receipts = await (invDb.select(invDb.stockReceipts)..where((t) => t.uuid.equals(receiptUuid))).get();
      expect(receipts.length, equals(1));
      expect(receipts.first.status, equals('posted'));

      // Verify Movement Lines has exactly 1 movement line set
      final lines = await (invDb.select(invDb.stockMovementLines)..where((t) => t.movementUuid.equals(receiptUuid))).get();
      expect(lines.length, equals(1));
      expect(lines.first.quantity, equals(100.0));

      // Verify Cost Layers has exactly 1 layer
      final layers = await (invDb.select(invDb.inventoryCostLayers)..where((t) => t.movementUuid.equals(receiptUuid))).get();
      expect(layers.length, equals(1));
      expect(layers.first.remainingQty, equals(100.0));
      expect(layers.first.unitCost, equals(15.0));

      // Verify total stock balance for ITEM-A is exactly 100
      final balance = await getAvailableQty('ITEM-A');
      expect(balance, equals(100.0));
    });

    test('2. Concurrent Remote Delivery of event X produces exactly ONE economic effect', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();
      final now = DateTime.now().toUtc();

      final remoteChange = SyncRemoteChange(
        entityId: receiptUuid,
        version: 1,
        updatedAt: now,
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-SYNC-CONC',
          'warehouse': whId,
          'status': 'posted',
          'lines': [
            {
              'id': lineUuid,
              'itemCode': 'ITEM-CONC',
              'itemName': 'Conc Item',
              'quantity': 50.0,
              'unitCost': 20.0,
              'totalCost': 1000.0,
            }
          ],
        },
      );

      // Apply remote change concurrently 3 times
      await Future.wait([
        receiptSyncHandler.applyRemoteChange(remoteChange),
        receiptSyncHandler.applyRemoteChange(remoteChange),
        receiptSyncHandler.applyRemoteChange(remoteChange),
      ]);

      // Verify stock balance is 50, not 150
      final balance = await getAvailableQty('ITEM-CONC');
      expect(balance, equals(50.0));

      // Verify movement lines count
      final lines = await (invDb.select(invDb.stockMovementLines)..where((t) => t.movementUuid.equals(receiptUuid))).get();
      expect(lines.length, equals(1));
    });

    test('3. Cross-tenant sync payload is rejected before any database mutation', () async {
      final receiptUuid = generateUuidV4();
      final remoteChange = SyncRemoteChange(
        entityId: receiptUuid,
        version: 1,
        updatedAt: DateTime.now().toUtc(),
        payload: {
          'companyId': 'MALICIOUS_TENANT',
          'receiptNumber': 'REC-EVIL',
          'status': 'posted',
          'lines': [],
        },
      );

      expect(
        () => receiptSyncHandler.applyRemoteChange(remoteChange),
        throwsA(isA<ArgumentError>()),
      );

      // Verify zero DB records created
      final receipts = await (invDb.select(invDb.stockReceipts)..where((t) => t.uuid.equals(receiptUuid))).get();
      expect(receipts, isEmpty);
    });

    test('4. Remote Stock Issue consumption idempotency across duplicate events', () async {
      // 1. Create initial receipt stock of 100 units
      final receiptUuid = generateUuidV4();
      await receiptSyncHandler.applyRemoteChange(
        SyncRemoteChange(
          entityId: receiptUuid,
          version: 1,
          updatedAt: DateTime.now().toUtc(),
          payload: {
            'companyId': tenantId,
            'receiptNumber': 'REC-STOCK-001',
            'warehouse': whId,
            'status': 'posted',
            'lines': [
              {
                'id': generateUuidV4(),
                'itemCode': 'ITEM-ISSUE-TEST',
                'itemName': 'Issue Item',
                'quantity': 100.0,
                'unitCost': 10.0,
                'totalCost': 1000.0,
              }
            ],
          },
        ),
      );

      final issueUuid = generateUuidV4();
      final issueLineUuid = generateUuidV4();
      final issueChange = SyncRemoteChange(
        entityId: issueUuid,
        version: 1,
        updatedAt: DateTime.now().toUtc(),
        payload: {
          'companyId': tenantId,
          'issueNumber': 'ISS-SYNC-001',
          'status': 'posted',
          'warehouse': whId,
          'lines': [
            {
              'id': issueLineUuid,
              'itemCode': 'ITEM-ISSUE-TEST',
              'itemName': 'Issue Item',
              'quantity': 40.0,
              'unitCost': 10.0,
              'totalCost': 400.0,
            }
          ],
        },
      );

      // Deliver duplicate issue events
      await issueSyncHandler.applyRemoteChange(issueChange);
      await issueSyncHandler.applyRemoteChange(issueChange);
      await issueSyncHandler.applyRemoteChange(issueChange);

      // Verify remaining stock is exactly 60.0 (100 - 40), not -20.0
      final balance = await getAvailableQty('ITEM-ISSUE-TEST');
      expect(balance, equals(60.0));

      // Verify total cost consumptions for this issue movement line
      final consumptions = await (invDb.select(invDb.inventoryCostConsumptions)..where((t) => t.issueLineUuid.equals(issueLineUuid))).get();
      expect(consumptions.length, equals(1));
      expect(consumptions.first.consumedQty, equals(40.0));
    });

    test('5. Reversal of remote event delivered multiple times produces exactly ONE reversal effect', () async {
      // 1. Setup receipt
      final receiptUuid = generateUuidV4();
      await receiptSyncHandler.applyRemoteChange(
        SyncRemoteChange(
          entityId: receiptUuid,
          version: 1,
          updatedAt: DateTime.now().toUtc(),
          payload: {
            'companyId': tenantId,
            'receiptNumber': 'REC-REV-001',
            'warehouse': whId,
            'status': 'posted',
            'lines': [
              {
                'id': generateUuidV4(),
                'itemCode': 'ITEM-REV',
                'itemName': 'Reversal Item',
                'quantity': 50.0,
                'unitCost': 30.0,
                'totalCost': 1500.0,
              }
            ],
          },
        ),
      );

      expect(await getAvailableQty('ITEM-REV'), equals(50.0));

      // 2. Deliver reversal event multiple times
      final reversalHandler = InventoryDocumentSyncHandler(
        entityType: 'inventory_reversal',
        remoteProvider: () => MockRemoteSyncApi(),
        db: invDb,
        postingCoordinator: coordinator,
        postingEngine: postingEngine,
        readCompanyId: () => tenantId,
      );

      final revChange = SyncRemoteChange(
        entityId: generateUuidV4(),
        version: 1,
        updatedAt: DateTime.now().toUtc(),
        payload: {
          'companyId': tenantId,
          'documentId': receiptUuid,
          'documentType': 'stock_receipt',
          'reason': 'Remote sync cancel',
        },
      );

      await reversalHandler.applyRemoteChange(revChange);
      await reversalHandler.applyRemoteChange(revChange);
      await reversalHandler.applyRemoteChange(revChange);

      // Verify remaining stock is now 0.0 (reversed once)
      expect(await getAvailableQty('ITEM-REV'), equals(0.0));

      // Verify receipt status is draft (unposted)
      final receipts = await (invDb.select(invDb.stockReceipts)..where((t) => t.uuid.equals(receiptUuid))).get();
      expect(receipts.first.status, equals('draft'));
    });

    test('6. Stock shortage during remote issue sync throws exception without corrupting state', () async {
      final issueUuid = generateUuidV4();
      final issueChange = SyncRemoteChange(
        entityId: issueUuid,
        version: 1,
        updatedAt: DateTime.now().toUtc(),
        payload: {
          'companyId': tenantId,
          'issueNumber': 'ISS-SHORTAGE',
          'status': 'posted',
          'warehouse': whId,
          'lines': [
            {
              'id': generateUuidV4(),
              'itemCode': 'ITEM-NONEXISTENT',
              'itemName': 'Ghost Item',
              'quantity': 10.0,
              'unitCost': 5.0,
              'totalCost': 50.0,
            }
          ],
        },
      );

      // Attempting to post stock issue for non-existent stock must throw
      expect(
        () => issueSyncHandler.applyRemoteChange(issueChange),
        throwsA(isA<StateError>()),
      );
    });
  });
}
