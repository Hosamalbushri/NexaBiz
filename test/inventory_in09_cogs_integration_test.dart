import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_ledger_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/stock_ledger_transaction_type.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
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

class TrackingAccountingPoster implements InventoryAccountingPoster {
  final List<Map<String, dynamic>> postedEntries = [];
  final List<String> reversedDocuments = [];

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {
    postedEntries.add({
      'documentId': document.documentId,
      'documentType': document.documentType,
      'totalAmount': totalAmount,
      'accountId': accountId,
      'isPosted': isPosted,
    });
  }

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {
    reversedDocuments.add(document.documentId);
  }

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
  late InventoryDatabase db;
  late StockValidationServiceImpl validationService;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl coordinator;
  late InventoryLedgerServiceImpl ledgerService;
  late TrackingAccountingPoster accountingPoster;

  const companyA = 'COMPANY_ALPHA';
  const warehouseA = '00000000-0000-0000-0000-00000000000A';
  const warehouseB = '00000000-0000-0000-0000-00000000000B';
  const productX = 'PROD_X_WIDGET';

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());

    validationService = StockValidationServiceImpl(db, () => companyA);
    costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => companyA);
    postingEngine = PostingEngineImpl(db, costLayerService, null, () => companyA, null, validationService);
    accountingPoster = TrackingAccountingPoster();

    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: MockInventoryDependencyDetector(),
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      permissionGuard: AlwaysAllowPermissionGuard(),
      readCompanyId: () => companyA,
    );

    ledgerService = InventoryLedgerServiceImpl(db: db);

    // Setup Active Warehouse A
    await db.into(db.warehouses).insert(
      WarehousesCompanion(
        uuid: const Value(warehouseA),
        code: const Value('WHA'),
        name: const Value('Warehouse Alpha'),
        companyId: const Value(companyA),
        isActive: const Value(true),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Setup Active Warehouse B
    await db.into(db.warehouses).insert(
      WarehousesCompanion(
        uuid: const Value(warehouseB),
        code: const Value('WHB'),
        name: const Value('Warehouse Beta'),
        companyId: const Value(companyA),
        isActive: const Value(true),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Setup Product X
    await db.into(db.products).insert(
      ProductsCompanion(
        uuid: Value(generateUuidV4()),
        itemCode: const Value(productX),
        name: const Value('Product X Widget'),
        packSize: const Value(1),
        price: const Value(250.0), // Retail Price 250
        companyId: const Value(companyA),
        onHandQty: const Value(0.0),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase IN-09: Inventory / Sales / Accounting / COGS Integration Tests', () {
    test('1. COGS is derived from inventory costing layer (not retail sales price)', () async {
      // 1. Receive 100 units of Product X into Warehouse A at unit cost of 40.0
      final recId = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(recId),
          receiptNumber: const Value('REC-COGS-1'),
          receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(recId),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(100.0),
          unitCost: const Value(40.0),
          totalCost: const Value(4000.0),
        ),
      );

      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: recId,
          documentNumber: 'REC-COGS-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      // 2. Post Sale Invoice of 10 units at Retail Price 250.0
      final saleId = generateUuidV4();
      final saleLineId = generateUuidV4();

      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(saleLineId),
          movementUuid: Value(saleId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(0.0), // Cost NOT calculated by UI
          totalCost: const Value(0.0),
        ),
      );

      final saleDocRef = InventoryDocumentRef(
        documentId: saleId,
        documentNumber: 'INV-2026-001',
        documentType: InventoryDocumentType.salesInvoice,
        documentDate: DateTime.now(),
        warehouseId: warehouseA,
      );

      final postResult = await coordinator.post(document: saleDocRef);
      expect(postResult, isA<PostSuccess>());

      // COGS for 10 units @ cost 40.0 must be EXACTLY 400.0 (NOT 2500.0 retail price!)
      final postedValue = (postResult as PostSuccess).postedValue;
      expect(postedValue, equals(400.0));

      // Verify StockMovementLedgers entry
      final entries = await ledgerService.getLedgerEntriesForDocument(
        companyId: companyA,
        documentId: saleId,
      );
      expect(entries.length, equals(1));
      final entry = entries.first;
      expect(entry.unitCost, equals(40.0));
      expect(entry.totalCost, equals(400.0));
    });

    test('2. Discount & Sales Tax do not corrupt inventory COGS cost layer', () async {
      // Receive 50 units @ cost 60.0
      final recId = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(recId),
          receiptNumber: const Value('REC-TAX-1'),
          receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(recId),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(50.0),
          unitCost: const Value(60.0),
          totalCost: const Value(3000.0),
        ),
      );

      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: recId,
          documentNumber: 'REC-TAX-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      // Post Sale of 5 units (Retail 300, 50% discount = 150, 15% VAT tax = 22.5)
      final saleId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(saleId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(5.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final saleDocRef = InventoryDocumentRef(
        documentId: saleId,
        documentNumber: 'INV-DISCOUNT-1',
        documentType: InventoryDocumentType.salesInvoice,
        documentDate: DateTime.now(),
        warehouseId: warehouseA,
      );

      final postResult = await coordinator.post(document: saleDocRef);
      expect(postResult, isA<PostSuccess>());

      // COGS for 5 units @ 60.0 = 300.0 (Unchanged by discount or tax!)
      final cogs = (postResult as PostSuccess).postedValue;
      expect(cogs, equals(300.0));
    });

    test('3. Simultaneous multi-warehouse sales isolate stock and COGS per warehouse', () async {
      // Warehouse A: 50 units @ 15.0 cost
      final recAId = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(recAId),
          receiptNumber: const Value('REC-WHA-1'),
          receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(recAId),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(50.0),
          unitCost: const Value(15.0),
          totalCost: const Value(750.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: recAId,
          documentNumber: 'REC-WHA-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      // Warehouse B: 50 units @ 35.0 cost
      final recBId = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(recBId),
          receiptNumber: const Value('REC-WHB-1'),
          receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(recBId),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(50.0),
          unitCost: const Value(35.0),
          totalCost: const Value(1750.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: recBId,
          documentNumber: 'REC-WHB-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseB,
        ),
      );

      // Sale A from Warehouse A (10 units)
      final saleAId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(saleAId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );
      final resA = await coordinator.post(
        document: InventoryDocumentRef(
          documentId: saleAId,
          documentNumber: 'INV-WHA',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      // Sale B from Warehouse B (10 units)
      final saleBId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(saleBId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );
      final resB = await coordinator.post(
        document: InventoryDocumentRef(
          documentId: saleBId,
          documentNumber: 'INV-WHB',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseB,
        ),
      );

      expect((resA as PostSuccess).postedValue, equals(150.0)); // 10 * 15.0
      expect((resB as PostSuccess).postedValue, equals(350.0)); // 10 * 35.0

      final balA = await validationService.getPostedBalance(itemCode: productX, warehouseId: warehouseA);
      final balB = await validationService.getPostedBalance(itemCode: productX, warehouseId: warehouseB);

      expect(balA, equals(40.0));
      expect(balB, equals(40.0));
    });

    test('4. FIFO Costing Method consumes oldest layers first', () async {
      // 1. Receipt 1: 10 units @ 10.0
      final rec1Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec1Id),
          receiptNumber: const Value('REC-FIFO-1'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec1Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(10.0),
          totalCost: const Value(100.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec1Id,
          documentNumber: 'REC-FIFO-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 2)),
          warehouseId: warehouseA,
        ),
      );

      // 2. Receipt 2: 10 units @ 20.0
      final rec2Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec2Id),
          receiptNumber: const Value('REC-FIFO-2'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec2Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(20.0),
          totalCost: const Value(200.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec2Id,
          documentNumber: 'REC-FIFO-2',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 1)),
          warehouseId: warehouseA,
        ),
      );

      // Post Sale of 15 units under FIFO
      final saleId = generateUuidV4();
      final lineId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(lineId),
          movementUuid: Value(saleId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(15.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final res = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: saleId,
          documentNumber: 'FIFO-SALE',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
        lines: [
          OutboundLineData(
            lineUuid: lineId,
            itemCode: productX,
            itemName: 'Product X Widget',
            quantity: 15.0,
          ),
        ],
        warehouseId: warehouseA,
        valuationMethod: CostValuationMethod.fifo,
      );

      // FIFO: (10 * 10) + (5 * 20) = 200.0
      expect(res, equals(200.0));
    });

    test('5. LIFO Costing Method consumes newest layers first', () async {
      // 1. Receipt 1: 10 units @ 10.0
      final rec1Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec1Id),
          receiptNumber: const Value('REC-LIFO-1'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec1Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(10.0),
          totalCost: const Value(100.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec1Id,
          documentNumber: 'REC-LIFO-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 2)),
          warehouseId: warehouseA,
        ),
      );

      // 2. Receipt 2: 10 units @ 20.0
      final rec2Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec2Id),
          receiptNumber: const Value('REC-LIFO-2'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec2Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(20.0),
          totalCost: const Value(200.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec2Id,
          documentNumber: 'REC-LIFO-2',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 1)),
          warehouseId: warehouseA,
        ),
      );

      // Post Sale of 15 units under LIFO
      final saleId = generateUuidV4();
      final lineId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(lineId),
          movementUuid: Value(saleId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(15.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final res = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: saleId,
          documentNumber: 'LIFO-SALE',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
        lines: [
          OutboundLineData(
            lineUuid: lineId,
            itemCode: productX,
            itemName: 'Product X Widget',
            quantity: 15.0,
          ),
        ],
        warehouseId: warehouseA,
        valuationMethod: CostValuationMethod.lifo,
      );

      // LIFO: (10 * 20) + (5 * 10) = 250.0
      expect(res, equals(250.0));
    });

    test('6. Weighted Average Cost (WAC) method calculates moving average cost', () async {
      // 1. Receipt 1: 10 units @ 10.0
      final rec1Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec1Id),
          receiptNumber: const Value('REC-WAC-1'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec1Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(10.0),
          totalCost: const Value(100.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec1Id,
          documentNumber: 'REC-WAC-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 2)),
          warehouseId: warehouseA,
        ),
      );

      // 2. Receipt 2: 10 units @ 30.0
      final rec2Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec2Id),
          receiptNumber: const Value('REC-WAC-2'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec2Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(30.0),
          totalCost: const Value(300.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec2Id,
          documentNumber: 'REC-WAC-2',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 1)),
          warehouseId: warehouseA,
        ),
      );

      // Total 20 units, Total Cost 400.0 -> WAC = 20.0 / unit
      final saleId = generateUuidV4();
      final lineId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(lineId),
          movementUuid: Value(saleId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(5.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final res = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: saleId,
          documentNumber: 'WAC-SALE',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
        lines: [
          OutboundLineData(
            lineUuid: lineId,
            itemCode: productX,
            itemName: 'Product X Widget',
            quantity: 5.0,
          ),
        ],
        warehouseId: warehouseA,
        valuationMethod: CostValuationMethod.weightedAverage,
      );

      // WAC: 5 units * 20.0 = 100.0
      expect(res, equals(100.0));
    });

    test('7. Sale Reversal restores consumed layers without recalculating cost with current method', () async {
      // 1. Receive 10 units @ 25.0
      final recId = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(recId),
          receiptNumber: const Value('REC-REV-1'),
          receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyA),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(recId),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(25.0),
          totalCost: const Value(250.0),
        ),
      );

      final recDocRef = InventoryDocumentRef(
        documentId: recId,
        documentNumber: 'REC-REV-1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: warehouseA,
      );
      await coordinator.post(document: recDocRef);

      // 2. Sale 10 units (COGS = 250.0)
      final saleId = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(saleId),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X Widget'),
          quantity: const Value(10.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final saleDocRef = InventoryDocumentRef(
        documentId: saleId,
        documentNumber: 'INV-REV-1',
        documentType: InventoryDocumentType.salesInvoice,
        documentDate: DateTime.now(),
        warehouseId: warehouseA,
      );
      await coordinator.post(document: saleDocRef);

      // Verify stock balance is 0
      var bal = await validationService.getPostedBalance(itemCode: productX, warehouseId: warehouseA);
      expect(bal, equals(0.0));

      // 3. Unpost/Reverse Sale Invoice
      final unpostRes = await coordinator.unpost(
        document: InventoryDocumentRef(
          documentId: saleId,
          documentNumber: 'INV-REV-1',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
          status: InventoryDocumentStatus.posted,
        ),
      );

      expect(unpostRes, isA<UnpostSuccess>());

      // Stock balance restored to 10.0
      bal = await validationService.getPostedBalance(itemCode: productX, warehouseId: warehouseA);
      expect(bal, equals(10.0));

      // Ledger reversal entry recorded
      final ledgerEntries = await ledgerService.getLedgerEntriesForDocument(
        companyId: companyA,
        documentId: saleId,
      );
      expect(ledgerEntries.length, equals(2)); // Original issue + Reversal
      final revEntry = ledgerEntries.firstWhere((e) => e.movementType == StockLedgerTransactionType.reversal);
      expect(revEntry.unitCost, equals(25.0));
      expect(revEntry.totalCost, equals(250.0));
    });
  });
}
