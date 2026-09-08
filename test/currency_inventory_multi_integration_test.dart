import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/inventory_cost_calculator_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

class MockInheritanceResolver implements CostMethodInheritanceResolver {
  MockInheritanceResolver(this.method);
  final CostValuationMethod method;

  @override
  Future<EffectiveCostMethodResult> resolveForProduct({
    required String itemCode,
    required String? warehouseId,
    String? companyId,
  }) async {
    return EffectiveCostMethodResult(
      effectiveMethod: method,
      source: CostMethodSource.product,
    );
  }

  @override
  Future<EffectiveCostMethodResult> resolveForCategory({
    required String categoryId,
    String? companyId,
  }) async {
    return EffectiveCostMethodResult(
      effectiveMethod: method,
      source: CostMethodSource.category,
    );
  }

  @override
  Future<EffectiveCostMethodResult> resolveForWarehouse({
    required String warehouseId,
    String? companyId,
  }) async {
    return EffectiveCostMethodResult(
      effectiveMethod: method,
      source: CostMethodSource.warehouse,
    );
  }

  @override
  CostValuationMethod getSystemDefaultCostMethod() => method;
}

void main() {
  group('CURRENCY-08 — Inventory and Multi-Currency Integration Tests', () {
    late InventoryDatabase invDb;
    late CostLayerServiceImpl costLayerService;
    const companyId = 'COMP-CURRENCY-08';
    const warehouseId = 'WH-MAIN';
    const itemCode = 'ITEM-1001';

    setUp(() async {
      invDb = InventoryDatabase(executor: NativeDatabase.memory());
      costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => companyId,
      );
    });

    tearDown(() async {
      await invDb.close();
    });

    test('1. YER purchase / YER sale scenario in valuation currency', () async {
      final calculator = InventoryCostCalculatorImpl(
        inheritanceResolver: MockInheritanceResolver(CostValuationMethod.fifo),
        costLayerService: costLayerService,
      );

      // Inbound Purchase: 10 units @ 1,400 YER (rate = 1.0)
      final receipt = await calculator.calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 10.0,
        unitCost: 1400.0,
        documentDate: DateTime.utc(2026, 1, 10),
        exchangeRate: 1.0,
      );

      expect(receipt.totalCost, equals(14000.0));
      expect(receipt.unitCost, equals(1400.0));

      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 10),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Outbound Sale: 1 unit sold @ 2,000 YER
      final issue = await calculator.calculateIssueCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 1.0,
        documentDate: DateTime.utc(2026, 1, 12),
      );

      expect(issue.totalCost, equals(1400.0));
      expect(issue.unitCost, equals(1400.0));
    });

    test('2. SAR purchase into YER inventory valuation currency', () async {
      final calculator = InventoryCostCalculatorImpl(
        inheritanceResolver: MockInheritanceResolver(CostValuationMethod.fifo),
        costLayerService: costLayerService,
      );

      // Purchase: 10 units @ 10 SAR each, Exchange Rate = 140 YER/SAR
      // Total Cost in YER = 10 * 10 * 140 = 14,000 YER
      // Unit Cost in YER = 1,400 YER
      final receipt = await calculator.calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 10.0,
        unitCost: 10.0,
        exchangeRate: 140.0,
        documentDate: DateTime.utc(2026, 1, 10),
      );

      expect(receipt.unitCost, equals(1400.0));
      expect(receipt.totalCost, equals(14000.0));

      // Supplier Liability: 100 SAR (14,000 YER equivalent)
      final supplierLine = JournalLineDraft(
        accountUuid: 'acc_supplier',
        debit: 0.0,
        credit: 100.0,
        currencyCode: 'SAR',
        exchangeRateToBase: 140.0,
        baseCredit: 14000.0,
      );

      expect(supplierLine.credit, equals(100.0));
      expect(supplierLine.baseCredit, equals(14000.0));
    });

    test('3. USD purchase into YER inventory valuation currency', () async {
      final calculator = InventoryCostCalculatorImpl(
        inheritanceResolver: MockInheritanceResolver(CostValuationMethod.fifo),
        costLayerService: costLayerService,
      );

      // Purchase: 10 units @ 20 USD each, Exchange Rate = 375 YER/USD
      // Total Cost in YER = 10 * 20 * 375 = 75,000 YER
      // Unit Cost in YER = 7,500 YER
      final receipt = await calculator.calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 10.0,
        unitCost: 20.0,
        exchangeRate: 375.0,
        documentDate: DateTime.utc(2026, 1, 15),
      );

      expect(receipt.unitCost, equals(7500.0));
      expect(receipt.totalCost, equals(75000.0));
    });

    test('4. SAR sale with YER COGS & Gross Profit calculation', () async {
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 10),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      final calculator = InventoryCostCalculatorImpl(
        inheritanceResolver: MockInheritanceResolver(CostValuationMethod.fifo),
        costLayerService: costLayerService,
      );

      // Sale: 1 unit @ 20 SAR, Exchange Rate = 150 YER/SAR
      // Revenue Equivalent = 20 SAR * 150 = 3,000 YER
      const salePriceSar = 20.0;
      const exchangeRate = 150.0;
      final revenueYer = salePriceSar * exchangeRate; // 3,000 YER

      final issue = await calculator.calculateIssueCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 1.0,
        documentDate: DateTime.utc(2026, 1, 15),
      );

      // COGS remains strictly in YER valuation currency (1,400 YER), NOT converted to SAR!
      final cogsYer = issue.totalCost;
      expect(cogsYer, equals(1400.0));

      final grossProfitYer = revenueYer - cogsYer;
      expect(grossProfitYer, equals(1600.0));
    });

    test('5. Changing exchange rates across multiple purchase receipts', () async {
      final calculator = InventoryCostCalculatorImpl(
        inheritanceResolver: MockInheritanceResolver(CostValuationMethod.weightedAverage),
        costLayerService: costLayerService,
      );

      // Receipt 1: 10 units @ 10 SAR @ 140 YER/SAR = 14,000 YER
      final r1 = await calculator.calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 10.0,
        unitCost: 10.0,
        exchangeRate: 140.0,
        documentDate: DateTime.utc(2026, 1, 1),
      );
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10.0,
          unitCost: r1.unitCost,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Receipt 2: 10 units @ 10 SAR @ 150 YER/SAR = 15,000 YER
      final r2 = await calculator.calculateReceiptCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 10.0,
        unitCost: 10.0,
        exchangeRate: 150.0,
        documentDate: DateTime.utc(2026, 1, 5),
      );
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 5),
          receivedQty: 10.0,
          unitCost: r2.unitCost,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // WAC Unit Cost = (14,000 + 15,000) / 20 = 1,450 YER
      final wacUnitCost = await costLayerService.getWeightedAverageCost(itemCode, companyId: companyId);
      expect(wacUnitCost, equals(1450.0));
    });

    test('6. Partial consumption of cost layer', () async {
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Issue 4 units
      final issueResult = await costLayerService.consumeLayers(
        itemCode: itemCode,
        quantity: 4.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        companyId: companyId,
      );

      expect(issueResult.totalCost, equals(5600.0)); // 4 * 1,400 YER

      // Remaining 6 units @ 1,400 YER = 8,400 YER valuation
      final openLayers = await costLayerService.getOpenLayers(itemCode, companyId: companyId);
      expect(openLayers.length, equals(1));
      expect(openLayers.first.remainingQty, equals(6.0));
      final remainingValuation = openLayers.first.remainingQty * openLayers.first.unitCost;
      expect(remainingValuation, equals(8400.0));
    });

    test('7. FIFO consumption order in valuation currency', () async {
      // Layer 1 (Jan 1): 10 units @ 1,400 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Layer 2 (Jan 5): 10 units @ 1,500 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 5),
          receivedQty: 10.0,
          unitCost: 1500.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // FIFO issue 10 units -> uses Layer 1 (1,400 YER unit cost = 14,000 YER)
      final fifoResult = await costLayerService.consumeLayers(
        itemCode: itemCode,
        quantity: 10.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        companyId: companyId,
      );

      expect(fifoResult.effectiveUnitCost, equals(1400.0));
      expect(fifoResult.totalCost, equals(14000.0));
    });

    test('8. LIFO consumption order in valuation currency', () async {
      // Layer 1 (Jan 1): 10 units @ 1,400 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Layer 2 (Jan 5): 10 units @ 1,500 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 5),
          receivedQty: 10.0,
          unitCost: 1500.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // LIFO issue 10 units -> uses Layer 2 (1,500 YER unit cost = 15,000 YER)
      final lifoResult = await costLayerService.consumeLayers(
        itemCode: itemCode,
        quantity: 10.0,
        method: CostValuationMethod.lifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
        companyId: companyId,
      );

      expect(lifoResult.effectiveUnitCost, equals(1500.0));
      expect(lifoResult.totalCost, equals(15000.0));
    });

    test('9. Returns, Adjustments, and Write-Offs in valuation currency', () async {
      final calculator = InventoryCostCalculatorImpl(
        inheritanceResolver: MockInheritanceResolver(CostValuationMethod.fifo),
        costLayerService: costLayerService,
      );

      // Sales Return: Inbound 2 units @ 1,400 YER valuation cost
      final salesReturn = await calculator.calculateReturnCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 2.0,
        isSalesReturn: true,
        unitCost: 1400.0,
        documentDate: DateTime.utc(2026, 1, 15),
      );
      expect(salesReturn.totalCost, equals(2800.0));

      // Positive Stock Adjustment: Inbound 5 units @ 1,400 YER
      final adjustmentInc = await calculator.calculateAdjustmentCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 5.0,
        isIncrease: true,
        unitCost: 1400.0,
        documentDate: DateTime.utc(2026, 1, 16),
      );
      expect(adjustmentInc.totalCost, equals(7000.0));

      // Add layer for write-off test
      await costLayerService.createLayer(
        CostLayer(
          itemCode: itemCode,
          warehouseId: warehouseId,
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 1),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Inventory Write-Off: Outbound 3 units @ 1,400 YER
      final writeOff = await calculator.calculateIssueCost(
        companyId: companyId,
        warehouseId: warehouseId,
        itemCode: itemCode,
        quantity: 3.0,
        documentDate: DateTime.utc(2026, 1, 20),
      );
      expect(writeOff.totalCost, equals(4200.0));
    });
  });
}
