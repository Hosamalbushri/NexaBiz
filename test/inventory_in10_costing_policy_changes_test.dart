import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/cost_method_inheritance_resolver_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_ledger_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

class MockInventoryDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async => [];
}

class TrackingAccountingPoster implements InventoryAccountingPoster {
  final List<Map<String, dynamic>> postedEntries = [];

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
    });
  }

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

void main() {
  late InventoryDatabase db;
  late StockValidationServiceImpl validationService;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl coordinator;
  late InventoryLedgerServiceImpl ledgerService;
  late CostMethodInheritanceResolverImpl resolver;
  late TrackingAccountingPoster accountingPoster;

  const companyId = 'COMP_POLICY_TEST';
  const warehouseA = '00000000-0000-0000-0000-00000000000A';
  const warehouseB = '00000000-0000-0000-0000-00000000000B';
  const productX = 'PROD_POLICY_X';
  const productY = 'PROD_POLICY_Y';

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());

    validationService = StockValidationServiceImpl(db, () => companyId);
    costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => companyId);
    postingEngine = PostingEngineImpl(db, costLayerService, null, () => companyId, null, validationService);
    accountingPoster = TrackingAccountingPoster();

    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: MockInventoryDependencyDetector(),
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );

    ledgerService = InventoryLedgerServiceImpl(db: db);
    resolver = CostMethodInheritanceResolverImpl(
      db: db,
      systemDefaultMethod: CostValuationMethod.weightedAverage,
    );

    // Setup Active Warehouse A (Override: FIFO)
    await db.into(db.warehouses).insert(
      WarehousesCompanion(
        uuid: const Value(warehouseA),
        code: const Value('WHA'),
        name: const Value('Warehouse Alpha'),
        costValuationMethod: const Value('fifo'),
        companyId: const Value(companyId),
        isActive: const Value(true),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Setup Active Warehouse B (Override: WAC)
    await db.into(db.warehouses).insert(
      WarehousesCompanion(
        uuid: const Value(warehouseB),
        code: const Value('WHB'),
        name: const Value('Warehouse Beta'),
        costValuationMethod: const Value('weightedAverage'),
        companyId: const Value(companyId),
        isActive: const Value(true),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Setup Product X (Override: LIFO)
    await db.into(db.products).insert(
      ProductsCompanion(
        uuid: Value(generateUuidV4()),
        itemCode: const Value(productX),
        name: const Value('Product X'),
        packSize: const Value(1),
        price: const Value(100.0),
        costValuationMethod: const Value('lifo'),
        companyId: const Value(companyId),
        onHandQty: const Value(0.0),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Setup Product Y (No Product Override)
    await db.into(db.products).insert(
      ProductsCompanion(
        uuid: Value(generateUuidV4()),
        itemCode: const Value(productY),
        name: const Value('Product Y'),
        packSize: const Value(1),
        price: const Value(150.0),
        costValuationMethod: const Value(null),
        companyId: const Value(companyId),
        onHandQty: const Value(0.0),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase IN-10: Costing Policy Scope, Overrides & Safe Method Changes', () {
    test('1. Hierarchy Precedence (Company WAC -> Warehouse FIFO -> Product LIFO)', () async {
      // Product X has Product Override = LIFO -> MUST resolve to LIFO
      final resX = await resolver.resolveForProduct(
        itemCode: productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );
      expect(resX.effectiveMethod, equals(CostValuationMethod.lifo));
      expect(resX.source, equals(CostMethodSource.product));

      // Product Y has NO Product Override -> Inherits from Warehouse A = FIFO
      final resY = await resolver.resolveForProduct(
        itemCode: productY,
        warehouseId: warehouseA,
        companyId: companyId,
      );
      expect(resY.effectiveMethod, equals(CostValuationMethod.fifo));
      expect(resY.source, equals(CostMethodSource.warehouse));

      // Product Y in Warehouse without override -> System Fallback = WAC
      final resYDefault = await resolver.resolveForProduct(
        itemCode: productY,
        warehouseId: null,
        companyId: companyId,
      );
      expect(resYDefault.effectiveMethod, equals(CostValuationMethod.weightedAverage));
      expect(resYDefault.source, equals(CostMethodSource.system));
    });

    test('2. Warehouse Costing Method Isolation (Warehouse A FIFO vs Warehouse B WAC)', () async {
      // Product Y in Warehouse A (FIFO) vs Warehouse B (WAC)
      final resA = await resolver.resolveForProduct(
        itemCode: productY,
        warehouseId: warehouseA,
        companyId: companyId,
      );
      final resB = await resolver.resolveForProduct(
        itemCode: productY,
        warehouseId: warehouseB,
        companyId: companyId,
      );

      expect(resA.effectiveMethod, equals(CostValuationMethod.fifo));
      expect(resB.effectiveMethod, equals(CostValuationMethod.weightedAverage));
    });

    test('3. Product Costing Method Isolation in Same Warehouse', () async {
      // Same Warehouse B: Product X (LIFO) vs Product Y (Inherited WAC)
      final resX = await resolver.resolveForProduct(
        itemCode: productX,
        warehouseId: warehouseB,
        companyId: companyId,
      );
      final resY = await resolver.resolveForProduct(
        itemCode: productY,
        warehouseId: warehouseB,
        companyId: companyId,
      );

      expect(resX.effectiveMethod, equals(CostValuationMethod.lifo));
      expect(resY.effectiveMethod, equals(CostValuationMethod.weightedAverage));
    });

    test('4. Product + Warehouse Tier 1 Explicit Override Isolation', () async {
      resolver.registerProductWarehouseOverride(
        itemCode: productX,
        warehouseId: warehouseA,
        method: CostValuationMethod.lifo,
      );
      resolver.registerProductWarehouseOverride(
        itemCode: productX,
        warehouseId: warehouseB,
        method: CostValuationMethod.fifo,
      );

      final resA = await resolver.resolveForProduct(
        itemCode: productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );
      final resB = await resolver.resolveForProduct(
        itemCode: productX,
        warehouseId: warehouseB,
        companyId: companyId,
      );

      expect(resA.effectiveMethod, equals(CostValuationMethod.lifo));
      expect(resA.source, equals(CostMethodSource.productWarehouse));

      expect(resB.effectiveMethod, equals(CostValuationMethod.fifo));
      expect(resB.source, equals(CostMethodSource.productWarehouse));
    });

    test('5. Mandatory Scenario: Costing method change preserves historical COGS & uses new policy for future transactions', () async {
      // 1. Receipt 1: 100 @ 10
      final rec1Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec1Id),
          receiptNumber: const Value('REC-MAN-1'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyId),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec1Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X'),
          quantity: const Value(100.0),
          unitCost: const Value(10.0),
          totalCost: const Value(1000.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec1Id,
          documentNumber: 'REC-MAN-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 3)),
          warehouseId: warehouseA,
        ),
      );

      // 2. Receipt 2: 100 @ 20
      final rec2Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec2Id),
          receiptNumber: const Value('REC-MAN-2'),
          receiptDate: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyId),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec2Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X'),
          quantity: const Value(100.0),
          unitCost: const Value(20.0),
          totalCost: const Value(2000.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec2Id,
          documentNumber: 'REC-MAN-2',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().subtract(const Duration(days: 2)),
          warehouseId: warehouseA,
        ),
      );

      // 3. Under WAC (Moving Average = 15.0), Issue 100 units -> COGS = 1500
      final issue1Id = generateUuidV4();
      final line1Id = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(line1Id),
          movementUuid: Value(issue1Id),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X'),
          quantity: const Value(100.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final wacValue = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: issue1Id,
          documentNumber: 'ISSUE-WAC-100',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now().subtract(const Duration(days: 1)),
          warehouseId: warehouseA,
        ),
        lines: [
          OutboundLineData(
            lineUuid: line1Id,
            itemCode: productX,
            itemName: 'Product X',
            quantity: 100.0,
          ),
        ],
        warehouseId: warehouseA,
        valuationMethod: CostValuationMethod.weightedAverage,
      );

      // Under WAC: 100 units @ 15.0 = 1500.0
      expect(wacValue, equals(1500.0));

      // 4. NOW CHANGE FUTURE COSTING POLICY TO FIFO
      resolver.registerProductWarehouseOverride(
        itemCode: productX,
        warehouseId: warehouseA,
        method: CostValuationMethod.fifo,
      );

      // 5. VERIFY HISTORICAL ISSUE REMAINS 1500.0 IN DATABASE LEDGER
      final ledgerEntries = await ledgerService.getLedgerEntriesForDocument(
        companyId: companyId,
        documentId: issue1Id,
      );
      expect(ledgerEntries.length, equals(1));
      expect(ledgerEntries.first.totalCost, equals(1500.0)); // 100% UNTOUCHED HISTORICAL COGS!

      // 6. Post Receipt 3: 100 @ 30 under new policy
      final rec3Id = generateUuidV4();
      await db.into(db.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: Value(rec3Id),
          receiptNumber: const Value('REC-MAN-3'),
          receiptDate: Value(DateTime.now().millisecondsSinceEpoch),
          status: const Value('draft'),
          companyId: const Value(companyId),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(generateUuidV4()),
          movementUuid: Value(rec3Id),
          movementType: const Value('receipt'),
          itemCode: const Value(productX),
          itemName: const Value('Product X'),
          quantity: const Value(100.0),
          unitCost: const Value(30.0),
          totalCost: const Value(3000.0),
        ),
      );
      await coordinator.post(
        document: InventoryDocumentRef(
          documentId: rec3Id,
          documentNumber: 'REC-MAN-3',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
      );

      // 7. Post Issue 2 under new policy (FIFO) for 100 units
      // Remaining layers before Issue 2:
      // - Receipt 1: 50 units @ 10.0 remaining ($500)
      // - Receipt 2: 50 units @ 20.0 remaining ($1000)
      // - Receipt 3: 100 units @ 30.0 remaining ($3000)
      // FIFO consumption of 100 units = 50 * 10 + 50 * 20 = 1500.0
      final issue2Id = generateUuidV4();
      final line2Id = generateUuidV4();
      await db.into(db.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: Value(line2Id),
          movementUuid: Value(issue2Id),
          movementType: const Value('issue'),
          itemCode: const Value(productX),
          itemName: const Value('Product X'),
          quantity: const Value(100.0),
          unitCost: const Value(0.0),
          totalCost: const Value(0.0),
        ),
      );

      final effectivePolicy = await resolver.resolveForProduct(
        itemCode: productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );

      final fifoValue = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: issue2Id,
          documentNumber: 'ISSUE-FIFO-100',
          documentType: InventoryDocumentType.salesInvoice,
          documentDate: DateTime.now(),
          warehouseId: warehouseA,
        ),
        lines: [
          OutboundLineData(
            lineUuid: line2Id,
            itemCode: productX,
            itemName: 'Product X',
            quantity: 100.0,
          ),
        ],
        warehouseId: warehouseA,
        valuationMethod: effectivePolicy.effectiveMethod,
      );

      // New issue uses FIFO method (50 * 10 + 50 * 20 = 1500.0)
      expect(fifoValue, equals(1500.0));

      // Historical issue #1 is STILL 1500.0
      final histEntries = await ledgerService.getLedgerEntriesForDocument(
        companyId: companyId,
        documentId: issue1Id,
      );
      expect(histEntries.first.totalCost, equals(1500.0));
    });
  });
}
