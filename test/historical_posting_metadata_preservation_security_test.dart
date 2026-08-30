import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
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

  group('ROOT FIX 09 — Historical Posting Metadata Preservation', () {
    test('1. Inbound Receipt Reversal: Original postedCost and postedAt on movement lines remain intact after reversal', () async {
      currentTenant = 'company_alpha';
      const itemCode = 'ITEM-HIST-REC';
      const warehouseId = 'WH-MAIN';
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: Value(generateUuidV4()),
              itemCode: const Value(itemCode),
              name: const Value('Test Item Hist Rec'),
              packSize: const Value(1),
              price: const Value(50.0),
              onHandQty: const Value(0.0),
              unitCost: const Value(50.0),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
              companyId: Value(currentTenant),
            ),
          );

      final recId = generateUuidV4();
      final lineId = generateUuidV4();

      await db.into(db.stockReceipts).insert(
            StockReceiptsCompanion(
              uuid: Value(recId),
              receiptNumber: const Value('REC-HIST-01'),
              status: Value(InventoryDocumentStatus.draft.name),
              receiptDate: Value(nowMs),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
              companyId: Value(currentTenant),
            ),
          );

      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(lineId),
              movementUuid: Value(recId),
              movementType: const Value('stock_receipt'),
              itemCode: const Value(itemCode),
              itemName: const Value('Test Item Hist Rec'),
              quantity: const Value(10.0),
              unitCost: const Value(50.0),
            ),
          );

      final receiptDocRef = InventoryDocumentRef(
        documentId: recId,
        documentNumber: 'REC-HIST-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: now,
        warehouseId: warehouseId,
      );

      // Post the receipt
      await postingEngine.applyInboundPosting(
        document: receiptDocRef,
        lines: [
          InboundLineData(
            lineUuid: lineId,
            itemCode: itemCode,
            itemName: 'Test Item Hist Rec',
            quantity: 10.0,
            unitCost: 50.0,
          ),
        ],
        warehouseId: warehouseId,
        documentDate: now,
      );

      // Verify line has postedCost and postedAt
      var lineAfterPost = await (db.select(db.stockMovementLines)
            ..where((tbl) => tbl.uuid.equals(lineId)))
          .getSingle();
      expect(lineAfterPost.postedCost, equals(50.0));
      expect(lineAfterPost.postedAt, isNotNull);
      final originalPostedAt = lineAfterPost.postedAt;

      // Reverse posting
      await postingEngine.reversePosting(document: receiptDocRef);

      // Verify original line postedCost and postedAt remain PRESERVED (NOT set to null / absent!)
      var lineAfterReversal = await (db.select(db.stockMovementLines)
            ..where((tbl) => tbl.uuid.equals(lineId)))
          .getSingle();
      expect(lineAfterReversal.postedCost, equals(50.0));
      expect(lineAfterReversal.postedAt, equals(originalPostedAt));
    });

    test('2. Outbound Issue Reversal: Original line postedCost and postedAt preserved during unposting', () async {
      currentTenant = 'company_alpha';
      const itemCode = 'ITEM-HIST-ISS';
      const warehouseId = 'WH-MAIN';
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      // Seed 20 units
      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: Value(generateUuidV4()),
              itemCode: const Value(itemCode),
              name: const Value('Test Item Hist Iss'),
              packSize: const Value(1),
              price: const Value(100.0),
              onHandQty: const Value(0.0),
              unitCost: const Value(100.0),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
              companyId: Value(currentTenant),
            ),
          );

      final recId = generateUuidV4();
      final recLineId = generateUuidV4();
      final recDocRef = InventoryDocumentRef(
        documentId: recId,
        documentNumber: 'REC-HIST-02',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: now,
        warehouseId: warehouseId,
      );

      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(recLineId),
              movementUuid: Value(recId),
              movementType: const Value('stock_receipt'),
              itemCode: const Value(itemCode),
              itemName: const Value('Test Item Hist Iss'),
              quantity: const Value(20.0),
              unitCost: const Value(100.0),
            ),
          );

      await postingEngine.applyInboundPosting(
        document: recDocRef,
        lines: [InboundLineData(lineUuid: recLineId, itemCode: itemCode, itemName: 'Test Item Hist Iss', quantity: 20.0, unitCost: 100.0)],
        warehouseId: warehouseId,
        documentDate: now,
      );

      // Post Outbound Issue of 5 units
      final issId = generateUuidV4();
      final issLineId = generateUuidV4();
      final issDocRef = InventoryDocumentRef(
        documentId: issId,
        documentNumber: 'ISS-HIST-01',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: now,
        warehouseId: warehouseId,
      );

      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(issLineId),
              movementUuid: Value(issId),
              movementType: const Value('stock_issue'),
              itemCode: const Value(itemCode),
              itemName: const Value('Test Item Hist Iss'),
              quantity: const Value(5.0),
              unitCost: const Value(100.0),
            ),
          );

      await postingEngine.applyOutboundPosting(
        document: issDocRef,
        lines: [OutboundLineData(lineUuid: issLineId, itemCode: itemCode, itemName: 'Test Item Hist Iss', quantity: 5.0)],
        warehouseId: warehouseId,
        valuationMethod: CostValuationMethod.fifo,
      );

      var issLineAfterPost = await (db.select(db.stockMovementLines)
            ..where((tbl) => tbl.uuid.equals(issLineId)))
          .getSingle();
      expect(issLineAfterPost.postedCost, equals(100.0));
      expect(issLineAfterPost.postedAt, isNotNull);
      final originalIssPostedAt = issLineAfterPost.postedAt;

      // Reverse outbound posting
      await postingEngine.reversePosting(document: issDocRef);

      var issLineAfterReversal = await (db.select(db.stockMovementLines)
            ..where((tbl) => tbl.uuid.equals(issLineId)))
          .getSingle();

      expect(issLineAfterReversal.postedCost, equals(100.0));
      expect(issLineAfterReversal.postedAt, equals(originalIssPostedAt));
    });
  });
}
