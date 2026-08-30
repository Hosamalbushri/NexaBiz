import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late String currentTenant;

  setUp(() {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    currentTenant = 'company_alpha';
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => currentTenant,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => currentTenant,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedProductAndInbound({
    required String itemCode,
    required String warehouseId,
    required double qty,
    required double unitCost,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.products).insert(
          ProductsCompanion(
            uuid: Value(generateUuidV4()),
            itemCode: Value(itemCode),
            name: Value('Test Product $itemCode'),
            packSize: const Value(1),
            price: Value(unitCost),
            onHandQty: const Value(0.0),
            unitCost: Value(unitCost),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: Value(currentTenant),
          ),
        );

    final docRef = InventoryDocumentRef(
      documentId: generateUuidV4(),
      documentNumber: 'REC-001',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.now(),
      warehouseId: warehouseId,
    );

    final lineUuid = generateUuidV4();
    await db.into(db.stockMovementLines).insert(
          StockMovementLinesCompanion(
            uuid: Value(lineUuid),
            movementUuid: Value(docRef.documentId),
            movementType: const Value('stock_receipt'),
            itemCode: Value(itemCode),
            itemName: Value('Test Item $itemCode'),
            quantity: Value(qty),
            unitCost: Value(unitCost),
          ),
        );

    await postingEngine.applyInboundPosting(
      document: docRef,
      lines: [
        InboundLineData(
          lineUuid: lineUuid,
          itemCode: itemCode,
          itemName: 'Test Item $itemCode',
          quantity: qty,
          unitCost: unitCost,
        ),
      ],
      warehouseId: warehouseId,
      documentDate: DateTime.now(),
    );
  }

  group('ROOT FIX 08 — Inventory Quantity Integrity (Remove Silent Clamping)', () {
    test('1. Explicit Rejection on Shortage: 5 Available vs 10 Requested throws JournalException and leaves stock at 5', () async {
      currentTenant = 'company_alpha';
      const itemCode = 'ITEM-SHORT-01';
      const warehouseId = 'WH-MAIN';

      // Seed 5 units
      await seedProductAndInbound(
        itemCode: itemCode,
        warehouseId: warehouseId,
        qty: 5.0,
        unitCost: 10.0,
      );

      // Attempt to post Stock Issue requesting 10 units
      final issueDocId = generateUuidV4();
      final issueDocRef = InventoryDocumentRef(
        documentId: issueDocId,
        documentNumber: 'ISS-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: warehouseId,
      );

      final lineUuid = generateUuidV4();
      await db.into(db.stockIssues).insert(
            StockIssuesCompanion(
              uuid: Value(issueDocId),
              issueNumber: const Value('ISS-001'),
              status: Value(InventoryDocumentStatus.draft.name),
              issueDate: Value(DateTime.now().millisecondsSinceEpoch),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              companyId: Value(currentTenant),
            ),
          );

      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(lineUuid),
              movementUuid: Value(issueDocId),
              movementType: const Value('stock_issue'),
              itemCode: Value(itemCode),
              itemName: Value('Test Item $itemCode'),
              quantity: const Value(10.0),
              unitCost: const Value(10.0),
            ),
          );

      // Attempt posting outbound issue
      expect(
        () async => await postingEngine.applyOutboundPosting(
          document: issueDocRef,
          lines: [
            OutboundLineData(
              lineUuid: lineUuid,
              itemCode: itemCode,
              itemName: 'Test Item $itemCode',
              quantity: 10.0,
            ),
          ],
          warehouseId: warehouseId,
          valuationMethod: CostValuationMethod.fifo,
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            equals(JournalException.insufficientStock),
          ),
        ),
      );

      // Verify stock in product table remains 5.0 (NOT clamped to 0.0!)
      final prod = await (db.select(db.products)
            ..where((p) => p.itemCode.equals(itemCode)))
          .getSingle();
      expect(prod.onHandQty, equals(5.0));

      // Verify warehouse stock remains 5.0
      final whStock = await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals(itemCode) & w.warehouseId.equals(warehouseId)))
          .getSingle();
      expect(whStock.onHandQty, equals(5.0));

      // Verify document status remains draft
      final issueDoc = await (db.select(db.stockIssues)
            ..where((i) => i.uuid.equals(issueDocId)))
          .getSingle();
      expect(issueDoc.status, equals(InventoryDocumentStatus.draft.name));
      expect(issueDoc.postedAt, isNull);
    });

    test('2. Concurrent Outbound Requests: Concurrent requests (7.0 & 7.0) on 10.0 available stock -> 1 succeeds, 1 rejected', () async {
      currentTenant = 'company_alpha';
      const itemCode = 'ITEM-CONC-SHORT';
      const warehouseId = 'WH-MAIN';

      await seedProductAndInbound(
        itemCode: itemCode,
        warehouseId: warehouseId,
        qty: 10.0,
        unitCost: 15.0,
      );

      final lineA = generateUuidV4();
      final lineB = generateUuidV4();

      final docA = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'ISS-002',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: warehouseId,
      );

      final docB = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'ISS-003',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: warehouseId,
      );

      Future<Object?> runPost(InventoryDocumentRef doc, String lineUuid, String name) async {
        try {
          return await postingEngine.applyOutboundPosting(
            document: doc,
            lines: [OutboundLineData(lineUuid: lineUuid, itemCode: itemCode, itemName: name, quantity: 7.0)],
            warehouseId: warehouseId,
            valuationMethod: CostValuationMethod.fifo,
          );
        } catch (e) {
          return e;
        }
      }

      final results = await Future.wait<Object?>([
        runPost(docA, lineA, 'Item A'),
        runPost(docB, lineB, 'Item B'),
      ]);

      // Exactly one succeeds (returns double), and one throws JournalException.insufficientStock
      final successCount = results.whereType<double>().length;
      final errorCount = results.whereType<JournalException>().where((e) => e.code == JournalException.insufficientStock).length;

      expect(successCount, equals(1));
      expect(errorCount, equals(1));

      // Final stock in product table MUST be 3.0 (10 - 7 = 3)
      final prod = await (db.select(db.products)
            ..where((p) => p.itemCode.equals(itemCode)))
          .getSingle();
      expect(prod.onHandQty, equals(3.0));
    });

    test('3. Transfer Shortage Rejection: Attempting transfer out exceeding warehouse stock is rejected', () async {
      currentTenant = 'company_alpha';
      const itemCode = 'ITEM-TR-SHORT';
      const fromWh = 'WH-SOURCE';
      const toWh = 'WH-DEST';

      // Seed 4.0 units in WH-SOURCE
      await seedProductAndInbound(
        itemCode: itemCode,
        warehouseId: fromWh,
        qty: 4.0,
        unitCost: 20.0,
      );

      final transferDocRef = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'TR-001',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: DateTime.now(),
        warehouseId: fromWh,
      );

      final lineUuid = generateUuidV4();

      expect(
        () async => await postingEngine.applyTransferPosting(
          document: transferDocRef,
          lines: [TransferLineData(lineUuid: lineUuid, itemCode: itemCode, itemName: 'Transfer Item', quantity: 10.0)],
          fromWarehouseId: fromWh,
          toWarehouseId: toWh,
          valuationMethod: CostValuationMethod.fifo,
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            equals(JournalException.insufficientStock),
          ),
        ),
      );

      // Verify zero stock created in destination warehouse
      final destWhStocks = await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals(itemCode) & w.warehouseId.equals(toWh)))
          .get();
      expect(destWhStocks.isEmpty, isTrue);

      // Source stock remains 4.0
      final sourceWhStock = await (db.select(db.productWarehouseStocks)
            ..where((w) => w.itemCode.equals(itemCode) & w.warehouseId.equals(fromWh)))
          .getSingle();
      expect(sourceWhStock.onHandQty, equals(4.0));
    });
  });
}
