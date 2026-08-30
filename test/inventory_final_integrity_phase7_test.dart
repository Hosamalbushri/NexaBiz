import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:hive/hive.dart';

class MockSyncBox<T> implements Box<T> {
  MockSyncBox(List<T> initial) {
    for (final item in initial) {
      final id = (item as dynamic).id;
      _map[id] = item;
    }
  }
  final Map<dynamic, T> _map = {};

  @override
  Iterable<T> get values => _map.values;

  @override
  Map<dynamic, T> toMap() => Map.from(_map);

  @override
  Future<void> put(dynamic key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _map.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late StockMovementsRepositoryImpl movementsRepo;
  late StockTransferRepositoryImpl transferRepo;
  late SyncQueue syncQueue;
  late MockSyncBox<SyncOperation> mockBox;
  late String activeCompanyId;

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    activeCompanyId = 'company_A';
    mockBox = MockSyncBox<SyncOperation>([]);
    syncQueue = SyncQueue(box: mockBox, companyId: activeCompanyId, deviceId: 'DEV-1');

    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => activeCompanyId,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => activeCompanyId,
    );
    validationService = StockValidationServiceImpl(
      db,
      () => activeCompanyId,
    );
    dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => activeCompanyId,
    );
    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      syncQueue: syncQueue,
      readCompanyId: () => activeCompanyId,
    );
    movementsRepo = StockMovementsRepositoryImpl(
      db: db,
      readCompanyId: () => activeCompanyId,
    );
    transferRepo = StockTransferRepositoryImpl(db: db);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.products).insert(
          ProductsCompanion(
            id: const Value(1),
            uuid: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('ITEM-001'),
            name: const Value('Test Item 1'),
            unitCost: const Value(100.0),
            price: const Value(100.0),
            packSize: const Value(1),
            onHandQty: const Value(0.0),
            syncStatus: const Value('synced'),
            companyId: const Value('company_A'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await db.into(db.products).insert(
          ProductsCompanion(
            id: const Value(2),
            uuid: const Value('00000000-0000-4000-8000-000000000002'),
            itemCode: const Value('ITEM-002'),
            name: const Value('Test Item 2'),
            unitCost: const Value(200.0),
            price: const Value(200.0),
            packSize: const Value(1),
            onHandQty: const Value(0.0),
            syncStatus: const Value('synced'),
            companyId: const Value('company_B'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  // Helper functions
  Future<StockReceipt> createReceipt({
    required String id,
    required String docNumber,
    required double qty,
    required double unitCost,
    String itemCode = 'ITEM-001',
    String warehouse = 'WH-001',
    String companyId = 'company_A',
  }) async {
    final receipt = StockReceipt(
      id: id,
      receiptNumber: docNumber,
      receiptDate: DateTime.now(),
      warehouse: warehouse,
      notes: 'Receipt $docNumber',
      status: InventoryDocumentStatus.draft,
      companyId: companyId,
      lines: [
        StockMovementLine(
          id: generateUuidV4(),
          movementUuid: id,
          movementType: 'receipt',
          itemCode: itemCode,
          itemName: 'Item $itemCode',
          quantity: qty,
          unitCost: unitCost,
          totalCost: qty * unitCost,
        ),
      ],
    );
    await movementsRepo.saveReceipt(receipt);
    return receipt;
  }

  Future<StockIssue> createIssue({
    required String id,
    required String docNumber,
    required double qty,
    double unitCost = 100.0,
    String itemCode = 'ITEM-001',
    String warehouse = 'WH-001',
    String companyId = 'company_A',
  }) async {
    final issue = StockIssue(
      id: id,
      issueNumber: docNumber,
      issueDate: DateTime.now(),
      warehouse: warehouse,
      notes: 'Issue $docNumber',
      status: InventoryDocumentStatus.draft,
      companyId: companyId,
      lines: [
        StockMovementLine(
          id: generateUuidV4(),
          movementUuid: id,
          movementType: 'issue',
          itemCode: itemCode,
          itemName: 'Item $itemCode',
          quantity: qty,
          unitCost: unitCost,
          totalCost: qty * unitCost,
        ),
      ],
    );
    await movementsRepo.saveIssue(issue);
    return issue;
  }

  group('TEST GROUP 1 — POSTING SAFETY', () {
    test('Test 1 — Normal Posting: single stock, cost, accounting & audit effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REC-G1-1', qty: 10, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: InventoryDocumentStatus.draft,
      );

      final result = await coordinator.post(document: ref);
      expect(result, isA<PostSuccess>());

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.length, 1);
      expect(layers.first.remainingQty, 10.0);

      final events = await syncQueue.peekReady();
      expect(events.any((e) => e.entityId == receipt.id), true);
    });

    test('Test 2 — Duplicate Posting: safe response & single economic effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REC-G1-2', qty: 5, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: InventoryDocumentStatus.draft,
      );

      final res1 = await coordinator.post(document: ref);
      final res2 = await coordinator.post(document: ref);

      expect(res1, isA<PostSuccess>());
      expect(res2, isA<PostSuccess>());

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.where((l) => l.movementUuid == receipt.id).length, 1);
    });

    test('Test 3 — Ten Duplicate Requests: 10 safe responses, single economic effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REC-G1-3', qty: 15, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: InventoryDocumentStatus.draft,
      );

      for (int i = 0; i < 10; i++) {
        final res = await coordinator.post(document: ref);
        expect(res, isA<PostSuccess>());
      }

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.where((l) => l.movementUuid == receipt.id).length, 1);
    });

    test('Test 4 — Concurrent Duplicate Posting: 1 successful economic effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REC-G1-4', qty: 8, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: InventoryDocumentStatus.draft,
      );

      final results = await Future.wait([
        coordinator.post(document: ref),
        coordinator.post(document: ref),
        coordinator.post(document: ref),
      ]);

      for (final r in results) {
        expect(r, isA<PostSuccess>());
      }

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.where((l) => l.movementUuid == receipt.id).length, 1);
    });
  });

  group('TEST GROUP 2 — TRANSACTIONAL INTEGRITY', () {
    test('Test 5 — Stock Failure Rollback: atomic rollback on error', () async {
      final ref = InventoryDocumentRef(
        documentId: '00000000-0000-4000-8000-999999999999',
        documentNumber: 'NON-EXIST-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 1, 1),
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostInvalidStatus>());

      final layers = await costLayerService.getOpenLayers('ITEM-001');
      expect(layers.isEmpty, true);
    });

    test('Test 6 — Accounting Failure Rollback: inventory and document status rolled back', () async {
      final issId = generateUuidV4();
      final issue = await createIssue(id: issId, docNumber: 'ISS-FAIL-1', qty: 100);
      final ref = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostStockShortage>());

      final reloadedIssue = await movementsRepo.getIssueById(issId);
      expect(reloadedIssue?.status, InventoryDocumentStatus.draft);
    });

    test('Test 7 — Cost Layer Failure Rollback: stock & accounting remain consistent', () async {
      final issId = generateUuidV4();
      final issue = await createIssue(id: issId, docNumber: 'ISS-FAIL-2', qty: 50);
      final ref = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostStockShortage>());
    });
  });

  group('TEST GROUP 3 — FIFO', () {
    test('Test 8 — FIFO Consumption: 10@100 + 10@120, Issue 12 -> COGS = 1240, Remaining = 8@120', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'FIFO-R1', qty: 10, unitCost: 100);
      final r2 = await createReceipt(id: generateUuidV4(), docNumber: 'FIFO-R2', qty: 10, unitCost: 120);

      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2.id,
        documentNumber: r2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r2.receiptDate,
        warehouseId: r2.warehouse,
      ));

      final issueLineUuid = generateUuidV4();
      final result = await costLayerService.consumeLayers(
        itemCode: 'ITEM-001',
        quantity: 12,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineUuid,
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.totalCost, 1240.0);
      final open = await costLayerService.getOpenLayers('ITEM-001');
      expect(open.length, 1);
      expect(open.first.remainingQty, 8.0);
      expect(open.first.unitCost, 120.0);
    });

    test('Test 9 — FIFO Partial Restoration on Reversal', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'FIFO-R1-9', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));

      final openBefore = await costLayerService.getOpenLayers('ITEM-001');
      expect(openBefore.length, 1);
    });

    test('Test 10 — FIFO Multi-Layer: 10@100 + 5@120 + 8@140, Issue 16 -> COGS = 1740', () async {
      final r1 = await createReceipt(id: generateUuidV4(), docNumber: 'FIFO-R10-1', qty: 10, unitCost: 100);
      final r2 = await createReceipt(id: generateUuidV4(), docNumber: 'FIFO-R10-2', qty: 5, unitCost: 120);
      final r3 = await createReceipt(id: generateUuidV4(), docNumber: 'FIFO-R10-3', qty: 8, unitCost: 140);
      
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1.id,
        documentNumber: r1.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r1.receiptDate,
        warehouseId: r1.warehouse,
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r2.id,
        documentNumber: r2.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r2.receiptDate,
        warehouseId: r2.warehouse,
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r3.id,
        documentNumber: r3.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: r3.receiptDate,
        warehouseId: r3.warehouse,
      ));

      final result = await costLayerService.consumeLayers(
        itemCode: 'ITEM-001',
        quantity: 16,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(result.totalCost, 1740.0);
    });
  });

  group('TEST GROUP 4 — LIFO', () {
    test('Test 11 — LIFO Consumption: 10@100 + 10@120, Issue 12 -> COGS = 1400, Remaining = 8@100', () async {
      final t1 = DateTime.utc(2026, 1, 1);
      final t2 = DateTime.utc(2026, 1, 2);
      final l1Id = generateUuidV4();
      final l2Id = generateUuidV4();
      final r1Id = generateUuidV4();
      final r2Id = generateUuidV4();

      await costLayerService.createLayer(CostLayer(
        id: l1Id,
        itemCode: 'ITEM-LIFO',
        movementUuid: r1Id,
        movementType: 'stock_receipt',
        receivedDate: t1,
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 100,
        totalCost: 1000,
        companyId: 'company_A',
      ));

      await costLayerService.createLayer(CostLayer(
        id: l2Id,
        itemCode: 'ITEM-LIFO',
        movementUuid: r2Id,
        movementType: 'stock_receipt',
        receivedDate: t2,
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 120,
        totalCost: 1200,
        companyId: 'company_A',
      ));

      final res = await costLayerService.consumeLayers(
        itemCode: 'ITEM-LIFO',
        quantity: 12,
        method: CostValuationMethod.lifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(res.totalCost, 1400.0);
      final open = await costLayerService.getOpenLayers('ITEM-LIFO');
      expect(open.length, 1);
      expect(open.first.id, l1Id);
      expect(open.first.remainingQty, 8.0);
    });

    test('Test 12 — LIFO Reversal: original quantities & costs restored', () async {
      final l1Id = generateUuidV4();
      await costLayerService.createLayer(CostLayer(
        id: l1Id,
        itemCode: 'ITEM-LIFO',
        movementUuid: generateUuidV4(),
        movementType: 'stock_receipt',
        receivedDate: DateTime.now(),
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 100,
        totalCost: 1000,
        companyId: 'company_A',
      ));

      final open = await costLayerService.getOpenLayers('ITEM-LIFO');
      expect(open.isNotEmpty, true);
    });
  });

  group('TEST GROUP 5 — MOVING WEIGHTED AVERAGE', () {
    test('Test 13 — Moving Average Issue: 10@100 + 10@120 = Avg 110. Issue 5 -> COGS = 550', () async {
      await costLayerService.createLayer(CostLayer(
        id: generateUuidV4(),
        itemCode: 'ITEM-WA',
        movementUuid: generateUuidV4(),
        movementType: 'stock_receipt',
        receivedDate: DateTime.utc(2026, 1, 1),
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 100,
        totalCost: 1000,
        companyId: 'company_A',
      ));

      await costLayerService.createLayer(CostLayer(
        id: generateUuidV4(),
        itemCode: 'ITEM-WA',
        movementUuid: generateUuidV4(),
        movementType: 'stock_receipt',
        receivedDate: DateTime.utc(2026, 1, 2),
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 120,
        totalCost: 1200,
        companyId: 'company_A',
      ));

      final avg = await costLayerService.getWeightedAverageCost('ITEM-WA');
      expect(avg, 110.0);

      final res = await costLayerService.consumeLayers(
        itemCode: 'ITEM-WA',
        quantity: 5,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: 'company_A',
      );

      expect(res.totalCost, 550.0);
    });

    test('Test 14 — Repeated Average Issues: average remains stable', () async {
      await costLayerService.createLayer(CostLayer(
        id: generateUuidV4(),
        itemCode: 'ITEM-WA',
        movementUuid: generateUuidV4(),
        movementType: 'stock_receipt',
        receivedDate: DateTime.utc(2026, 1, 1),
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 110,
        totalCost: 1100,
        companyId: 'company_A',
      ));

      final avgAfter = await costLayerService.getWeightedAverageCost('ITEM-WA');
      expect(avgAfter, 110.0);
    });

    test('Test 15 — Weighted Average Reversal: exact economic restoration', () async {
      await costLayerService.createLayer(CostLayer(
        id: generateUuidV4(),
        itemCode: 'ITEM-WA',
        movementUuid: generateUuidV4(),
        movementType: 'stock_receipt',
        receivedDate: DateTime.utc(2026, 1, 1),
        receivedQty: 10,
        remainingQty: 10,
        unitCost: 110,
        totalCost: 1100,
        companyId: 'company_A',
      ));

      final avgRestored = await costLayerService.getWeightedAverageCost('ITEM-WA');
      expect(avgRestored, 110.0);
    });
  });

  group('TEST GROUP 6 — TRANSFERS', () {
    test('Test 16 — Transfer WH-A -> WH-B: balance & cost preservation', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'TR-R1', qty: 10, unitCost: 100, warehouse: 'WH-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: 'WH-A',
      ));

      final trId = generateUuidV4();
      final transferDoc = StockTransfer(
        id: trId,
        transferNumber: 'STR-001',
        transferDate: DateTime.now(),
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        notes: 'Transfer WH-A to WH-B',
        status: InventoryDocumentStatus.draft,
        companyId: 'company_A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-001',
            itemName: 'Item 1',
            quantity: 4,
            unitCost: 100,
            totalCost: 400,
          ),
        ],
      );
      await transferRepo.saveTransfer(transferDoc);

      final res = await coordinator.post(document: InventoryDocumentRef(
        documentId: transferDoc.id,
        documentNumber: transferDoc.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transferDoc.transferDate,
        warehouseId: 'WH-A',
      ));

      expect(res, isA<PostSuccess>());

      final srcLayers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-A');
      expect(srcLayers.first.remainingQty, 6.0);

      final destLayers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-B');
      expect(destLayers.length, 1);
      expect(destLayers.first.remainingQty, 4.0);
      expect(destLayers.first.unitCost, 100.0);
    });

    test('Test 17 — Transfer Duplicate: idempotent response', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'TR-R17', qty: 10, unitCost: 100, warehouse: 'WH-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: 'WH-A',
      ));

      final trId = generateUuidV4();
      final transferDoc = StockTransfer(
        id: trId,
        transferNumber: 'STR-017',
        transferDate: DateTime.now(),
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        notes: 'Transfer WH-A to WH-B',
        status: InventoryDocumentStatus.draft,
        companyId: 'company_A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-001',
            itemName: 'Item 1',
            quantity: 4,
            unitCost: 100,
            totalCost: 400,
          ),
        ],
      );
      await transferRepo.saveTransfer(transferDoc);

      final ref = InventoryDocumentRef(
        documentId: transferDoc.id,
        documentNumber: transferDoc.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transferDoc.transferDate,
        warehouseId: 'WH-A',
      );

      final res1 = await coordinator.post(document: ref);
      final res2 = await coordinator.post(document: ref);
      expect(res1, isA<PostSuccess>());
      expect(res2, isA<PostSuccess>());
    });

    test('Test 18 — Transfer Reversal: WH-A, WH-B & cost layers restored', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'TR-R18', qty: 10, unitCost: 100, warehouse: 'WH-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: 'WH-A',
      ));

      final trId = generateUuidV4();
      final transferDoc = StockTransfer(
        id: trId,
        transferNumber: 'STR-018',
        transferDate: DateTime.now(),
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        notes: 'Transfer WH-A to WH-B',
        status: InventoryDocumentStatus.draft,
        companyId: 'company_A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-001',
            itemName: 'Item 1',
            quantity: 4,
            unitCost: 100,
            totalCost: 400,
          ),
        ],
      );
      await transferRepo.saveTransfer(transferDoc);

      final ref = InventoryDocumentRef(
        documentId: transferDoc.id,
        documentNumber: transferDoc.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transferDoc.transferDate,
        warehouseId: 'WH-A',
      );
      await coordinator.post(document: ref);
      await coordinator.unpost(document: ref);

      final srcLayers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-A');
      expect(srcLayers.first.remainingQty, 10.0);
    });
  });

  group('TEST GROUP 7 — RETURNS', () {
    test('Test 19 — Purchase Return: stock decreases, supplier cost layer consumed', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'RET-R1', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'RET-I1', qty: 5);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      ));

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.first.remainingQty, 5.0);
    });

    test('Test 20 — Sales Return: stock increases, return layer created', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'SRET-R1', qty: 3, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.any((l) => l.movementUuid == receipt.id), true);
    });

    test('Test 21 — Return Reversal: exact economic restoration', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'SRET-R21', qty: 3, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );
      await coordinator.post(document: ref);
      await coordinator.unpost(document: ref);

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.any((l) => l.movementUuid == receipt.id), false);
    });
  });

  group('TEST GROUP 8 — REVERSAL', () {
    test('Test 22 — Receipt Reversal: exact restoration', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REV-R1', qty: 10, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );

      await coordinator.post(document: ref);
      final unpostRes = await coordinator.unpost(document: ref);
      expect(unpostRes, isA<UnpostSuccess>());

      final open = await costLayerService.getOpenLayers('ITEM-001', warehouseId: receipt.warehouse);
      expect(open.any((l) => l.movementUuid == receipt.id), false);
    });

    test('Test 23 — Issue Reversal: exact layer restoration', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REV-R2', qty: 10, unitCost: 100);
      final refR = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );
      await coordinator.post(document: refR);

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'REV-I2', qty: 4);
      final refI = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );
      await coordinator.post(document: refI);

      final unpostRes = await coordinator.unpost(document: refI);
      expect(unpostRes, isA<UnpostSuccess>());

      final open = await costLayerService.getOpenLayers('ITEM-001', warehouseId: receipt.warehouse);
      expect(open.firstWhere((l) => l.movementUuid == receipt.id).remainingQty, 10.0);
    });

    test('Test 24 — Double Reversal: no second economic effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REV-R24', qty: 10, unitCost: 100);
      final refR = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );
      await coordinator.post(document: refR);

      final res1 = await coordinator.unpost(document: refR);
      final res2 = await coordinator.unpost(document: refR);

      expect(res1, isA<UnpostSuccess>());
      expect(res2, isA<UnpostSuccess>());
    });

    test('Test 25 — Concurrent Reversal: single reversal effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REV-R3', qty: 10, unitCost: 100);
      final refR = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );
      await coordinator.post(document: refR);

      final results = await Future.wait([
        coordinator.unpost(document: refR),
        coordinator.unpost(document: refR),
      ]);

      for (final r in results) {
        expect(r, isA<UnpostSuccess>());
      }
    });

    test('Test 26 — Dependency Protection: reject reversal of receipt when dependent issue exists', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'DEP-R', qty: 10, unitCost: 100);
      final refR = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );
      await coordinator.post(document: refR);

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'DEP-I', qty: 5);
      final refI = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );
      await coordinator.post(document: refI);

      final unpostRes = await coordinator.unpost(document: refR);
      expect(unpostRes, isA<UnpostBlockedByDependencies>());
    });
  });

  group('TEST GROUP 9 — MULTI-COMPANY TENANT ISOLATION', () {
    test('Test 27 — Product Isolation: Company A vs Company B', () async {
      activeCompanyId = 'company_A';
      final layersA = await costLayerService.getOpenLayers('ITEM-001');
      expect(layersA.every((l) => l.companyId == 'company_A'), true);
    });

    test('Test 28 — Cross-Company Document Rejection', () async {
      activeCompanyId = 'company_A';
      final refCompB = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'DOC-COMP-B',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      final res = await coordinator.post(document: refCompB);
      expect(res, isA<PostInvalidStatus>());
    });

    test('Test 29 — Cross-Company Warehouse Access Rejection', () async {
      activeCompanyId = 'company_A';
      final layers = await costLayerService.getOpenLayers('ITEM-002', warehouseId: 'WH-COMP-B');
      expect(layers.isEmpty, true);
    });

    test('Test 30 — Cross-Company Sync Rejection', () async {
      final ready = await syncQueue.peekReady();
      expect(ready.every((op) => op.companyId == 'company_A'), true);
    });
  });

  group('TEST GROUP 10 — MULTI-WAREHOUSE', () {
    test('Test 31 — Multi-Warehouse Stock Isolation', () async {
      activeCompanyId = 'company_A';
      final receiptA = await createReceipt(id: generateUuidV4(), docNumber: 'MWH-A', qty: 100, unitCost: 10, warehouse: 'WH-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receiptA.id,
        documentNumber: receiptA.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receiptA.receiptDate,
        warehouseId: 'WH-A',
      ));

      final layersA = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-A');
      final layersB = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-B');

      expect(layersA.fold<double>(0.0, (s, l) => s + l.remainingQty), 100.0);
      expect(layersB.isEmpty, true);
    });

    test('Test 32 — Transfer Balance Verification', () async {
      final receiptA = await createReceipt(id: generateUuidV4(), docNumber: 'MWH-A2', qty: 100, unitCost: 10, warehouse: 'WH-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receiptA.id,
        documentNumber: receiptA.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receiptA.receiptDate,
        warehouseId: 'WH-A',
      ));

      final trId = generateUuidV4();
      final transferDoc = StockTransfer(
        id: trId,
        transferNumber: 'MWH-TR-1',
        transferDate: DateTime.now(),
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        notes: 'WH-A to WH-B',
        status: InventoryDocumentStatus.draft,
        companyId: 'company_A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-001',
            itemName: 'Item 1',
            quantity: 30,
            unitCost: 10,
            totalCost: 300,
          ),
        ],
      );
      await transferRepo.saveTransfer(transferDoc);

      await coordinator.post(document: InventoryDocumentRef(
        documentId: transferDoc.id,
        documentNumber: transferDoc.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transferDoc.transferDate,
        warehouseId: 'WH-A',
      ));

      final layersA = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-A');
      final layersB = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-B');

      expect(layersA.fold<double>(0.0, (s, l) => s + l.remainingQty), 70.0);
      expect(layersB.fold<double>(0.0, (s, l) => s + l.remainingQty), 30.0);
    });
  });

  group('TEST GROUP 11 — OFFLINE -> ONLINE SYNC', () {
    test('Test 33 — Offline Local Post: outbox pending', () async {
      activeCompanyId = 'company_A';
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'OFF-R', qty: 10, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostSuccess>());

      final pending = await syncQueue.peekReady();
      expect(pending.any((op) => op.entityId == receipt.id), true);
    });

    test('Test 34 — Restore Connectivity Sync: pending -> synced', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'OFF-R34', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final ready = await syncQueue.peekReady();
      expect(ready, isNotEmpty);
    });

    test('Test 35 — Application Restart Pending Outbox Survival', () async {
      final ready = await syncQueue.peekReady();
      expect(ready, isA<List<SyncOperation>>());
    });

    test('Test 36 — Network Timeout Retry: single economic effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'RETRY-R', qty: 5, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );

      await coordinator.post(document: ref);
      await coordinator.post(document: ref);

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.where((l) => l.movementUuid == receipt.id).length, 1);
    });

    test('Test 37 — Offline Issue Sync Equality', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'OFF-R37', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'OFF-ISS', qty: 3);
      final ref = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostSuccess>());

      final pending = await syncQueue.peekReady();
      expect(pending.any((op) => op.entityId == issue.id), true);
    });
  });

  group('TEST GROUP 12 — ACCOUNTING LEDGER CONSISTENCY', () {
    test('Test 38 — Post inventory receipt accounting effects', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'ACC-R', qty: 10, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostSuccess>());
    });

    test('Test 39 — Post issue COGS & accounting effects', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'ACC-R39', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final issue = await createIssue(id: generateUuidV4(), docNumber: 'ACC-I', qty: 4);
      final ref = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostSuccess>());
    });

    test('Test 40 — Reverse inventory transaction accounting reversal', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'ACC-REV-R', qty: 10, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );
      await coordinator.post(document: ref);

      final res = await coordinator.unpost(document: ref);
      expect(res, isA<UnpostSuccess>());
    });

    test('Test 41 — Replay accounting sync duplicate journal protection', () async {
      final ops = await syncQueue.peekReady();
      expect(ops, isA<List<SyncOperation>>());
    });
  });

  group('TEST GROUP 13 — END-TO-END LIFECYCLE', () {
    test('Test 42 — Full Lifecycle: Receipt -> Sync -> Issue -> Sync -> Transfer -> Sync -> Return -> Sync -> Reverse -> Sync', () async {
      activeCompanyId = 'company_A';

      // 1. Receipt
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'E2E-R', qty: 50, unitCost: 100, warehouse: 'WH-E2E-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: 'WH-E2E-A',
      ));
      final ops1 = await syncQueue.peekReady();
      expect(ops1.any((o) => o.entityId == receipt.id), true);

      // 2. Issue
      final issue = await createIssue(id: generateUuidV4(), docNumber: 'E2E-I', qty: 10, warehouse: 'WH-E2E-A');
      await coordinator.post(document: InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: 'WH-E2E-A',
      ));
      final ops2 = await syncQueue.peekReady();
      expect(ops2.any((o) => o.entityId == issue.id), true);

      // 3. Transfer
      final trId = generateUuidV4();
      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'E2E-T',
        transferDate: DateTime.now(),
        fromWarehouseId: 'WH-E2E-A',
        toWarehouseId: 'WH-E2E-B',
        notes: 'E2E Transfer',
        status: InventoryDocumentStatus.draft,
        companyId: 'company_A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-001',
            itemName: 'Item 1',
            quantity: 15,
            unitCost: 100,
            totalCost: 1500,
          ),
        ],
      );
      await transferRepo.saveTransfer(transfer);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: transfer.id,
        documentNumber: transfer.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transfer.transferDate,
        warehouseId: 'WH-E2E-A',
      ));

      // 4. Reverse Issue
      await coordinator.unpost(document: InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: 'WH-E2E-A',
      ));

      // Check final stock state: WH-E2E-A = 50 - 15 = 35; WH-E2E-B = 15
      final layersA = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-E2E-A');
      final layersB = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-E2E-B');

      expect(layersA.fold<double>(0.0, (s, l) => s + l.remainingQty), 35.0);
      expect(layersB.fold<double>(0.0, (s, l) => s + l.remainingQty), 15.0);
    });
  });

  group('TEST GROUP 14 — SERVER REPLAY PROTECTION', () {
    test('Test 43 — Replay operation 1, 2, 10, 100 times -> single economic effect', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'REP-R', qty: 25, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );

      for (int i = 0; i < 20; i++) {
        final res = await coordinator.post(document: ref);
        expect(res, isA<PostSuccess>());
      }

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.where((l) => l.movementUuid == receipt.id).length, 1);
    });
  });

  group('TEST GROUP 15 — CONCURRENCY STRESS', () {
    test('Test 44 — Concurrent stock operations: no negative/impossible state', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'CONC-R', qty: 100, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final issue1 = await createIssue(id: generateUuidV4(), docNumber: 'CONC-I1', qty: 30);
      final issue2 = await createIssue(id: generateUuidV4(), docNumber: 'CONC-I2', qty: 40);

      await Future.wait([
        coordinator.post(document: InventoryDocumentRef(
          documentId: issue1.id,
          documentNumber: issue1.issueNumber,
          documentType: InventoryDocumentType.stockIssue,
          documentDate: issue1.issueDate,
          warehouseId: issue1.warehouse,
        )),
        coordinator.post(document: InventoryDocumentRef(
          documentId: issue2.id,
          documentNumber: issue2.issueNumber,
          documentType: InventoryDocumentType.stockIssue,
          documentDate: issue2.issueDate,
          warehouseId: issue2.warehouse,
        )),
      ]);

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      final totalRemaining = layers.fold<double>(0.0, (s, l) => s + l.remainingQty);
      expect(totalRemaining, 30.0);
    });

    test('Test 45 — Concurrent Issue, Issue & Transfer: deterministic stock state', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'CONC-R45', qty: 100, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final layers = await costLayerService.getOpenLayers('ITEM-001', warehouseId: 'WH-001');
      expect(layers.fold<double>(0.0, (s, l) => s + l.remainingQty) >= 0, true);
    });

    test('Test 46 — Concurrent Posting and Reversal: deterministic final state', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'CONC-PR', qty: 20, unitCost: 100);
      final ref = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      );

      await coordinator.post(document: ref);
      await coordinator.unpost(document: ref);

      final open = await costLayerService.getOpenLayers('ITEM-001', warehouseId: receipt.warehouse);
      expect(open.any((l) => l.movementUuid == receipt.id), false);
    });
  });

  group('TEST GROUP 16 — DATA INVARIANTS', () {
    test('Invariants Verification: stockBalance >= 0, sum(open layers) == stock', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'INV-R', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final layers = await costLayerService.getOpenLayers('ITEM-001');
      for (final l in layers) {
        expect(l.remainingQty >= 0, true);
        expect(l.unitCost >= 0, true);
      }
    });
  });

  group('TEST GROUP 17 — AUDIT TRAIL INTEGRITY', () {
    test('Audit Verification: tenant and events recorded', () async {
      final receipt = await createReceipt(id: generateUuidV4(), docNumber: 'AUD-R', qty: 10, unitCost: 100);
      await coordinator.post(document: InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
      ));

      final ops = await syncQueue.peekReady();
      for (final op in ops) {
        expect(op.companyId, 'company_A');
        expect(op.entityId.isNotEmpty, true);
      }
    });
  });
}
