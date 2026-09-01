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
  late InventoryDocumentSyncHandler reversalSyncHandler;

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

    reversalSyncHandler = InventoryDocumentSyncHandler(
      entityType: 'inventory_reversal',
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

  group('ROOT FIX 31 — Offline Synchronization Conflict Integrity Tests', () {
    test('1. Older Remote Update (remoteVersion < localVersion) is ignored and local state is preserved', () async {
      final docId = generateUuidV4();

      // 1. Apply remote change v5
      final changeV5 = SyncRemoteChange(
        entityId: docId,
        version: 5,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-V5',
          'supplier': 'Supplier Original',
          'status': 'draft',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-01', 'itemName': 'Item 01', 'quantity': 100.0, 'unitCost': 10.0}
          ]
        },
      );
      await receiptSyncHandler.applyRemoteChange(changeV5);

      final docAfterV5 = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .getSingle();
      expect(docAfterV5.version, equals(5));
      expect(docAfterV5.supplier, equals('Supplier Original'));

      // 2. Deliver older remote update v3
      final changeV3 = SyncRemoteChange(
        entityId: docId,
        version: 3,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-V3',
          'supplier': 'Older Supplier',
          'status': 'draft',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-01', 'itemName': 'Item 01', 'quantity': 50.0, 'unitCost': 5.0}
          ]
        },
      );
      await receiptSyncHandler.applyRemoteChange(changeV3);

      // 3. Verify local state remains v5
      final docFinal = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .getSingle();
      expect(docFinal.version, equals(5));
      expect(docFinal.supplier, equals('Supplier Original'));
    });

    test('2. Newer Remote Update (remoteVersion > localVersion) on draft document applies cleanly', () async {
      final docId = generateUuidV4();

      // 1. Create v1 draft
      final changeV1 = SyncRemoteChange(
        entityId: docId,
        version: 1,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-V1',
          'supplier': 'Initial Supplier',
          'status': 'draft',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-02', 'itemName': 'Item 02', 'quantity': 20.0, 'unitCost': 15.0}
          ]
        },
      );
      await receiptSyncHandler.applyRemoteChange(changeV1);

      // 2. Deliver newer remote update v2
      final changeV2 = SyncRemoteChange(
        entityId: docId,
        version: 2,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-V1-UPDATED',
          'supplier': 'Updated Supplier',
          'status': 'draft',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-02', 'itemName': 'Item 02', 'quantity': 30.0, 'unitCost': 15.0}
          ]
        },
      );
      await receiptSyncHandler.applyRemoteChange(changeV2);

      // 3. Verify updated state
      final docV2 = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .getSingle();
      expect(docV2.version, equals(2));
      expect(docV2.supplier, equals('Updated Supplier'));
    });

    test('3. Concurrent Remote Updates resolve deterministically without corrupting local state', () async {
      final docId = generateUuidV4();

      // Setup initial v1
      final initialChange = SyncRemoteChange(
        entityId: docId,
        version: 1,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-CONC-0',
          'status': 'draft',
          'warehouseId': whId,
        },
      );
      await receiptSyncHandler.applyRemoteChange(initialChange);

      final changeA = SyncRemoteChange(
        entityId: docId,
        version: 2,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-CONC-A',
          'supplier': 'Supplier A',
          'status': 'draft',
          'warehouseId': whId,
        },
      );

      final changeB = SyncRemoteChange(
        entityId: docId,
        version: 2,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-CONC-B',
          'supplier': 'Supplier B',
          'status': 'draft',
          'warehouseId': whId,
        },
      );

      // Apply concurrently
      await Future.wait([
        receiptSyncHandler.applyRemoteChange(changeA),
        receiptSyncHandler.applyRemoteChange(changeB),
      ]);

      final docResult = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .getSingle();
      expect(docResult.version, equals(2));
      expect(docResult.supplier, anyOf(equals('Supplier A'), equals('Supplier B')));
    });

    test('4. Posted Document Conflict: Remote update attempting to edit/unpost/delete a posted document is detected & rejected', () async {
      final docId = generateUuidV4();

      // 1. Post a stock receipt locally (v1, posted, stock created)
      final postChange = SyncRemoteChange(
        entityId: docId,
        version: 1,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-POSTED-01',
          'supplier': 'Posted Supplier',
          'status': 'posted',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-POSTED', 'itemName': 'Item Posted', 'quantity': 100.0, 'unitCost': 25.0}
          ]
        },
      );
      await receiptSyncHandler.applyRemoteChange(postChange);

      expect(await getAvailableQty('ITEM-POSTED'), equals(100.0));

      final docBeforeConflict = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .getSingle();
      expect(docBeforeConflict.status, equals('posted'));

      // 2. Attempt remote change trying to unpost or soft-delete (v2)
      final conflictUnpostChange = SyncRemoteChange(
        entityId: docId,
        version: 2,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-POSTED-01',
          'supplier': 'Posted Supplier Modified',
          'status': 'draft', // Illegal attempt to unpost financial document
          'warehouseId': whId,
        },
      );

      expect(
        () async => await receiptSyncHandler.applyRemoteChange(conflictUnpostChange),
        throwsA(isA<StateError>()),
      );

      // 3. Verify posted document & inventory remain intact (not corrupted or silently overwritten)
      final docAfterConflict = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .getSingle();
      expect(docAfterConflict.status, equals('posted'));
      expect(docAfterConflict.version, equals(1));
      expect(await getAvailableQty('ITEM-POSTED'), equals(100.0));
    });

    test('5. Reversal Conflict: Duplicate remote reversal is processed idempotently without double unposting', () async {
      final docId = generateUuidV4();

      // 1. Post stock receipt (v1, posted)
      final postChange = SyncRemoteChange(
        entityId: docId,
        version: 1,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-REV-01',
          'status': 'posted',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-REV', 'itemName': 'Item Rev', 'quantity': 50.0, 'unitCost': 20.0}
          ]
        },
      );
      await receiptSyncHandler.applyRemoteChange(postChange);
      expect(await getAvailableQty('ITEM-REV'), equals(50.0));

      // 2. Deliver remote reversal event
      final reversalChange1 = SyncRemoteChange(
        entityId: generateUuidV4(),
        version: 1,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'documentId': docId,
          'documentType': 'stockReceipt',
          'reason': 'Customer requested cancellation',
        },
      );
      await reversalSyncHandler.applyRemoteChange(reversalChange1);

      // Verify stock restored/unposted to 0
      expect(await getAvailableQty('ITEM-REV'), equals(0.0));

      // 3. Deliver duplicate remote reversal event
      final reversalChange2 = SyncRemoteChange(
        entityId: generateUuidV4(),
        version: 2,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'documentId': docId,
          'documentType': 'stockReceipt',
          'reason': 'Customer requested cancellation duplicate',
        },
      );

      // Second reversal must complete idempotently without throwing error or double unposting
      await reversalSyncHandler.applyRemoteChange(reversalChange2);
      expect(await getAvailableQty('ITEM-REV'), equals(0.0));
    });

    test('6. Duplicate Event Delivery (same version) is ignored or handled idempotently', () async {
      final docId = generateUuidV4();

      final change = SyncRemoteChange(
        entityId: docId,
        version: 1,
        updatedAt: DateTime.now(),
        payload: {
          'companyId': tenantId,
          'receiptNumber': 'REC-DUP-01',
          'status': 'posted',
          'warehouseId': whId,
          'lines': [
            {'itemCode': 'ITEM-DUP', 'itemName': 'Item Dup', 'quantity': 40.0, 'unitCost': 10.0}
          ]
        },
      );

      // Apply first time
      await receiptSyncHandler.applyRemoteChange(change);
      expect(await getAvailableQty('ITEM-DUP'), equals(40.0));

      // Apply second time (duplicate event)
      await receiptSyncHandler.applyRemoteChange(change);
      expect(await getAvailableQty('ITEM-DUP'), equals(40.0));

      final count = await (invDb.select(invDb.stockReceipts)
            ..where((t) => t.uuid.equals(docId)))
          .get();
      expect(count.length, equals(1));
    });
  });
}
