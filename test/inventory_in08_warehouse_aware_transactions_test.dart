import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';

class MockInventoryDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<bool> hasDependentDocuments(String documentId) async => false;

  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async => [];
}

class MockInventoryAccountingPoster implements InventoryAccountingPoster {
  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}
}

class AlwaysAllowPermissionGuard implements PermissionGuard {
  @override
  void require(String permission) {}

  @override
  void requireAny(Iterable<String> codes) {}

  @override
  void requireAll(List<String> permissions) {}
}

void main() {
  late NexabizDatabase db;
  late StockValidationServiceImpl validationService;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl coordinator;

  const companyA = 'COMPANY_ALPHA';
  const companyB = 'COMPANY_BETA';
  const warehouse1 = '00000000-0000-0000-0000-000000000001';
  const warehouse2 = '00000000-0000-0000-0000-000000000002';
  const warehouseInactive = '00000000-0000-0000-0000-000000000003';
  const warehouseCrossCompany = '00000000-0000-0000-0000-000000000004';
  const itemA = 'ITEM_TEST_WIDGET_A';

  setUp(() async {
    db = NexabizDatabase.memory();

    validationService = StockValidationServiceImpl(db, () => companyA);
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyA,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => companyA,
      null,
      validationService,
    );

    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: MockInventoryDependencyDetector(),
      postingEngine: postingEngine,
      accountingPoster: MockInventoryAccountingPoster(),
      permissionGuard: AlwaysAllowPermissionGuard(),
      readCompanyId: () => companyA,
    );

    // Setup Active Warehouse 1 (Company A)
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            id: const Value(warehouse1),
            code: const Value('WH01'),
            name: const Value('Main Active Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Setup Active Warehouse 2 (Company A)
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            id: const Value(warehouse2),
            code: const Value('WH02'),
            name: const Value('Secondary Active Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Setup Inactive Warehouse (Company A)
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            id: const Value(warehouseInactive),
            code: const Value('WH_INACTIVE'),
            name: const Value('Inactive Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(false),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Setup Warehouse belonging to Company B (Cross-Company)
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            id: const Value(warehouseCrossCompany),
            code: const Value('WH_CROSS'),
            name: const Value('Company B Warehouse'),
            companyId: const Value(companyB),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Setup Product A
    await db
        .into(db.products)
        .insert(
          ProductsCompanion(
            id: Value(generateUuidV4()),
            itemCode: const Value(itemA),
            name: const Value('Test Widget A'),
            packSize: const Value(1),
            price: const Value(100.0),
            companyId: const Value(companyA),
            
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase IN-08: Receipt / Issue / Transfer Warehouse-Aware Transactions', () {
    test(
      '1. Receipt Inbound Posting Increases Stock in Selected Warehouse',
      () async {
        final docId = generateUuidV4();
        final lineId = generateUuidV4();

        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(docId),
                receiptNumber: const Value('REC-001'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyA),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );

        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(lineId),
                movementId: Value(docId),
                movementType: const Value('receipt'),
                itemCode: const Value(itemA),
                itemName: const Value('Test Widget A'),
                quantity: const Value(50.0),
                unitCost: const Value(20.0),
                totalCost: const Value(1000.0),
              ),
            );

        final docRef = InventoryDocumentRef(
          documentId: docId,
          documentNumber: 'REC-001',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouse1,
        );

        final result = await coordinator.post(document: docRef);
        expect(result, isA<PostSuccess>());

        final balWH1 = await validationService.getPostedBalance(
          itemCode: itemA,
          warehouseId: warehouse1,
        );
        expect(balWH1, equals(50.0));
      },
    );

    test('2. Missing Warehouse Document Post Request Rejection', () async {
      final docId = generateUuidV4();
      final lineId = generateUuidV4();

      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(docId),
              receiptNumber: const Value('REC-EMPTY-WH'),
              receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyA),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(lineId),
              movementId: Value(docId),
              movementType: const Value('receipt'),
              itemCode: const Value(itemA),
              itemName: const Value('Test Widget A'),
              quantity: const Value(10.0),
              unitCost: const Value(10.0),
              totalCost: const Value(100.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: docId,
        documentNumber: 'REC-EMPTY-WH',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: '',
      );

      final result = await coordinator.post(document: docRef);
      expect(result, isA<PostInvalidStatus>());
    });

    test('3. Inactive Warehouse Document Post Request Rejection', () async {
      final docId = generateUuidV4();
      final lineId = generateUuidV4();

      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(docId),
              receiptNumber: const Value('REC-INACTIVE'),
              receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyA),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(lineId),
              movementId: Value(docId),
              movementType: const Value('receipt'),
              itemCode: const Value(itemA),
              itemName: const Value('Test Widget A'),
              quantity: const Value(10.0),
              unitCost: const Value(10.0),
              totalCost: const Value(100.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: docId,
        documentNumber: 'REC-INACTIVE',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: warehouseInactive,
      );

      final result = await coordinator.post(document: docRef);
      expect(result, isA<PostInvalidStatus>());
    });

    test('4. Cross-Company Warehouse Access Rejection', () async {
      final docId = generateUuidV4();
      final lineId = generateUuidV4();

      await db
          .into(db.stockReceipts)
          .insert(
            StockReceiptsCompanion(
              uuid: Value(docId),
              receiptNumber: const Value('REC-CROSS'),
              receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyA),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(lineId),
              movementId: Value(docId),
              movementType: const Value('receipt'),
              itemCode: const Value(itemA),
              itemName: const Value('Test Widget A'),
              quantity: const Value(10.0),
              unitCost: const Value(10.0),
              totalCost: const Value(100.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: docId,
        documentNumber: 'REC-CROSS',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: warehouseCrossCompany,
      );

      final result = await coordinator.post(document: docRef);
      expect(result, isA<PostInvalidStatus>());
    });

    test('5. Insufficient Stock Outbound Rejection', () async {
      final docId = generateUuidV4();
      final lineId = generateUuidV4();

      await db
          .into(db.stockIssues)
          .insert(
            StockIssuesCompanion(
              uuid: Value(docId),
              issueNumber: const Value('ISS-OVERDRAW'),
              warehouse: const Value(warehouse1),
              issueDate: Value(DateTime.now().millisecondsSinceEpoch),
              status: const Value('draft'),
              companyId: const Value(companyA),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db
          .into(db.stockMovementLines)
          .insert(
            StockMovementLinesCompanion(
              uuid: Value(lineId),
              movementId: Value(docId),
              movementType: const Value('issue'),
              itemCode: const Value(itemA),
              itemName: const Value('Test Widget A'),
              quantity: const Value(999.0),
              unitCost: const Value(10.0),
              totalCost: const Value(9990.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: docId,
        documentNumber: 'ISS-OVERDRAW',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: warehouse1,
      );

      final result = await coordinator.post(document: docRef);
      expect(result, isA<PostStockShortage>());
    });

    test(
      '6. Stock Transfer Decreases Source, Increases Destination with Exact Valuation',
      () async {
        // 1. Post receipt into Warehouse 1: 100 units @ 15.0 = 1500.0 total cost
        final recId = generateUuidV4();
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                uuid: Value(recId),
                receiptNumber: const Value('REC-INIT-1'),
                receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyA),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(generateUuidV4()),
                movementId: Value(recId),
                movementType: const Value('receipt'),
                itemCode: const Value(itemA),
                itemName: const Value('Test Widget A'),
                quantity: const Value(100.0),
                unitCost: const Value(15.0),
                totalCost: const Value(1500.0),
              ),
            );

        await coordinator.post(
          document: InventoryDocumentRef(
            documentId: recId,
            documentNumber: 'REC-INIT-1',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: warehouse1,
          ),
        );

        // 2. Transfer 40 units from Warehouse 1 -> Warehouse 2
        final trsId = generateUuidV4();
        final trsLineId = generateUuidV4();
        await db
            .into(db.stockTransfers)
            .insert(
              StockTransfersCompanion(
                uuid: Value(trsId),
                transferNumber: const Value('TRS-001'),
                fromWarehouseId: const Value(warehouse1),
                toWarehouseId: const Value(warehouse2),
                transferDate: Value(DateTime.now().millisecondsSinceEpoch),
                status: const Value('draft'),
                companyId: const Value(companyA),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                uuid: Value(trsLineId),
                movementId: Value(trsId),
                movementType: const Value('transfer'),
                itemCode: const Value(itemA),
                itemName: const Value('Test Widget A'),
                quantity: const Value(40.0),
                unitCost: const Value(15.0),
                totalCost: const Value(600.0),
              ),
            );

        final trsResult = await coordinator.post(
          document: InventoryDocumentRef(
            documentId: trsId,
            documentNumber: 'TRS-001',
            documentType: InventoryDocumentType.stockTransfer,
            documentDate: DateTime.now(),
            warehouseId: warehouse1,
          ),
        );
        expect(trsResult, isA<PostSuccess>());

        // Verify stock balances: WH1 = 60, WH2 = 40
        final balWH1 = await validationService.getPostedBalance(
          itemCode: itemA,
          warehouseId: warehouse1,
        );
        final balWH2 = await validationService.getPostedBalance(
          itemCode: itemA,
          warehouseId: warehouse2,
        );

        expect(balWH1, equals(60.0));
        expect(balWH2, equals(40.0));
      },
    );
  });
}
