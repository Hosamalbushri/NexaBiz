import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/utils/monetary_precision_utils.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/cost_method_inheritance_resolver_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

void main() {
  late NexabizDatabase db;
  late CostMethodInheritanceResolverImpl resolver;
  late CostLayerServiceImpl costLayerService;

  const companyA = 'COMPANY_ALPHA';
  const warehouse1 = 'WH_MAIN';
  const warehouse2 = 'WH_SECONDARY';
  const itemA = 'ITEM_WIDGET_A';
  const itemB = 'ITEM_WIDGET_B';

  setUp(() async {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    resolver = CostMethodInheritanceResolverImpl(
      db: db,
      systemDefaultMethod: CostValuationMethod.fifo,
    );
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyA,
    );

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Setup Warehouses
    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            uuid: const Value(warehouse1),
            warehouseCode: const Value('WH01'),
            name: const Value('Main Warehouse'),
            companyId: const Value(companyA),
            costValuationMethod: const Value('lifo'),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await db
        .into(db.warehouses)
        .insert(
          WarehousesCompanion(
            uuid: const Value(warehouse2),
            warehouseCode: const Value('WH02'),
            name: const Value('Secondary Warehouse'),
            companyId: const Value(companyA),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
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
            unit: const Value('PCS'),
            costValuationMethod: const Value('lifo'),
            companyId: const Value(companyA),
            onHandQty: const Value(0.0),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await db
        .into(db.products)
        .insert(
          ProductsCompanion(
            uuid: Value(generateUuidV4()),
            itemCode: const Value(itemB),
            name: const Value('Widget B (Standard)'),
            unit: const Value('PCS'),
            companyId: const Value(companyA),
            onHandQty: const Value(0.0),
            createdAt: Value(now),
            updatedAt: Value(now),
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

    test('3. FIFO / WAC Cost Layer Management via Canonical CostLayerService', () async {
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

      // Consuming 5 units under LIFO should consume from Layer 2 (@ 20.0)
      final res = await costLayerService.consumeLayers(
        itemCode: itemA,
        quantity: 5.0,
        method: CostValuationMethod.lifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'stock_issue',
        companyId: companyA,
      );

      expect(res.consumptions.length, equals(1));
      expect(res.consumptions.first.unitCost, equals(20.0));
      expect(res.consumptions.first.totalCost, equals(100.0));
    });

    test('4. Costing Policy Change Does Not Revalue Historical Layers', () async {
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
    });
  });
}
