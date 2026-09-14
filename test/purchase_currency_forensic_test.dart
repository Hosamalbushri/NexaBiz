import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/currency/domain/entities/currency.dart';
import 'package:stock_count/modules/currency/domain/services/functional_currency_service.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/app/inventory/inventory_accounting_poster_adapter.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'helpers/journal_posting_test_helper.dart';

class FakeCompanyInitRepoForForensic implements CompanyInitializationRepository {
  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async {
    return CompanyInventoryConfig(
      companyId: LocalAuthDefaults.companyId,
      inventoryBaseCurrencyId: 'YER',
    );
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async {
    return const CompanyAccountingConfig(
      companyId: LocalAuthDefaults.companyId,
      accountMappings: {
        AccountRole.inventory: '1200',
        AccountRole.payable: '2100',
        AccountRole.cogs: '5100',
      },
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFunctionalCurrencyServiceForForensic implements FunctionalCurrencyService {
  @override
  Future<Currency> getFunctionalCurrency([String? companyId]) async {
    return Currency(
      id: 'yer-uuid',
      code: 'YER',
      nameAr: 'ريال يمني',
      nameEn: 'Yemeni Rial',
      symbol: 'YER',
      decimalDigits: 2,
      isDefault: true,
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase inventoryDb;
  late NexabizDatabase accountingDb;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late PostingCoordinatorImpl postingCoordinator;
  late InventoryAccountingPosterAdapter adapterPoster;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forensic_purchase_');
    Hive.init(tempDir.path);

    inventoryDb = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();

    accountRepo = AccountRepositoryImpl(accountingDb, readCompanyId: () => LocalAuthDefaults.companyId);
    await accountRepo.seedDefaultChart();
    await accountRepo.ensureDefaultChartSeeded();

    final validator = legacyPeriodValidator();

    journalRepo = JournalRepositoryImpl(
      accountingDb,
      accounts: accountRepo,
      periodValidator: validator,
      readCompanyId: () => LocalAuthDefaults.companyId,
    );

    journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: validator,
    );

    adapterPoster = InventoryAccountingPosterAdapter(
      accountingDb,
      journalPostingService: journalPostingService,
      readCompanyId: () => LocalAuthDefaults.companyId,
      initRepository: FakeCompanyInitRepoForForensic(),
      functionalCurrencyService: FakeFunctionalCurrencyServiceForForensic(),
    );

    final validationService = StockValidationServiceImpl(inventoryDb, () => LocalAuthDefaults.companyId);
    final dependencyDetector = InventoryDependencyDetectorImpl(inventoryDb);
    final costLayerService = CostLayerServiceImpl(db: inventoryDb, readCompanyId: () => LocalAuthDefaults.companyId);
    final postingEngine = PostingEngineImpl(inventoryDb, costLayerService);

    postingCoordinator = PostingCoordinatorImpl(
      db: inventoryDb,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      accountingPoster: adapterPoster,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => LocalAuthDefaults.companyId,
    );
  });

  tearDown(() async {
    await inventoryDb.close();
    await accountingDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FORENSIC AUDIT: Purchase Order -> Inventory Costing -> GL Journal Posting', () {
    test('Forensic test of Purchase Receipt in SAR (Rate 140 YER/SAR) via PostingCoordinator', () async {
      // Setup Purchase / Receipt parameters as specified in CURRENCY-PURCHASE-FORENSIC-01:
      // Item quantity = 1
      // Item unit cost = 20 SAR
      // Exchange rate = 140 YER/SAR
      // Correct inventory valuation cost = 2,800 YER
      
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 0. Seed Warehouse
      await inventoryDb.into(inventoryDb.warehouses).insert(
        WarehousesCompanion.insert(
          id: warehouseId,
          code: 'WH-01',
          name: 'Main Warehouse',
          createdAt: now,
          updatedAt: now,
          companyId: Value(LocalAuthDefaults.companyId),
          isActive: const Value(true),
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'PO-SAR-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 140.0,
      );

      // 1. Seed database tables for StockReceipt and StockMovementLine
      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-SAR-01',
          itemName: 'Forensic Test Item SAR',
          quantity: const Value(1.0),
          unitCost: const Value(20.0), // 20 SAR
          totalCost: const Value(20.0), // 20 SAR
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'PO-SAR-001',
          receiptDate: DateTime.utc(2026, 9, 7).millisecondsSinceEpoch,
          currencyCode: 'SAR',
          exchangeRate: const Value(140.0),
          warehouse: Value(warehouseId),
          status: const Value('draft'),
          createdAt: now,
          updatedAt: now,
          companyId: Value(LocalAuthDefaults.companyId),
        ),
      );

      // 2. Execute Posting via PostingCoordinatorImpl
      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      // 3. Inspect Cost Layer valuation
      final layers = await inventoryDb.select(inventoryDb.inventoryCostLayers).get();
      expect(layers.length, equals(1));
      final costLayer = layers.first;
      
      print('=== FORENSIC EVIDENCE: INVENTORY COST LAYER ===');
      print('Cost Layer Unit Cost (YER): ${costLayer.unitCost}');
      print('Cost Layer Total Cost (YER): ${costLayer.totalCost}');

      // 4. Inspect Accounting Journal Entry & Lines created by InventoryAccountingPosterAdapter
      final journalEntry = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptId,
      );
      expect(journalEntry, isNotNull);

      print('=== FORENSIC EVIDENCE: JOURNAL ENTRY & LINES ===');
      print('Journal Entry Header Currency: ${journalEntry!.currencyCode}');

      for (final line in journalEntry.lines) {
        print('Line Account: ${line.accountId}');
        print('  - Line Currency: ${line.currencyCode}');
        print('  - Debit: ${line.debit}');
        print('  - Credit: ${line.credit}');
        print('  - Base Debit: ${line.baseDebit}');
        print('  - Base Credit: ${line.baseCredit}');
        print('  - Exchange Rate to Base: ${line.exchangeRateToBase}');
      }

      final inventoryLine = journalEntry.lines.firstWhere((l) => l.debit > 0);
      final payableLine = journalEntry.lines.firstWhere((l) => l.credit > 0);

      print('=== FORENSIC AUDIT VERDICT ===');
      print('Expected Inventory GL Debit: 2,800 YER');
      print('Actual Inventory GL Debit: ${inventoryLine.debit} ${inventoryLine.currencyCode}');
      print('Actual Inventory GL Base Debit: ${inventoryLine.baseDebit} YER');
      print('Expected Supplier GL Credit: 20 SAR');
      print('Actual Supplier GL Credit: ${payableLine.credit} ${payableLine.currencyCode}');
      print('Actual Supplier GL Base Credit: ${payableLine.baseCredit} YER');

      if (inventoryLine.debit == 392000.0) {
        print('🚨 CONFIRMED DEFECT: DOUBLE CONVERSION (20 SAR * 140 -> 2,800 * 140 = 392,000 YER)');
      }
    });
  });
}
