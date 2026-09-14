import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late InventoryDependencyDetectorImpl dependencyDetector;

  const testCompanyId = 'COMPANY_001';
  final warehouseId = generateUuidV4();

  setUp(() async {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => testCompanyId,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => testCompanyId,
    );
    dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => testCompanyId,
    );

    // Insert test warehouse into in-memory database
    await db.into(db.warehouses).insert(
          WarehousesCompanion.insert(
            id: Value(warehouseId),
            code: 'MAIN',
            name: 'Main Warehouse',
            companyId: testCompanyId,
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('applyInboundPosting creates cost layers and updates product warehouse stock', () async {
    final docId = generateUuidV4();
    final lineId = generateUuidV4();

    await db.into(db.stockMovementLines).insert(
          StockMovementLinesCompanion.insert(
            uuid: lineId,
            receiptId: docId,
            movementType: 'stock_receipt',
            itemCode: 'ITEM_A',
            itemName: 'Item A',
            quantity: const Value(100.0),
            unitCost: const Value(10.0),
            totalCost: const Value(1000.0),
          ),
        );

    final doc = InventoryDocumentRef(
      documentId: docId,
      documentNumber: 'REC-001',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.now(),
      warehouseId: warehouseId,
      status: InventoryDocumentStatus.draft,
    );

    final lines = <InboundLineData>[
      InboundLineData(
        lineUuid: lineId,
        itemCode: 'ITEM_A',
        itemName: 'Item A',
        quantity: 100.0,
        unitCost: 10.0,
      ),
    ];

    final totalValue = await postingEngine.applyInboundPosting(
      document: doc,
      lines: lines,
      warehouseId: warehouseId,
      documentDate: DateTime.now(),
    );

    expect(totalValue, equals(1000.0));

    final layers = await (db.select(db.inventoryCostLayers)
          ..where((l) => l.itemCode.equals('ITEM_A') & l.companyId.equals(testCompanyId)))
        .get();
    expect(layers.length, equals(1));
    expect(layers.first.receivedQty, equals(100.0));

    final wac = await costLayerService.getWeightedAverageCost(
      'ITEM_A',
      companyId: testCompanyId,
    );
    expect(wac, equals(10.0));
  });

  test('reversePosting removes cost effects and recalculates stock balance from valid posted history without reversal entries', () async {
    final docId = generateUuidV4();
    final lineId = generateUuidV4();

    await db.into(db.stockMovementLines).insert(
          StockMovementLinesCompanion.insert(
            uuid: lineId,
            receiptId: docId,
            movementType: 'stock_receipt',
            itemCode: 'ITEM_B',
            itemName: 'Item B',
            quantity: const Value(50.0),
            unitCost: const Value(20.0),
            totalCost: const Value(1000.0),
          ),
        );

    final doc = InventoryDocumentRef(
      documentId: docId,
      documentNumber: 'REC-002',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.now(),
      warehouseId: warehouseId,
      status: InventoryDocumentStatus.draft,
    );

    final lines = <InboundLineData>[
      InboundLineData(
        lineUuid: lineId,
        itemCode: 'ITEM_B',
        itemName: 'Item B',
        quantity: 50.0,
        unitCost: 20.0,
      ),
    ];

    await postingEngine.applyInboundPosting(
      document: doc,
      lines: lines,
      warehouseId: warehouseId,
      documentDate: DateTime.now(),
    );

    final postedDoc = InventoryDocumentRef(
      documentId: docId,
      documentNumber: 'REC-002',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.now(),
      warehouseId: warehouseId,
      status: InventoryDocumentStatus.posted,
    );

    await postingEngine.reversePosting(document: postedDoc);

    // Verify cost layers are soft-deleted / reversed
    final activeLayers = await (db.select(db.inventoryCostLayers)
          ..where(
            (l) =>
                l.itemCode.equals('ITEM_B') &
                l.companyId.equals(testCompanyId) &
                l.deletedAt.isNull(),
          ))
        .get();
    expect(activeLayers.isEmpty, isTrue);

    // Verify stock balance was recalculated to 0
    final whStock = await (db.select(db.productWarehouseStocks)
          ..where(
            (w) =>
                w.itemCode.equals('ITEM_B') &
                w.warehouseId.equals(warehouseId) &
                w.companyId.equals(testCompanyId),
          ))
        .getSingleOrNull();
    expect(whStock?.onHandQty ?? 0.0, equals(0.0));

    // Verify NO reversal ledger entries exist
    final reversals = await (db.select(db.stockMovementLedgers)
          ..where((l) => l.movementType.equals('reversal')))
        .get();
    expect(reversals.isEmpty, isTrue);
  });
}
