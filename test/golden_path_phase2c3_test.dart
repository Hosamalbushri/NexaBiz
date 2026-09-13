import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  group('Phase 2C-3 Golden Path Integration Test Suite', () {
    late NexabizDatabase db;
    final companyA = generateUuidV7();
    final companyB = generateUuidV7();

    final whA = generateUuidV7();
    final whB = generateUuidV7();

    const prodItemCode = 'PROD-GP-001';

    setUp(() async {
      db = NexabizDatabase.memory();

      // Seed Warehouses
      await db.into(db.warehouses).insert(
        WarehousesCompanion.insert(
          id: Value(whA),
          code: 'WH-A',
          name: 'Main Warehouse A',
          companyId: companyA,
        ),
      );

      await db.into(db.warehouses).insert(
        WarehousesCompanion.insert(
          id: Value(whB),
          code: 'WH-B',
          name: 'Main Warehouse B',
          companyId: companyB,
        ),
      );

      // Seed Products
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: Value(generateUuidV7()),
          itemCode: prodItemCode,
          name: 'Golden Product',
          companyId: companyA,
        ),
      );

      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: Value(generateUuidV7()),
          itemCode: prodItemCode,
          name: 'Golden Product B',
          companyId: companyB,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('TEST A — PURCHASE LIFECYCLE (Receipt -> Cost Layer -> Stock Ledger -> Single Effect)', () async {
      final costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => companyA);
      final postingEngine = PostingEngineImpl(db, costLayerService, null, () => companyA);

      final receiptId = generateUuidV7();
      final lineId = generateUuidV7();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Seed Stock Receipt document header
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          id: Value(receiptId),
          receiptNumber: 'REC-001',
          receiptDate: nowMs,
          createdAt: nowMs,
          updatedAt: nowMs,
          status: const Value('draft'),
          currencyCode: 'YER',
          companyId: Value(companyA),
        ),
      );

      // Seed Stock Movement Line
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          id: Value(lineId),
          receiptId: Value(receiptId),
          movementType: 'receipt',
          itemCode: prodItemCode,
          itemName: 'Golden Product',
          quantity: const Value(10.0),
          unitCost: const Value(50.0),
          totalCost: const Value(500.0),
          companyId: companyA,
        ),
      );

      // Execute Inbound Posting
      final totalValue = await postingEngine.applyInboundPosting(
        document: InventoryDocumentRef(
          documentId: receiptId,
          documentNumber: 'REC-001',
          documentType: InventoryDocumentType.stockReceipt,
          warehouseId: whA,
          currencyCode: 'YER',
          exchangeRate: 1.0,
          documentDate: DateTime.now(),
        ),
        lines: [
          InboundLineData(
            lineUuid: lineId,
            itemCode: prodItemCode,
            itemName: 'Golden Product',
            quantity: 10.0,
            unitCost: 50.0,
          ),
        ],
        warehouseId: whA,
        documentDate: DateTime.now(),
      );

      expect(totalValue, equals(500.0));

      // Verify Cost Layer created exactly once
      final layers = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.companyId.equals(companyA) & tbl.itemCode.equals(prodItemCode)))
          .get();

      expect(layers.length, equals(1));
      expect(layers.first.receivedQty, equals(10.0));
      expect(layers.first.unitCost, equals(50.0));
      expect(layers.first.totalCost, equals(500.0));

      // Verify Stock Ledger entry created
      final ledgers = await (db.select(db.stockMovementLedgers)
            ..where((tbl) => tbl.companyId.equals(companyA) & tbl.sourceDocumentId.equals(receiptId)))
          .get();

      expect(ledgers.length, equals(1));
      expect(ledgers.first.direction, equals('inbound'));

      // Verify Stock Receipt header status updated to posted
      final receipt = await (db.select(db.stockReceipts)..where((tbl) => tbl.id.equals(receiptId))).getSingle();
      expect(receipt.status, equals('posted'));
    });

    test('TEST B — SALE LIFECYCLE (Stock Check -> Outbound Posting -> FIFO Cost Consumption)', () async {
      final costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => companyA);
      final postingEngine = PostingEngineImpl(db, costLayerService, null, () => companyA);

      final receiptId = generateUuidV7();
      final line1Id = generateUuidV7();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          id: Value(receiptId),
          receiptNumber: 'REC-002',
          receiptDate: nowMs,
          createdAt: nowMs,
          updatedAt: nowMs,
          status: const Value('draft'),
          currencyCode: 'YER',
          companyId: Value(companyA),
        ),
      );

      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          id: Value(line1Id),
          receiptId: Value(receiptId),
          movementType: 'receipt',
          itemCode: prodItemCode,
          itemName: 'Golden Product',
          quantity: const Value(10.0),
          unitCost: const Value(100.0),
          totalCost: const Value(1000.0),
          companyId: companyA,
        ),
      );

      await postingEngine.applyInboundPosting(
        document: InventoryDocumentRef(
          documentId: receiptId,
          documentNumber: 'REC-002',
          documentType: InventoryDocumentType.stockReceipt,
          warehouseId: whA,
          currencyCode: 'YER',
          exchangeRate: 1.0,
          documentDate: DateTime.now(),
        ),
        lines: [
          InboundLineData(
            lineUuid: line1Id,
            itemCode: prodItemCode,
            itemName: 'Golden Product',
            quantity: 10.0,
            unitCost: 100.0,
          ),
        ],
        warehouseId: whA,
        documentDate: DateTime.now(),
      );

      // Outbound Sale Issue of 4 units
      final issueId = generateUuidV7();
      final issueLineId = generateUuidV7();

      await db.into(db.stockIssues).insert(
        StockIssuesCompanion.insert(
          id: Value(issueId),
          issueNumber: 'ISS-001',
          issueDate: nowMs,
          createdAt: nowMs,
          updatedAt: nowMs,
          status: const Value('draft'),
          currencyCode: 'YER',
          companyId: Value(companyA),
        ),
      );

      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          id: Value(issueLineId),
          issueId: Value(issueId),
          movementType: 'issue',
          itemCode: prodItemCode,
          itemName: 'Golden Product',
          quantity: const Value(4.0),
          unitCost: const Value(100.0),
          totalCost: const Value(400.0),
          companyId: companyA,
        ),
      );

      final totalCogs = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: issueId,
          documentNumber: 'ISS-001',
          documentType: InventoryDocumentType.stockIssue,
          warehouseId: whA,
          currencyCode: 'YER',
          exchangeRate: 1.0,
          documentDate: DateTime.now(),
        ),
        lines: [
          OutboundLineData(
            lineUuid: issueLineId,
            itemCode: prodItemCode,
            itemName: 'Golden Product',
            quantity: 4.0,
          ),
        ],
        warehouseId: whA,
        valuationMethod: CostValuationMethod.fifo,
      );

      expect(totalCogs, equals(400.0));

      // Check remaining stock balance is 6.0
      final stocks = await (db.select(db.productWarehouseStocks)
            ..where((tbl) => tbl.companyId.equals(companyA) & tbl.itemCode.equals(prodItemCode) & tbl.warehouseId.equals(whA)))
          .getSingle();

      expect(stocks.onHandQty, equals(6.0));
    });

    test('TEST C — SALES RETURN (Reversal of Posting & Stock Balance Recovery)', () async {
      final costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => companyA);
      final postingEngine = PostingEngineImpl(db, costLayerService, null, () => companyA);

      final receiptId = generateUuidV7();
      final line1Id = generateUuidV7();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          id: Value(receiptId),
          receiptNumber: 'REC-003',
          receiptDate: nowMs,
          createdAt: nowMs,
          updatedAt: nowMs,
          status: const Value('draft'),
          currencyCode: 'YER',
          companyId: Value(companyA),
        ),
      );

      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          id: Value(line1Id),
          receiptId: Value(receiptId),
          movementType: 'receipt',
          itemCode: prodItemCode,
          itemName: 'Golden Product',
          quantity: const Value(5.0),
          unitCost: const Value(30.0),
          totalCost: const Value(150.0),
          companyId: companyA,
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-003',
        documentType: InventoryDocumentType.stockReceipt,
        warehouseId: whA,
        currencyCode: 'YER',
        exchangeRate: 1.0,
        documentDate: DateTime.now(),
      );

      await postingEngine.applyInboundPosting(
        document: docRef,
        lines: [
          InboundLineData(
            lineUuid: line1Id,
            itemCode: prodItemCode,
            itemName: 'Golden Product',
            quantity: 5.0,
            unitCost: 30.0,
          ),
        ],
        warehouseId: whA,
        documentDate: DateTime.now(),
      );

      // Execute Reverse Posting
      await postingEngine.reversePosting(document: docRef);

      // Verify Stock Receipt document status reverted to draft
      final receipt = await (db.select(db.stockReceipts)..where((tbl) => tbl.id.equals(receiptId))).getSingle();
      expect(receipt.status, equals('draft'));

      // Verify Stock Ledger deleted
      final ledgers = await (db.select(db.stockMovementLedgers)
            ..where((tbl) => tbl.companyId.equals(companyA) & tbl.sourceDocumentId.equals(receiptId)))
          .get();

      expect(ledgers, isEmpty);
    });

    test('TEST D — CROSS-TENANT ATTACK REJECTION', () async {
      final costLayerServiceA = CostLayerServiceImpl(db: db, readCompanyId: () => companyA);
      final postingEngineA = PostingEngineImpl(db, costLayerServiceA, null, () => companyA);

      final receiptId = generateUuidV7();
      final lineId = generateUuidV7();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          id: Value(receiptId),
          receiptNumber: 'REC-004',
          receiptDate: nowMs,
          createdAt: nowMs,
          updatedAt: nowMs,
          status: const Value('draft'),
          currencyCode: 'YER',
          companyId: Value(companyA),
        ),
      );

      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          id: Value(lineId),
          receiptId: Value(receiptId),
          movementType: 'receipt',
          itemCode: prodItemCode,
          itemName: 'Golden Product',
          quantity: const Value(5.0),
          unitCost: const Value(20.0),
          totalCost: const Value(100.0),
          companyId: companyA,
        ),
      );

      // Attempt posting with Warehouse B belonging to Company B -> MUST BE REJECTED
      expect(
        () => postingEngineA.applyInboundPosting(
          document: InventoryDocumentRef(
            documentId: receiptId,
            documentNumber: 'REC-004',
            documentType: InventoryDocumentType.stockReceipt,
            warehouseId: whB, // Company B warehouse!
            currencyCode: 'YER',
            exchangeRate: 1.0,
            documentDate: DateTime.now(),
          ),
          lines: [
            InboundLineData(
              lineUuid: lineId,
              itemCode: prodItemCode,
              itemName: 'Golden Product',
              quantity: 5.0,
              unitCost: 20.0,
            ),
          ],
          warehouseId: whB,
          documentDate: DateTime.now(),
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('TEST E — MULTI-CURRENCY PURCHASE (20 SAR * 140 YER/SAR = 2800 YER Base Equivalent)', () async {
      final costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => companyA);
      final postingEngine = PostingEngineImpl(db, costLayerService, null, () => companyA);

      final receiptId = generateUuidV7();
      final lineId = generateUuidV7();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          id: Value(receiptId),
          receiptNumber: 'REC-SAR-01',
          receiptDate: nowMs,
          createdAt: nowMs,
          updatedAt: nowMs,
          status: const Value('draft'),
          currencyCode: 'SAR',
          companyId: Value(companyA),
        ),
      );

      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          id: Value(lineId),
          receiptId: Value(receiptId),
          movementType: 'receipt',
          itemCode: prodItemCode,
          itemName: 'Golden Product SAR',
          quantity: const Value(1.0),
          unitCost: const Value(20.0), // 20 SAR
          totalCost: const Value(20.0),
          companyId: companyA,
        ),
      );

      // 20 SAR transaction currency, exchangeRate = 140 YER/SAR
      final totalBaseValue = await postingEngine.applyInboundPosting(
        document: InventoryDocumentRef(
          documentId: receiptId,
          documentNumber: 'REC-SAR-01',
          documentType: InventoryDocumentType.stockReceipt,
          warehouseId: whA,
          currencyCode: 'SAR',
          exchangeRate: 140.0, // 140 YER per 1 SAR
          documentDate: DateTime.now(),
        ),
        lines: [
          InboundLineData(
            lineUuid: lineId,
            itemCode: prodItemCode,
            itemName: 'Golden Product SAR',
            quantity: 1.0,
            unitCost: 20.0,
          ),
        ],
        warehouseId: whA,
        documentDate: DateTime.now(),
      );

      // Expected base total cost = 20 SAR * 140 = 2800 YER
      expect(totalBaseValue, equals(2800.0), reason: '20 SAR @ 140 YER/SAR must equal 2800 YER base cost');

      // Verify cost layer base unit cost & total cost
      final layers = await (db.select(db.inventoryCostLayers)
            ..where((tbl) => tbl.companyId.equals(companyA) & tbl.itemCode.equals(prodItemCode)))
          .get();

      expect(layers.length, equals(1));
      expect(layers.first.unitCost, equals(2800.0));
      expect(layers.first.totalCost, equals(2800.0));
    });
  });
}
