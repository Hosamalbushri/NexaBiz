import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerService;
  const String companyId = 'company_a';
  const String warehouseA = 'wh_a';
  const String warehouseB = 'wh_b';
  const String productX = 'PROD_X';

  setUp(() {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('IN-06A Numerical Acceptance Test Scenario (Section 31)', () {
    test('Receipt 1 & Receipt 2 layer valuation in YER', () async {
      // Receipt 1: 100 units @ 10 SAR, FX = 140 YER/SAR -> 1,400 YER/unit, Total = 140,000 YER
      final receipt1Layer = CostLayer(
        id: '11111111-1111-1111-1111-111111111101',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '11111111-1111-1111-1111-111111111102',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 100,
        unitCost: 1400.0, // 10 SAR * 140 YER/SAR
        totalCost: 140000.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1400.0,
        totalCostInventoryCurrency: 140000.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 10.0,
        totalCostDocumentCurrency: 1000.0,
        exchangeRate: 140.0,
        companyId: companyId,
      );
      await costLayerService.createLayer(receipt1Layer);

      // Receipt 2: 100 units @ 12 SAR, FX = 150 YER/SAR -> 1,800 YER/unit, Total = 180,000 YER
      final receipt2Layer = CostLayer(
        id: '11111111-1111-1111-1111-111111111103',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '11111111-1111-1111-1111-111111111104',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 2),
        receivedQty: 100,
        unitCost: 1800.0, // 12 SAR * 150 YER/SAR
        totalCost: 180000.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1800.0,
        totalCostInventoryCurrency: 180000.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 12.0,
        totalCostDocumentCurrency: 1200.0,
        exchangeRate: 150.0,
        companyId: companyId,
      );
      await costLayerService.createLayer(receipt2Layer);

      final openLayers = await costLayerService.getOpenLayers(
        productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );

      expect(openLayers.length, equals(2));
      expect(openLayers[0].unitCostInventoryCurrency, equals(1400.0));
      expect(openLayers[0].totalCostInventoryCurrency, equals(140000.0));
      expect(openLayers[1].unitCostInventoryCurrency, equals(1800.0));
      expect(openLayers[1].totalCostInventoryCurrency, equals(180000.0));
    });

    test('FIFO issue 120 units from Receipt 1 & 2 layers', () async {
      await costLayerService.createLayer(CostLayer(
        id: '22222222-2222-2222-2222-222222222201',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '22222222-2222-2222-2222-222222222202',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 100,
        unitCost: 1400.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1400.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 10.0,
        exchangeRate: 140.0,
        companyId: companyId,
      ));

      await costLayerService.createLayer(CostLayer(
        id: '22222222-2222-2222-2222-222222222203',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '22222222-2222-2222-2222-222222222204',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 2),
        receivedQty: 100,
        unitCost: 1800.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1800.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 12.0,
        exchangeRate: 150.0,
        companyId: companyId,
      ));

      final result = await costLayerService.consumeLayers(
        itemCode: productX,
        quantity: 120,
        method: CostValuationMethod.fifo,
        issueLineUuid: '22222222-2222-2222-2222-222222222205',
        movementType: 'issue',
        warehouseId: warehouseA,
        companyId: companyId,
      );

      // Expected: (100 * 1400) + (20 * 1800) = 140,000 + 36,000 = 176,000 YER
      expect(result.totalCost, equals(176000.0));
      expect(result.effectiveUnitCost, equals(176000.0 / 120.0));
      expect(result.consumptions.length, equals(2));

      // Remaining open layers (80 units @ 1800 YER = 144,000 YER)
      final remainingLayers = await costLayerService.getOpenLayers(
        productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );
      expect(remainingLayers.length, equals(1));
      expect(remainingLayers[0].remainingQty, equals(80.0));
      expect(remainingLayers[0].unitCostInventoryCurrency, equals(1800.0));
    });

    test('LIFO issue 120 units from Receipt 1 & 2 layers', () async {
      await costLayerService.createLayer(CostLayer(
        id: '33333333-3333-3333-3333-333333333301',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '33333333-3333-3333-3333-333333333302',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 100,
        unitCost: 1400.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1400.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 10.0,
        exchangeRate: 140.0,
        companyId: companyId,
      ));

      await costLayerService.createLayer(CostLayer(
        id: '33333333-3333-3333-3333-333333333303',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '33333333-3333-3333-3333-333333333304',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 2),
        receivedQty: 100,
        unitCost: 1800.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1800.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 12.0,
        exchangeRate: 150.0,
        companyId: companyId,
      ));

      final result = await costLayerService.consumeLayers(
        itemCode: productX,
        quantity: 120,
        method: CostValuationMethod.lifo,
        issueLineUuid: '33333333-3333-3333-3333-333333333305',
        movementType: 'issue',
        warehouseId: warehouseA,
        companyId: companyId,
      );

      // Expected LIFO: (100 * 1800) + (20 * 1400) = 180,000 + 28,000 = 208,000 YER
      expect(result.totalCost, equals(208000.0));
      expect(result.effectiveUnitCost, equals(208000.0 / 120.0));
    });

    test('Weighted Average Cost (WAC) average unit cost and 50 units issue', () async {
      await costLayerService.createLayer(CostLayer(
        id: '44444444-4444-4444-4444-444444444401',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '44444444-4444-4444-4444-444444444402',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 100,
        unitCost: 1400.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1400.0,
        companyId: companyId,
      ));

      await costLayerService.createLayer(CostLayer(
        id: '44444444-4444-4444-4444-444444444403',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '44444444-4444-4444-4444-444444444404',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 2),
        receivedQty: 100,
        unitCost: 1800.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1800.0,
        companyId: companyId,
      ));

      final avgCost = await costLayerService.getWeightedAverageCost(
        productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );

      // Expected WAC: (140,000 + 180,000) / 200 = 1,600 YER/unit
      expect(avgCost, equals(1600.0));

      // Issue 50 units
      final result = await costLayerService.consumeLayers(
        itemCode: productX,
        quantity: 50,
        method: CostValuationMethod.weightedAverage,
        issueLineUuid: '44444444-4444-4444-4444-444444444405',
        movementType: 'issue',
        warehouseId: warehouseA,
        companyId: companyId,
      );

      // Expected total cost: 50 * 1600 = 80,000 YER
      expect(result.totalCost, equals(80000.0));
      expect(result.effectiveUnitCost, equals(1600.0));
    });

    test('Historical FX immutability: changing current FX does not affect layer cost', () async {
      final layer = CostLayer(
        id: '55555555-5555-5555-5555-555555555501',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '55555555-5555-5555-5555-555555555502',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 10,
        unitCost: 1400.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1400.0,
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: 10.0,
        exchangeRate: 140.0,
        companyId: companyId,
      );
      await costLayerService.createLayer(layer);

      // Verify stored historical layer unit cost is permanently 1,400 YER
      final openLayers = await costLayerService.getOpenLayers(
        productX,
        warehouseId: warehouseA,
        companyId: companyId,
      );
      expect(openLayers.first.unitCostInventoryCurrency, equals(1400.0));
      expect(openLayers.first.exchangeRate, equals(140.0));

      // Consume stock later when market FX rate is 160 YER/SAR
      final result = await costLayerService.consumeLayers(
        itemCode: productX,
        quantity: 5,
        method: CostValuationMethod.fifo,
        issueLineUuid: '55555555-5555-5555-5555-555555555503',
        movementType: 'issue',
        warehouseId: warehouseA,
        companyId: companyId,
      );

      // Cost MUST still be calculated using the original 1,400 YER cost (not 10 * 160 = 1,600 YER)
      expect(result.totalCost, equals(7000.0));
      expect(result.effectiveUnitCost, equals(1400.0));
    });

    test('Missing and invalid FX validation', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'YER',
          exchangeRate: 0.0,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );

      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'YER',
          exchangeRate: -150.0,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );

      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'YER',
          exchangeRate: null,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );

      expect(
        ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'YER',
          exchangeRate: 145.0,
        ),
        equals(145.0),
      );
    });

    test('Multi-company currency and layer isolation', () async {
      // Company A layer (YER)
      await costLayerService.createLayer(CostLayer(
        id: '66666666-6666-6666-6666-666666666601',
        itemCode: productX,
        warehouseId: warehouseA,
        movementUuid: '66666666-6666-6666-6666-666666666602',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 50,
        unitCost: 1400.0,
        inventoryCurrencyId: 'YER',
        unitCostInventoryCurrency: 1400.0,
        companyId: 'company_a',
      ));

      // Company B layer (EUR)
      await costLayerService.createLayer(CostLayer(
        id: '77777777-7777-7777-7777-777777777701',
        itemCode: productX,
        warehouseId: warehouseB,
        movementUuid: '77777777-7777-7777-7777-777777777702',
        movementType: 'receipt',
        receivedDate: DateTime.utc(2026, 9, 1),
        receivedQty: 50,
        unitCost: 20.0,
        inventoryCurrencyId: 'EUR',
        unitCostInventoryCurrency: 20.0,
        companyId: 'company_b',
      ));

      // Query Company A open layers
      final compALayers = await costLayerService.getOpenLayers(
        productX,
        companyId: 'company_a',
      );
      expect(compALayers.length, equals(1));
      expect(compALayers.first.companyId, equals('company_a'));
      expect(compALayers.first.inventoryCurrencyId, equals('YER'));

      // Query Company B open layers
      final compBLayers = await costLayerService.getOpenLayers(
        productX,
        companyId: 'company_b',
      );
      expect(compBLayers.length, equals(1));
      expect(compBLayers.first.companyId, equals('company_b'));
      expect(compBLayers.first.inventoryCurrencyId, equals('EUR'));
    });
  });
}
