import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/utils/monetary_precision_utils.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/cost_method_inheritance_resolver_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/inventory_cost_calculator_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

void main() {
  late InventoryDatabase db;
  late CostMethodInheritanceResolverImpl resolver;
  late CostLayerServiceImpl costLayerService;
  late InventoryCostCalculatorImpl costCalculator;

  const companyA = 'COMPANY_ALPHA';
  const warehouse1 = 'WH_MAIN';
  const warehouse2 = 'WH_SECONDARY';
  const itemA = 'ITEM_WIDGET_A';
  const itemB = 'ITEM_WIDGET_B';

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    resolver = CostMethodInheritanceResolverImpl(
      db: db,
      systemDefaultMethod: CostValuationMethod.fifo,
    );
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyA,
    );
    costCalculator = InventoryCostCalculatorImpl(
      inheritanceResolver: resolver,
      costLayerService: costLayerService,
    );

    // Setup Warehouses
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            uuid: const Value(warehouse1),
            code: const Value('WH01'),
            name: const Value('Main Warehouse'),
            companyId: const Value(companyA),
            costValuationMethod: const Value('lifo'),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            uuid: const Value(warehouse2),
            code: const Value('WH02'),
            name: const Value('Secondary Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(true),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Setup Categories
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion(
            uuid: const Value('CAT_ELECTRONICS'),
            code: const Value('CAT01'),
            name: const Value('Electronics'),
            warehouseId: const Value(''),
            companyId: const Value(companyA),
            costValuationMethod: const Value('weighted_average'),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    // Setup Products
    await db
        .into(db.products)
        .insert(
          ProductsCompanion(
            uuid: Value(generateUuidV4()),
            itemCode: const Value(itemA),
            name: const Value('Widget A (Product Override LIFO)'),
            packSize: const Value(1),
            price: const Value(100.0),
            costValuationMethod: const Value('lifo'),
            companyId: const Value(companyA),
            onHandQty: const Value(0.0),
            createdAt: Value(DateTime.now().millisecondsSinceEpoch),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    await db
        .into(db.products)
        .insert(
          ProductsCompanion(
            uuid: Value(generateUuidV4()),
            itemCode: const Value(itemB),
            name: const Value('Widget B (Category Inherited WAVG)'),
            packSize: const Value(1),
            price: const Value(50.0),
            categoryId: const Value('CAT_ELECTRONICS'),
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

  group('Phase IN-06: Inventory Costing Architecture & Scope Tests', () {
    test(
      '1. Policy Inheritance Resolution (Product -> Category -> Warehouse -> System)',
      () async {
        // Item A has product override: LIFO
        final resA = await resolver.resolveForProduct(
          itemCode: itemA,
          warehouseId: warehouse2,
          companyId: companyA,
        );
        expect(resA.effectiveMethod, equals(CostValuationMethod.lifo));
        expect(resA.source, equals(CostMethodSource.product));

        // Item B inherits from Category 'CAT_ELECTRONICS': Weighted Average
        final resB = await resolver.resolveForProduct(
          itemCode: itemB,
          warehouseId: warehouse2,
          companyId: companyA,
        );
        expect(
          resB.effectiveMethod,
          equals(CostValuationMethod.weightedAverage),
        );
        expect(resB.source, equals(CostMethodSource.category));

        // Uncategorized item with no product override in Warehouse 1: inherits Warehouse LIFO
        final resWH = await resolver.resolveForProduct(
          itemCode: 'UNSET_ITEM',
          warehouseId: warehouse1,
          companyId: companyA,
        );
        expect(resWH.effectiveMethod, equals(CostValuationMethod.lifo));
        expect(resWH.source, equals(CostMethodSource.warehouse));

        // Uncategorized item in Warehouse 2 (no warehouse override): System default FIFO
        final resSys = await resolver.resolveForProduct(
          itemCode: 'UNSET_ITEM',
          warehouseId: warehouse2,
          companyId: companyA,
        );
        expect(resSys.effectiveMethod, equals(CostValuationMethod.fifo));
        expect(resSys.source, equals(CostMethodSource.system));
      },
    );

    test('2. Monetary Precision & Residual Allocation', () {
      final total = 100.0;
      final quantities = [33.333, 33.333, 33.334];

      final allocations = MonetaryPrecisionUtils.allocateCostProportionally(
        totalCost: total,
        quantities: quantities,
      );

      final sum = allocations.fold<double>(0.0, (a, b) => a + b);
      expect(MonetaryPrecisionUtils.roundTotal(sum), equals(100.0));
      expect(allocations.length, equals(3));
    });

    test(
      '3. Zero-Cost Receipt Rejection vs Explicit Business Policy Override',
      () async {
        final docDate = DateTime.utc(2026, 9, 6);

        // Should throw StateError when allowZeroCost = false and unitCost = 0.0
        expect(
          () => costCalculator.calculateReceiptCost(
            companyId: companyA,
            warehouseId: warehouse1,
            itemCode: itemA,
            quantity: 10.0,
            unitCost: 0.0,
            documentDate: docDate,
            allowZeroCost: false,
          ),
          throwsA(isA<StateError>()),
        );

        // Should succeed when allowZeroCost = true
        final res = await costCalculator.calculateReceiptCost(
          companyId: companyA,
          warehouseId: warehouse1,
          itemCode: itemA,
          quantity: 10.0,
          unitCost: 0.0,
          documentDate: docDate,
          allowZeroCost: true,
        );

        expect(res.unitCost, equals(0.0));
        expect(res.totalCost, equals(0.0));
      },
    );

    test('4. FIFO vs LIFO Cost Consumption Calculations', () async {
      final docDate = DateTime.utc(2026, 9, 6);

      // Create Layer 1: 10 units @ 10.0
      await costLayerService.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: itemA,
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: docDate.subtract(const Duration(days: 2)),
          receivedQty: 10.0,
          unitCost: 10.0,
          totalCost: 100.0,
          companyId: companyA,
        ),
      );

      // Create Layer 2: 10 units @ 20.0
      await costLayerService.createLayer(
        CostLayer(
          id: generateUuidV4(),
          itemCode: itemA,
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: docDate.subtract(const Duration(days: 1)),
          receivedQty: 10.0,
          unitCost: 20.0,
          totalCost: 200.0,
          companyId: companyA,
        ),
      );

      // Item A resolves to LIFO (product override).
      // Consuming 5 units under LIFO should consume from Layer 2 (@ 20.0)
      final issueRes = await costCalculator.calculateIssueCost(
        companyId: companyA,
        warehouseId: warehouse1,
        itemCode: itemA,
        quantity: 5.0,
        documentDate: docDate,
      );

      expect(issueRes.method, equals(CostValuationMethod.lifo));
      expect(issueRes.totalCost, equals(100.0)); // 5 * 20.0
      expect(issueRes.consumedLayers.length, equals(1));
      expect(issueRes.consumedLayers.first.unitCost, equals(20.0));
    });

    test('5. Costing Policy Change Does Not Revalue Historical Layers', () async {
      final docDate = DateTime.utc(2026, 9, 6);

      // Create Layer at 50.0 unit cost under LIFO
      final layerId = generateUuidV4();
      await costLayerService.createLayer(
        CostLayer(
          id: layerId,
          itemCode: itemA,
          movementUuid: generateUuidV4(),
          movementType: 'stock_receipt',
          receivedDate: docDate,
          receivedQty: 10.0,
          unitCost: 50.0,
          totalCost: 500.0,
          companyId: companyA,
        ),
      );

      // Update Product A costing policy to FIFO
      await (db.update(db.products)..where((p) => p.itemCode.equals(itemA)))
          .write(const ProductsCompanion(costValuationMethod: Value('fifo')));

      // Verify historical layer unitCost remains untouched @ 50.0
      final layers = await costLayerService.getOpenLayers(itemA);
      final layer = layers.firstWhere((l) => l.id == layerId);
      expect(layer.unitCost, equals(50.0));
      expect(layer.totalCost, equals(500.0));

      // Verify new issue uses new effective method (FIFO) but consumes unchanged historical layer unitCost
      final newIssue = await costCalculator.calculateIssueCost(
        companyId: companyA,
        warehouseId: warehouse1,
        itemCode: itemA,
        quantity: 2.0,
        documentDate: docDate,
      );

      expect(newIssue.method, equals(CostValuationMethod.fifo));
      expect(newIssue.unitCost, equals(50.0));
      expect(newIssue.totalCost, equals(100.0));
    });
  });
}
