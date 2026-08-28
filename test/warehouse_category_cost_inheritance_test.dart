import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/cost_method_inheritance_resolver_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:drift/drift.dart';

void main() {
  late InventoryDatabase db;
  late CostMethodInheritanceResolverImpl resolver;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;

  setUp(() {
    db = InventoryDatabase.memory();
    resolver = CostMethodInheritanceResolverImpl(
      db: db,
      systemDefaultMethod: CostValuationMethod.weightedAverage,
    );
    costLayerService = CostLayerServiceImpl(db: db);
    postingEngine = PostingEngineImpl(db, costLayerService, resolver);
  });

  tearDown(() async {
    await db.close();
  });

  group('Warehouse-Rooted Category Tree & Cost Method Inheritance Tests', () {
    test('Priority 5: System Default is resolved when no overrides exist',
        () async {
      // Create warehouse with null cost method
      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value('wh-sanaa'),
              code: const Value('WH-SANAA'),
              name: const Value('Sana\'a Warehouse'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Create product with no category and null cost method
      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111101'),
              itemCode: const Value('ITEM-001'),
              name: const Value('Product 1'),
              packSize: const Value(1),
              price: const Value(100.0),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      final result = await resolver.resolveForProduct(
        itemCode: 'ITEM-001',
        warehouseId: 'wh-sanaa',
      );

      expect(result.effectiveMethod, equals(CostValuationMethod.weightedAverage));
      expect(result.source, equals(CostMethodSource.system));
    });

    test('Priority 4: Warehouse Override takes precedence over System Default',
        () async {
      // Warehouse with FIFO override
      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value('wh-sanaa'),
              code: const Value('WH-SANAA'),
              name: const Value('Sana\'a Warehouse'),
              costValuationMethod: const Value('fifo'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111102'),
              itemCode: const Value('ITEM-001'),
              name: const Value('Product 1'),
              packSize: const Value(1),
              price: const Value(100.0),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      final result = await resolver.resolveForProduct(
        itemCode: 'ITEM-001',
        warehouseId: 'wh-sanaa',
      );

      expect(result.effectiveMethod, equals(CostValuationMethod.fifo));
      expect(result.source, equals(CostMethodSource.warehouse));
      expect(result.resolvedEntityId, equals('wh-sanaa'));
    });

    test(
        'Priority 3 & 2: Parent and Child Category Hierarchy Cost Method Overrides',
        () async {
      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value('wh-sanaa'),
              code: const Value('WH-SANAA'),
              name: const Value('Sana\'a Warehouse'),
              costValuationMethod: const Value('fifo'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Root Category: Food (no cost method override -> null)
      await db.into(db.categories).insert(
            CategoriesCompanion(
              uuid: const Value('cat-food'),
              code: const Value('FOOD'),
              name: const Value('Food'),
              warehouseId: const Value('wh-sanaa'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Child Category: Drinks (no override -> null)
      await db.into(db.categories).insert(
            CategoriesCompanion(
              uuid: const Value('cat-drinks'),
              code: const Value('DRINKS'),
              name: const Value('Drinks'),
              warehouseId: const Value('wh-sanaa'),
              parentId: const Value('cat-food'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Grandchild Category: Juices (LIFO override)
      await db.into(db.categories).insert(
            CategoriesCompanion(
              uuid: const Value('cat-juices'),
              code: const Value('JUICES'),
              name: const Value('Juices'),
              warehouseId: const Value('wh-sanaa'),
              parentId: const Value('cat-drinks'),
              costValuationMethod: const Value('lifo'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Product X in Drinks category (inherits Warehouse FIFO because Drinks and Food have null overrides)
      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111103'),
              itemCode: const Value('ITEM-DRINK'),
              name: const Value('Soft Drink'),
              categoryId: const Value('cat-drinks'),
              packSize: const Value(1),
              price: const Value(50.0),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Product Y in Juices category (overridden by Juices category -> LIFO)
      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111104'),
              itemCode: const Value('ITEM-JUICE'),
              name: const Value('Orange Juice'),
              categoryId: const Value('cat-juices'),
              packSize: const Value(1),
              price: const Value(80.0),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      final drinkResult = await resolver.resolveForProduct(
        itemCode: 'ITEM-DRINK',
        warehouseId: 'wh-sanaa',
      );
      expect(drinkResult.effectiveMethod, equals(CostValuationMethod.fifo));
      expect(drinkResult.source, equals(CostMethodSource.warehouse));

      final juiceResult = await resolver.resolveForProduct(
        itemCode: 'ITEM-JUICE',
        warehouseId: 'wh-sanaa',
      );
      expect(juiceResult.effectiveMethod, equals(CostValuationMethod.lifo));
      expect(juiceResult.source, equals(CostMethodSource.category));
      expect(juiceResult.resolvedEntityId, equals('cat-juices'));
    });

    test(
        'Priority 1: Product Override takes highest precedence over Category, Warehouse, and System',
        () async {
      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value('wh-sanaa'),
              code: const Value('WH-SANAA'),
              name: const Value('Sana\'a Warehouse'),
              costValuationMethod: const Value('fifo'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion(
              uuid: const Value('cat-juices'),
              code: const Value('JUICES'),
              name: const Value('Juices'),
              warehouseId: const Value('wh-sanaa'),
              costValuationMethod: const Value('lifo'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Product with direct Weighted Average override
      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111105'),
              itemCode: const Value('ITEM-SPECIAL'),
              name: const Value('Special Mango Juice'),
              categoryId: const Value('cat-juices'),
              costValuationMethod: const Value('weightedAverage'),
              packSize: const Value(1),
              price: const Value(120.0),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      final result = await resolver.resolveForProduct(
        itemCode: 'ITEM-SPECIAL',
        warehouseId: 'wh-sanaa',
      );

      expect(result.effectiveMethod, equals(CostValuationMethod.weightedAverage));
      expect(result.source, equals(CostMethodSource.product));
      expect(result.resolvedEntityId, equals('11111111-1111-1111-1111-111111111105'));
    });

    test(
        'PostingEngine applies LIFO consumption when category override dictates LIFO',
        () async {
      const whId = 'wh-sanaa';
      const itemCode = 'ITEM-JUICE';

      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value(whId),
              code: const Value('WH-SANAA'),
              name: const Value('Sana\'a Warehouse'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion(
              uuid: const Value('cat-juices'),
              code: const Value('JUICES'),
              name: const Value('Juices'),
              warehouseId: const Value(whId),
              costValuationMethod: const Value('lifo'),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      await db.into(db.products).insert(
            ProductsCompanion(
              uuid: const Value('11111111-1111-1111-1111-111111111106'),
              itemCode: const Value(itemCode),
              name: const Value('Fresh Juice'),
              categoryId: const Value('cat-juices'),
              packSize: const Value(1),
              price: const Value(100.0),
              createdAt: Value(DateTime.now().millisecondsSinceEpoch),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

      // Inbound receipt 1: 10 units @ 100 base currency (earlier date)
      final doc1 = InventoryDocumentRef(
        documentId: '22222222-2222-2222-2222-222222222201',
        documentType: InventoryDocumentType.stockReceipt,
        documentNumber: 'REC-001',
        warehouseId: whId,
        documentDate: DateTime.utc(2026, 1, 1),
      );
      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333301'),
              movementUuid: const Value('22222222-2222-2222-2222-222222222201'),
              movementType: const Value('stock_receipt'),
              itemCode: const Value(itemCode),
              itemName: const Value('Fresh Juice'),
              quantity: const Value(10.0),
              unitCost: const Value(100.0),
              totalCost: const Value(1000.0),
            ),
          );
      await postingEngine.applyInboundPosting(
        document: doc1,
        lines: [
          const InboundLineData(
            lineUuid: '33333333-3333-3333-3333-333333333301',
            itemCode: itemCode,
            itemName: 'Fresh Juice',
            quantity: 10.0,
            unitCost: 100.0,
          )
        ],
        warehouseId: whId,
        documentDate: doc1.documentDate,
      );

      // Inbound receipt 2: 10 units @ 200 base currency (later date)
      final doc2 = InventoryDocumentRef(
        documentId: '22222222-2222-2222-2222-222222222202',
        documentType: InventoryDocumentType.stockReceipt,
        documentNumber: 'REC-002',
        warehouseId: whId,
        documentDate: DateTime.utc(2026, 1, 10),
      );
      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333302'),
              movementUuid: const Value('22222222-2222-2222-2222-222222222202'),
              movementType: const Value('stock_receipt'),
              itemCode: const Value(itemCode),
              itemName: const Value('Fresh Juice'),
              quantity: const Value(10.0),
              unitCost: const Value(200.0),
              totalCost: const Value(2000.0),
            ),
          );
      await postingEngine.applyInboundPosting(
        document: doc2,
        lines: [
          const InboundLineData(
            lineUuid: '33333333-3333-3333-3333-333333333302',
            itemCode: itemCode,
            itemName: 'Fresh Juice',
            quantity: 10.0,
            unitCost: 200.0,
          )
        ],
        warehouseId: whId,
        documentDate: doc2.documentDate,
      );

      // Outbound issue: 5 units. Since Juices category uses LIFO, newest layer (@ 200) must be consumed first!
      final issueDoc = InventoryDocumentRef(
        documentId: '22222222-2222-2222-2222-222222222203',
        documentType: InventoryDocumentType.stockIssue,
        documentNumber: 'ISS-001',
        warehouseId: whId,
        documentDate: DateTime.utc(2026, 1, 15),
      );
      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: const Value('33333333-3333-3333-3333-333333333303'),
              movementUuid: const Value('22222222-2222-2222-2222-222222222203'),
              movementType: const Value('stock_issue'),
              itemCode: const Value(itemCode),
              itemName: const Value('Fresh Juice'),
              quantity: const Value(5.0),
            ),
          );

      final totalCogs = await postingEngine.applyOutboundPosting(
        document: issueDoc,
        lines: [
          const OutboundLineData(
            lineUuid: '33333333-3333-3333-3333-333333333303',
            itemCode: itemCode,
            itemName: 'Fresh Juice',
            quantity: 5.0,
          )
        ],
        warehouseId: whId,
        valuationMethod: CostValuationMethod.fifo, // Should be overridden by resolver to LIFO
      );

      expect(totalCogs, equals(1000.0)); // 5 units * 200 = 1000 total COGS under LIFO
    });
  });
}
