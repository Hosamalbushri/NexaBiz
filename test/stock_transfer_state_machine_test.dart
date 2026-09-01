import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/stock_transfer_repository.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_repository.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late InventoryDatabase invDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl stockValidationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late StockTransferRepository transferRepo;
  late WarehouseRepository warehouseRepo;

  const tenantA = 'company-tenant-alpha';
  const tenantB = 'company-tenant-beta';
  String activeTenant = tenantA;

  late String whSourceAId;
  late String whDestBId;

  setUp(() async {
    invDb = InventoryDatabase.memory();
    activeTenant = tenantA;
    whSourceAId = generateUuidV4();
    whDestBId = generateUuidV4();

    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => activeTenant,
    );

    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => activeTenant,
    );

    stockValidationService = StockValidationServiceImpl(
      invDb,
      () => activeTenant,
    );

    dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => activeTenant,
    );

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      postingEngine: postingEngine,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      readCompanyId: () => activeTenant,
    );

    transferRepo = StockTransferRepositoryImpl(
      db: invDb,
      costLayerService: costLayerService,
      readCompanyId: () => activeTenant,
    );

    warehouseRepo = WarehouseRepositoryImpl(
      invDb,
      null,
      () => activeTenant,
    );

    // Setup base product and warehouses
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await invDb.into(invDb.products).insert(
          ProductsCompanion.insert(
            uuid: generateUuidV4(),
            itemCode: 'ITEM-TR-1',
            name: 'Transfer Test Item',
            companyId: const drift.Value(tenantA),
            onHandQty: const drift.Value(0.0),
            unitCost: const drift.Value(0.0),
            price: 0.0,
            packSize: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await warehouseRepo.saveWarehouse(
      Warehouse(
        id: whSourceAId,
        code: 'WH-A',
        name: 'Warehouse A',
        companyId: tenantA,
      ),
    );

    await warehouseRepo.saveWarehouse(
      Warehouse(
        id: whDestBId,
        code: 'WH-B',
        name: 'Warehouse B',
        companyId: tenantA,
      ),
    );
  });

  tearDown(() async {
    await invDb.close();
  });

  Future<void> _seedReceipt({
    required String receiptId,
    required String warehouseId,
    required double qty,
    required double unitCost,
  }) async {
    final receiptDate = DateTime.now().toUtc();
    await invDb.into(invDb.stockReceipts).insert(
          StockReceiptsCompanion(
            uuid: drift.Value(receiptId),
            receiptNumber: drift.Value('REC-$receiptId'),
            receiptDate: drift.Value(receiptDate.millisecondsSinceEpoch),
            createdAt: drift.Value(receiptDate.millisecondsSinceEpoch),
            updatedAt: drift.Value(receiptDate.millisecondsSinceEpoch),
            status: const drift.Value('draft'),
            companyId: const drift.Value(tenantA),
          ),
        );

    await invDb.into(invDb.stockMovementLines).insert(
          StockMovementLinesCompanion(
            uuid: drift.Value(generateUuidV4()),
            movementUuid: drift.Value(receiptId),
            movementType: const drift.Value('receipt'),
            itemCode: const drift.Value('ITEM-TR-1'),
            itemName: const drift.Value('Transfer Test Item'),
            quantity: drift.Value(qty),
            unitCost: drift.Value(unitCost),
            totalCost: drift.Value(qty * unitCost),
          ),
        );

    final ref = InventoryDocumentRef(
      documentId: receiptId,
      documentNumber: 'REC-$receiptId',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: receiptDate,
      warehouseId: warehouseId,
    );

    await coordinator.post(document: ref);
  }

  group('ROOT FIX 28 — Stock Transfer State Machine Tests', () {
    test('1. Valid State Transition: draft -> posted -> draft (unpost)', () async {
      final recId = generateUuidV4();
      final trId = generateUuidV4();
      final lineId = generateUuidV4();

      await _seedReceipt(
        receiptId: recId,
        warehouseId: whSourceAId,
        qty: 100,
        unitCost: 10.0,
      );

      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-01',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whDestBId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: tenantA,
        lines: [
          StockTransferLine(
            id: lineId,
            transferUuid: trId,
            itemCode: 'ITEM-TR-1',
            itemName: 'Transfer Test Item',
            quantity: 30,
            unitCost: 10.0,
            totalCost: 300.0,
          ),
        ],
      );

      await transferRepo.saveTransfer(transfer);

      // Verify draft state
      final savedDraft = await transferRepo.getTransferById(trId);
      expect(savedDraft?.status, InventoryDocumentStatus.draft);

      // Post transfer
      final ref = InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'TR-NUM-01',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transfer.transferDate,
      );

      final postRes = await coordinator.post(document: ref);
      expect(postRes, isA<PostSuccess>());

      final postedDoc = await transferRepo.getTransferById(trId);
      expect(postedDoc?.status, InventoryDocumentStatus.posted);

      // Unpost transfer
      final unpostRes = await coordinator.unpost(document: ref);
      expect(unpostRes, isA<UnpostSuccess>());

      final unpostedDoc = await transferRepo.getTransferById(trId);
      expect(unpostedDoc?.status, InventoryDocumentStatus.draft);
    });

    test('2. Invalid State Transition: cancelled -> posted is blocked', () async {
      final trId = generateUuidV4();
      final lineId = generateUuidV4();

      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-CANCEL',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whDestBId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.cancelled,
        companyId: tenantA,
        lines: [
          StockTransferLine(
            id: lineId,
            transferUuid: trId,
            itemCode: 'ITEM-TR-1',
            itemName: 'Transfer Test Item',
            quantity: 10,
            unitCost: 10.0,
            totalCost: 100.0,
          ),
        ],
      );

      await transferRepo.saveTransfer(transfer);

      final ref = InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'TR-NUM-CANCEL',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transfer.transferDate,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostInvalidStatus>());
      expect((res as PostInvalidStatus).reason, contains('ملغي'));
    });

    test('3. Invalid State Transition: Editing cancelled transfer is blocked', () async {
      final trId = generateUuidV4();
      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-CANCEL2',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whDestBId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.cancelled,
        companyId: tenantA,
      );

      await transferRepo.saveTransfer(transfer);

      final updated = transfer.copyWith(notes: 'Modifying cancelled');
      expect(
        () => transferRepo.saveTransfer(updated),
        throwsA(isA<JournalException>()),
      );
    });

    test('4. Invariant: Stock Quantity Conservation (+qty dest, -qty source)', () async {
      final recId = generateUuidV4();
      final trId = generateUuidV4();
      final lineId = generateUuidV4();

      await _seedReceipt(
        receiptId: recId,
        warehouseId: whSourceAId,
        qty: 50,
        unitCost: 20.0,
      );

      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-CONSERVE',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whDestBId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: tenantA,
        lines: [
          StockTransferLine(
            id: lineId,
            transferUuid: trId,
            itemCode: 'ITEM-TR-1',
            itemName: 'Transfer Test Item',
            quantity: 20,
            unitCost: 20.0,
            totalCost: 400.0,
          ),
        ],
      );

      await transferRepo.saveTransfer(transfer);

      final ref = InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'TR-NUM-CONSERVE',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transfer.transferDate,
      );

      await coordinator.post(document: ref);

      // Verify warehouse stock conservation
      final sourceStock = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-TR-1',
        warehouseId: whSourceAId,
      );
      final destStock = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-TR-1',
        warehouseId: whDestBId,
      );
      final totalStock = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-TR-1',
      );

      expect(sourceStock, equals(30.0));
      expect(destStock, equals(20.0));
      expect(totalStock, equals(50.0)); // Total company stock remains 50
    });

    test('5. Invariant: Same warehouse transfer (WH-A -> WH-A) is blocked', () async {
      final trId = generateUuidV4();
      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-SAME',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whSourceAId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: tenantA,
      );

      expect(
        () => transferRepo.saveTransfer(transfer),
        throwsA(isA<StateError>()),
      );
    });

    test('6. Invariant: Source warehouse shortage blocks transfer posting', () async {
      final recId = generateUuidV4();
      final trId = generateUuidV4();
      final lineId = generateUuidV4();

      await _seedReceipt(
        receiptId: recId,
        warehouseId: whSourceAId,
        qty: 10,
        unitCost: 15.0,
      );

      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-SHORT',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whDestBId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: tenantA,
        lines: [
          StockTransferLine(
            id: lineId,
            transferUuid: trId,
            itemCode: 'ITEM-TR-1',
            itemName: 'Transfer Test Item',
            quantity: 50, // Available is only 10
            unitCost: 15.0,
            totalCost: 750.0,
          ),
        ],
      );

      await transferRepo.saveTransfer(transfer);

      final ref = InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'TR-NUM-SHORT',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transfer.transferDate,
      );

      final res = await coordinator.post(document: ref);
      expect(res, isA<PostStockShortage>());
    });

    test('7. Tenant Isolation: Transfer to unauthorized company warehouse is blocked', () async {
      final tenantBWhId = generateUuidV4();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Seed warehouse directly into database owned by tenantB
      await invDb.into(invDb.warehouses).insert(
            WarehousesCompanion.insert(
              uuid: tenantBWhId,
              code: 'WH-TB',
              name: 'Warehouse Tenant B',
              companyId: const drift.Value(tenantB),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final trId = generateUuidV4();
      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-CROSS',
        fromWarehouseId: whSourceAId,
        toWarehouseId: tenantBWhId, // Unauthorized warehouse owned by tenantB
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: tenantA,
      );

      expect(
        () => transferRepo.saveTransfer(transfer),
        throwsA(isA<StateError>()),
      );
    });

    test('8. Draft Deletion Integrity: Soft-deleting draft transfer does not touch cost layers', () async {
      final recId = generateUuidV4();
      final trId = generateUuidV4();
      final lineId = generateUuidV4();

      await _seedReceipt(
        receiptId: recId,
        warehouseId: whSourceAId,
        qty: 100,
        unitCost: 5.0,
      );

      final transfer = StockTransfer(
        id: trId,
        transferNumber: 'TR-NUM-DEL',
        fromWarehouseId: whSourceAId,
        toWarehouseId: whDestBId,
        transferDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: tenantA,
        lines: [
          StockTransferLine(
            id: lineId,
            transferUuid: trId,
            itemCode: 'ITEM-TR-1',
            itemName: 'Transfer Test Item',
            quantity: 25,
            unitCost: 5.0,
            totalCost: 125.0,
          ),
        ],
      );

      await transferRepo.saveTransfer(transfer);
      await transferRepo.deleteTransfer(trId);

      // Verify stock in whSourceAId is still 100 (unaffected by draft delete)
      final balance = await stockValidationService.getPostedBalance(
        itemCode: 'ITEM-TR-1',
        warehouseId: whSourceAId,
      );
      expect(balance, equals(100.0));
    });
  });
}
