import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/company/functional_currency_service.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/inventory/cost_valuation/data/services/inventory_cost_calculator_impl.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/inventory_valuation_currency_service.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/currency/domain/entities/currency_rate.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> testBox;
  late SettingsRepository settingsRepo;
  late AccountingDatabase accDb;
  late InventoryDatabase invDb;
  late CurrencyRepositoryImpl currencyRepo;
  late CurrencyRateRepositoryImpl rateRepo;
  late CompanyInitializationRepositoryImpl initRepo;
  late FunctionalCurrencyService functionalCurrencyService;
  late InventoryValuationCurrencyService valuationCurrencyService;
  late CostLayerServiceImpl costLayerService;

  const companyId = 'COMP-TEST-VALUATION-001';

  setUp(() async {
    Hive.init('./test_hive_currency_val');
    testBox = await Hive.openBox<dynamic>('test_settings_val_${DateTime.now().millisecondsSinceEpoch}');
    await testBox.clear();

    settingsRepo = SettingsRepository(box: testBox);
    accDb = AccountingDatabase(executor: NativeDatabase.memory());
    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    currencyRepo = CurrencyRepositoryImpl(accDb, readCompanyId: () => companyId);
    rateRepo = CurrencyRateRepositoryImpl(accDb, readCompanyId: () => companyId);
    initRepo = CompanyInitializationRepositoryImpl(box: testBox);

    functionalCurrencyService = FunctionalCurrencyService(
      settingsRepository: settingsRepo,
      currencyRepository: currencyRepo,
      db: accDb,
    );

    valuationCurrencyService = InventoryValuationCurrencyService(
      functionalCurrencyService: functionalCurrencyService,
      currencyRepository: currencyRepo,
      currencyRateRepository: rateRepo,
      initRepository: initRepo,
    );

    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => companyId,
    );

    // Seed active currencies into master data: YER, SAR, USD
    await currencyRepo.upsert(
      const CurrencyDraft(
        code: 'YER',
        nameAr: 'ريال يمني',
        nameEn: 'Yemeni Rial',
        symbol: 'ر.ي',
        decimalDigits: 2,
        isActive: true,
      ),
    );

    await currencyRepo.upsert(
      const CurrencyDraft(
        code: 'SAR',
        nameAr: 'ريال سعودي',
        nameEn: 'Saudi Riyal',
        symbol: 'ر.س',
        decimalDigits: 2,
        isActive: true,
      ),
    );

    await currencyRepo.upsert(
      const CurrencyDraft(
        code: 'USD',
        nameAr: 'دولار أمريكي',
        nameEn: 'US Dollar',
        symbol: '\$',
        decimalDigits: 2,
        isActive: true,
      ),
    );
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
    await testBox.close();
  });

  group('CURRENCY-03 — Inventory Valuation Currency Behavioral Tests', () {
    test('1. Same currency purchase preserves inventory valuation currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      final layer = CostLayer(
        itemCode: 'ITEM-001',
        warehouseId: 'WH-01',
        movementUuid: '00000000-0000-4000-8000-000000000001',
        movementType: 'receipt',
        receivedDate: DateTime.now().toUtc(),
        receivedQty: 20,
        unitCost: 2000,
        inventoryCurrencyId: 'YER',
        documentCurrencyId: 'YER',
        unitCostDocumentCurrency: 2000,
        exchangeRate: 1.0,
        companyId: companyId,
      );

      await costLayerService.createLayer(layer);
      final layers = await costLayerService.getOpenLayers('ITEM-001', companyId: companyId);

      expect(layers.length, equals(1));
      expect(layers.first.inventoryCurrencyId, equals('YER'));
      expect(layers.first.unitCost, equals(2000));
      expect(layers.first.totalCost, equals(40000));
      expect(layers.first.exchangeRate, equals(1.0));
    });

    test('2. Foreign currency purchase calculates valuation cost in inventory currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      // Purchase: 10 units @ 10 SAR, Exchange Rate: 140 YER/SAR -> 14,000 YER
      const docQty = 10.0;
      const docUnitCost = 10.0; // SAR
      const fxRate = 140.0; // YER/SAR
      const valUnitCost = docUnitCost * fxRate; // 1400 YER
      const valTotalCost = docQty * valUnitCost; // 14000 YER

      final layer = CostLayer(
        itemCode: 'ITEM-SAR-01',
        warehouseId: 'WH-01',
        movementUuid: '00000000-0000-4000-8000-000000000002',
        movementType: 'receipt',
        receivedDate: DateTime.now().toUtc(),
        receivedQty: docQty,
        unitCost: valUnitCost,
        totalCost: valTotalCost,
        inventoryCurrencyId: 'YER',
        documentCurrencyId: 'SAR',
        unitCostDocumentCurrency: docUnitCost,
        totalCostDocumentCurrency: docQty * docUnitCost,
        exchangeRate: fxRate,
        companyId: companyId,
      );

      await costLayerService.createLayer(layer);
      final layers = await costLayerService.getOpenLayers('ITEM-SAR-01', companyId: companyId);

      expect(layers.length, equals(1));
      expect(layers.first.inventoryCurrencyId, equals('YER'));
      expect(layers.first.unitCost, equals(1400.0));
      expect(layers.first.totalCost, equals(14000.0));
      expect(layers.first.documentCurrencyId, equals('SAR'));
      expect(layers.first.unitCostDocumentCurrency, equals(10.0));
      expect(layers.first.exchangeRate, equals(140.0));
    });

    test('3. FIFO consumption consumes oldest cost layer first in valuation currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      final t1 = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final t2 = DateTime.now().toUtc().subtract(const Duration(hours: 1));

      // Layer 1: 10 units @ 1000 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'FIFO-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000010',
          movementType: 'receipt',
          receivedDate: t1,
          receivedQty: 10,
          unitCost: 1000,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Layer 2: 10 units @ 2000 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'FIFO-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000011',
          movementType: 'receipt',
          receivedDate: t2,
          receivedQty: 10,
          unitCost: 2000,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Issue 5 units via FIFO
      final result = await costLayerService.consumeLayers(
        itemCode: 'FIFO-ITEM',
        quantity: 5,
        method: CostValuationMethod.fifo,
        issueLineUuid: '00000000-0000-4000-8000-000000000012',
        movementType: 'issue',
        companyId: companyId,
      );

      expect(result.effectiveUnitCost, equals(1000.0));
      expect(result.totalCost, equals(5000.0));
      expect(result.consumptions.length, equals(1));
    });

    test('4. LIFO consumption consumes newest cost layer first in valuation currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      final t1 = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final t2 = DateTime.now().toUtc().subtract(const Duration(hours: 1));

      // Layer 1: 10 units @ 1000 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'LIFO-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000020',
          movementType: 'receipt',
          receivedDate: t1,
          receivedQty: 10,
          unitCost: 1000,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Layer 2: 10 units @ 2000 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'LIFO-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000021',
          movementType: 'receipt',
          receivedDate: t2,
          receivedQty: 10,
          unitCost: 2000,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Issue 5 units via LIFO
      final result = await costLayerService.consumeLayers(
        itemCode: 'LIFO-ITEM',
        quantity: 5,
        method: CostValuationMethod.lifo,
        issueLineUuid: '00000000-0000-4000-8000-000000000022',
        movementType: 'issue',
        companyId: companyId,
      );

      expect(result.effectiveUnitCost, equals(2000.0));
      expect(result.totalCost, equals(10000.0));
    });

    test('5. WAC correctly blends multiple inbound layers in valuation currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      // 20 cartons @ 2,000 YER = 40,000 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'WAC-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000030',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
          receivedQty: 20,
          unitCost: 2000,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // 23 cartons @ 3,000 YER = 69,000 YER
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'WAC-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000031',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          receivedQty: 23,
          unitCost: 3000,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      // Total Qty = 43, Total Cost = 109,000 YER -> WAC = 2534.8837... YER
      final wac = await costLayerService.getWeightedAverageCost('WAC-ITEM', companyId: companyId);
      expect(wac, closeTo(109000 / 43, 0.001));
    });

    test('6. Partial consumption updates remainingQty accurately in valuation currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'PARTIAL-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000040',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc(),
          receivedQty: 100,
          unitCost: 50,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      await costLayerService.consumeLayers(
        itemCode: 'PARTIAL-ITEM',
        quantity: 30,
        method: CostValuationMethod.fifo,
        issueLineUuid: '00000000-0000-4000-8000-000000000041',
        movementType: 'issue',
        companyId: companyId,
      );

      final openLayers = await costLayerService.getOpenLayers('PARTIAL-ITEM', companyId: companyId);
      expect(openLayers.length, equals(1));
      expect(openLayers.first.remainingQty, equals(70.0));
    });

    test('7. Multiple foreign currencies (SAR, USD) convert accurately into valuation currency', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      // Receipt 1: 10 units @ 10 SAR (140 YER/SAR rate) = 14,000 YER (1,400 YER/unit)
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'MULTI-FX-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000050',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
          receivedQty: 10,
          unitCost: 1400,
          inventoryCurrencyId: 'YER',
          documentCurrencyId: 'SAR',
          unitCostDocumentCurrency: 10,
          exchangeRate: 140,
          companyId: companyId,
        ),
      );

      // Receipt 2: 10 units @ 10 USD (530 YER/USD rate) = 53,000 YER (5,300 YER/unit)
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'MULTI-FX-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000051',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          receivedQty: 10,
          unitCost: 5300,
          inventoryCurrencyId: 'YER',
          documentCurrencyId: 'USD',
          unitCostDocumentCurrency: 10,
          exchangeRate: 530,
          companyId: companyId,
        ),
      );

      final openLayers = await costLayerService.getOpenLayers('MULTI-FX-ITEM', companyId: companyId);
      expect(openLayers.length, equals(2));

      final wac = await costLayerService.getWeightedAverageCost('MULTI-FX-ITEM', companyId: companyId);
      // Total Qty = 20, Total Cost = 14,000 + 53,000 = 67,000 YER -> WAC = 3,350 YER
      expect(wac, equals(3350.0));
    });

    test('8. Exchange-rate changes across receipts create distinct valuation layers', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      // Receipt 1: 10 units @ 10 SAR with FX rate 140 = 1,400 YER/unit
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'FX-CHANGE-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000060',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
          receivedQty: 10,
          unitCost: 1400,
          inventoryCurrencyId: 'YER',
          documentCurrencyId: 'SAR',
          exchangeRate: 140,
          companyId: companyId,
        ),
      );

      // Receipt 2: 10 units @ 10 SAR with updated FX rate 145 = 1,450 YER/unit
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'FX-CHANGE-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000061',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          receivedQty: 10,
          unitCost: 1450,
          inventoryCurrencyId: 'YER',
          documentCurrencyId: 'SAR',
          exchangeRate: 145,
          companyId: companyId,
        ),
      );

      final openLayers = await costLayerService.getOpenLayers('FX-CHANGE-ITEM', companyId: companyId);
      expect(openLayers[0].exchangeRate, equals(140.0));
      expect(openLayers[1].exchangeRate, equals(145.0));

      final wac = await costLayerService.getWeightedAverageCost('FX-CHANGE-ITEM', companyId: companyId);
      expect(wac, equals(1425.0));
    });

    test('9. No valuation currency configured -> throws CurrencyRequiredException', () async {
      final repo = CurrencyRepositoryImpl(accDb, readCompanyId: () => 'COMP-EMPTY-CURR');
      await repo.setDefaultCurrency('');

      expect(
        () async => await valuationCurrencyService.getValuationCurrency('COMP-EMPTY-CURR'),
        throwsA(isA<CurrencyRequiredException>()),
      );
    });

    test('10. Invalid valuation currency code -> throws InvalidFunctionalCurrencyException', () async {
      expect(
        () async => await functionalCurrencyService.setFunctionalCurrency('XYZ_NON_EXISTENT', 'COMP-INVALID-CURR'),
        throwsA(isA<InvalidFunctionalCurrencyException>()),
      );
    });

    test('11. Inactive valuation currency -> throws InvalidFunctionalCurrencyException', () async {
      final repo = CurrencyRepositoryImpl(accDb, readCompanyId: () => 'COMP-INACTIVE-CURR');
      await repo.upsert(
        const CurrencyDraft(
          code: 'INR',
          nameAr: 'روبية هندية',
          nameEn: 'Indian Rupee',
          symbol: '₹',
          decimalDigits: 2,
          isActive: false,
        ),
      );

      final svc = FunctionalCurrencyService(
        settingsRepository: settingsRepo,
        currencyRepository: repo,
        db: accDb,
      );

      expect(
        () async => await svc.setFunctionalCurrency('INR', 'COMP-INACTIVE-CURR'),
        throwsA(isA<InvalidFunctionalCurrencyException>()),
      );
    });

    test('12. Restart persistence preserves valuation layer calculations', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'PERSIST-ITEM',
          movementUuid: '00000000-0000-4000-8000-000000000070',
          movementType: 'receipt',
          receivedDate: DateTime.now().toUtc(),
          receivedQty: 50,
          unitCost: 1200,
          inventoryCurrencyId: 'YER',
          documentCurrencyId: 'SAR',
          exchangeRate: 140,
          companyId: companyId,
        ),
      );

      // Simulate Service restart with same backing DB
      final restartedCostLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => companyId,
      );

      final openLayers = await restartedCostLayerService.getOpenLayers('PERSIST-ITEM', companyId: companyId);
      expect(openLayers.length, equals(1));
      expect(openLayers.first.inventoryCurrencyId, equals('YER'));
      expect(openLayers.first.unitCost, equals(1200.0));
      expect(openLayers.first.remainingQty, equals(50.0));
    });

    test('13. Inventory currency differs from functional currency WITHOUT FX rate -> throws CurrencyRateRequiredException', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      // Set inventory valuation currency to SAR (different from functional currency YER)
      await initRepo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: companyId,
          inventoryBaseCurrencyId: 'SAR',
        ),
      );

      // No exchange rate for SAR exists in rateRepo
      expect(
        () async => await valuationCurrencyService.getValuationCurrency(companyId),
        throwsA(isA<CurrencyRateRequiredException>()),
      );
    });

    test('14. Inventory currency differs from functional currency WITH valid FX rate -> succeeds', () async {
      await functionalCurrencyService.setFunctionalCurrency('YER', companyId);

      // Set inventory valuation currency to SAR
      await initRepo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: companyId,
          inventoryBaseCurrencyId: 'SAR',
        ),
      );

      // Upsert exchange rate for SAR in rateRepo (1 SAR = 140 YER)
      await rateRepo.upsert(
        const CurrencyRateDraft(
          currencyCode: 'SAR',
          rateToBase: 140.0,
        ),
      );

      final valCurrency = await valuationCurrencyService.getValuationCurrency(companyId);
      expect(valCurrency.code, equals('SAR'));
    });
  });
}
