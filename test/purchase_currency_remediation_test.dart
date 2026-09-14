import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
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

class FakeCompanyInitRepoForRemediation implements CompanyInitializationRepository {
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

class FakeFunctionalCurrencyServiceForRemediation implements FunctionalCurrencyService {
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
    tempDir = await Directory.systemTemp.createTemp('remediation_purchase_');
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
      initRepository: FakeCompanyInitRepoForRemediation(),
      functionalCurrencyService: FakeFunctionalCurrencyServiceForRemediation(),
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

  group('CURRENCY-PURCHASE-FIX-01 Remediation Behavioral Test Matrix', () {
    test('TEST 1 — Same Currency Purchase (20 YER @ 1.0)', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-YER-01',
          itemName: 'Same Currency Item YER',
          quantity: const Value(1.0),
          unitCost: const Value(20.0),
          totalCost: const Value(20.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-YER-001',
          receiptDate: DateTime.utc(2026, 9, 7).millisecondsSinceEpoch,
          currencyCode: 'YER',
          exchangeRate: const Value(1.0),
          warehouse: Value(warehouseId),
          status: const Value('draft'),
          createdAt: now,
          updatedAt: now,
          companyId: Value(LocalAuthDefaults.companyId),
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-YER-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'YER',
        exchangeRate: 1.0,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      final journalEntry = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptId,
      );
      expect(journalEntry, isNotNull);
      expect(journalEntry!.lines.length, equals(2));

      final invLine = journalEntry.lines.firstWhere((l) => l.debit > 0);
      final suppLine = journalEntry.lines.firstWhere((l) => l.credit > 0);

      expect(invLine.currencyCode, equals('YER'));
      expect(invLine.debit, equals(20.0));
      expect(invLine.baseDebit, equals(20.0));

      expect(suppLine.currencyCode, equals('YER'));
      expect(suppLine.credit, equals(20.0));
      expect(suppLine.baseCredit, equals(20.0));
    });

    test('TEST 2 — Foreign Purchase (20 SAR @ 140 YER/SAR)', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-SAR-01',
          itemName: 'Foreign Item SAR',
          quantity: const Value(1.0),
          unitCost: const Value(20.0),
          totalCost: const Value(20.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-SAR-002',
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

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-SAR-002',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 140.0,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      final journalEntry = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptId,
      );
      expect(journalEntry, isNotNull);

      final invLine = journalEntry!.lines.firstWhere((l) => l.debit > 0);
      final suppLine = journalEntry.lines.firstWhere((l) => l.credit > 0);

      // Inventory GL Debit MUST be 2,800 YER (not 392,000 YER!)
      expect(invLine.currencyCode, equals('YER'));
      expect(invLine.debit, equals(2800.0));
      expect(invLine.baseDebit, equals(2800.0));

      // Supplier GL Credit MUST be 20 SAR (not 2,800 SAR!)
      expect(suppLine.currencyCode, equals('SAR'));
      expect(suppLine.credit, equals(20.0));
      expect(suppLine.exchangeRateToBase, equals(140.0));
      expect(suppLine.baseCredit, equals(2800.0));
    });

    test('TEST 3 — USD Purchase (20 USD @ 150 YER/USD)', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-USD-01',
          itemName: 'USD Item',
          quantity: const Value(1.0),
          unitCost: const Value(20.0),
          totalCost: const Value(20.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-USD-003',
          receiptDate: DateTime.utc(2026, 9, 7).millisecondsSinceEpoch,
          currencyCode: 'USD',
          exchangeRate: const Value(150.0),
          warehouse: Value(warehouseId),
          status: const Value('draft'),
          createdAt: now,
          updatedAt: now,
          companyId: Value(LocalAuthDefaults.companyId),
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-USD-003',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'USD',
        exchangeRate: 150.0,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      final journalEntry = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptId,
      );
      expect(journalEntry, isNotNull);

      final invLine = journalEntry!.lines.firstWhere((l) => l.debit > 0);
      final suppLine = journalEntry.lines.firstWhere((l) => l.credit > 0);

      expect(invLine.currencyCode, equals('YER'));
      expect(invLine.debit, equals(3000.0));
      expect(invLine.baseDebit, equals(3000.0));

      expect(suppLine.currencyCode, equals('USD'));
      expect(suppLine.credit, equals(20.0));
      expect(suppLine.baseCredit, equals(3000.0));
    });

    test('TEST 4 — Quantity Multiplication (10 Qty @ 20 SAR, Rate 140)', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-SAR-04',
          itemName: 'Multi Qty Item',
          quantity: const Value(10.0),
          unitCost: const Value(20.0),
          totalCost: const Value(200.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-SAR-004',
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

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-SAR-004',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 140.0,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      final journalEntry = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptId,
      );
      expect(journalEntry, isNotNull);

      final invLine = journalEntry!.lines.firstWhere((l) => l.debit > 0);
      final suppLine = journalEntry.lines.firstWhere((l) => l.credit > 0);

      expect(invLine.debit, equals(28000.0));
      expect(invLine.baseDebit, equals(28000.0));

      expect(suppLine.credit, equals(200.0)); // 200 SAR
      expect(suppLine.baseCredit, equals(28000.0)); // 28,000 YER
    });

    test('TEST 6 — Missing / Zero FX Rate Explicit Failure', () async {
      final docRef = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'REC-ERR-006',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: generateUuidV4(),
        currencyCode: 'SAR',
        exchangeRate: 0.0, // Invalid exchange rate
      );

      expect(
        () => adapterPoster.postAccountingEntry(
          document: docRef,
          totalAmount: 20.0,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('TEST 8 — Stock Issue / COGS Historical Cost (No Re-conversion with Sale Rate)', () async {
      final receiptId = generateUuidV4();
      final recLineId = generateUuidV4();
      final issueId = generateUuidV4();
      final issLineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      // 1. Inbound Purchase of 1 Item @ 10 SAR (Rate 140 = 1,400 YER)
      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: recLineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-COGS-08',
          itemName: 'COGS Test Item',
          quantity: const Value(1.0),
          unitCost: const Value(10.0),
          totalCost: const Value(10.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-008',
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

      final recRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-008',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 140.0,
      );
      await postingCoordinator.post(document: recRef);

      // 2. Issue Item (Sale rate is 150.0 SAR/YER)
      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: issLineId,
          issueId: issueId,
          movementType: 'issue',
          itemCode: 'ITEM-COGS-08',
          itemName: 'COGS Test Item',
          quantity: const Value(1.0),
          unitCost: const Value(10.0),
          totalCost: const Value(10.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockIssues).insert(
        StockIssuesCompanion.insert(
          uuid: issueId,
          issueNumber: 'ISS-008',
          issueDate: DateTime.utc(2026, 9, 7).millisecondsSinceEpoch,
          currencyCode: 'SAR',
          warehouse: Value(warehouseId),
          status: const Value('draft'),
          createdAt: now,
          updatedAt: now,
          companyId: Value(LocalAuthDefaults.companyId),
        ),
      );

      final issueRef = InventoryDocumentRef(
        documentId: issueId,
        documentNumber: 'ISS-008',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 150.0, // Sale exchange rate!
      );

      final result = await postingCoordinator.post(document: issueRef);
      expect(result, isA<PostSuccess>());

      final issueEntry = await journalRepo.findBySource(
        sourceType: 'stock_issue',
        sourceId: issueId,
      );
      expect(issueEntry, isNotNull);

      final cogsLine = issueEntry!.lines.firstWhere((l) => l.debit > 0);
      final invLine = issueEntry.lines.firstWhere((l) => l.credit > 0);

      // COGS Debit MUST be historical layer cost (1,400 YER), NOT 1,400 * 150 = 210,000 YER!
      expect(cogsLine.currencyCode, equals('YER'));
      expect(cogsLine.debit, equals(1400.0));
      expect(cogsLine.baseDebit, equals(1400.0));
      expect(cogsLine.debit, isNot(equals(210000.0)));

      expect(invLine.currencyCode, equals('YER'));
      expect(invLine.credit, equals(1400.0));
      expect(invLine.baseCredit, equals(1400.0));
    });

    test('TEST 11 — Database Persistence & Reload Verification', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-SAR-11',
          itemName: 'DB Persistence Item',
          quantity: const Value(1.0),
          unitCost: const Value(20.0),
          totalCost: const Value(20.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-SAR-011',
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

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-SAR-011',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 140.0,
      );

      await postingCoordinator.post(document: docRef);

      // Direct SQLite/Drift Query on persisted tables
      final entryRow = await (accountingDb.select(accountingDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals(receiptId)))
          .getSingle();
      final lineRows = await (accountingDb.select(accountingDb.journalLines)
            ..where((tbl) => tbl.entryId.equals(entryRow.uuid)))
          .get();

      final invRow = lineRows.firstWhere((l) => l.debit > 0);
      final suppRow = lineRows.firstWhere((l) => l.credit > 0);

      expect(entryRow.currencyCode, equals('SAR'));

      expect(invRow.currencyCode, equals('YER'));
      expect(invRow.debit, equals(2800.0));
      expect(invRow.baseDebit, equals(2800.0));
      expect(invRow.exchangeRateToBase, equals(1.0));

      expect(suppRow.currencyCode, equals('SAR'));
      expect(suppRow.credit, equals(20.0));
      expect(suppRow.baseCredit, equals(2800.0));
      expect(suppRow.exchangeRateToBase, equals(140.0));
    });

    test('TEST 12, 13 & 14 — Inventory Reconciliation & Double Conversion Regression Assertions', () async {
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final warehouseId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

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

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion.insert(
          uuid: lineId,
          receiptId: receiptId,
          movementType: 'receipt',
          itemCode: 'ITEM-SAR-14',
          itemName: 'Regression Assert Item',
          quantity: const Value(1.0),
          unitCost: const Value(20.0),
          totalCost: const Value(20.0),
        ),
      );

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: receiptId,
          receiptNumber: 'REC-SAR-014',
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

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: 'REC-SAR-014',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 9, 7),
        warehouseId: warehouseId,
        currencyCode: 'SAR',
        exchangeRate: 140.0,
      );

      await postingCoordinator.post(document: docRef);

      // 1. Cost Layer Valuation
      final layers = await (inventoryDb.select(inventoryDb.inventoryCostLayers)
            ..where((tbl) => tbl.movementId.equals(receiptId)))
          .get();
      expect(layers.length, equals(1));
      final costLayerValuation = layers.first.totalCost; // 2,800 YER

      // 2. Journal Lines
      final journalEntry = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptId,
      );
      final invLine = journalEntry!.lines.firstWhere((l) => l.debit > 0);
      final suppLine = journalEntry.lines.firstWhere((l) => l.credit > 0);

      // TEST 12: Inventory GL balance == Inventory cost-layer valuation
      expect(invLine.debit, equals(costLayerValuation));
      expect(invLine.baseDebit, equals(costLayerValuation));

      // TEST 13: Supplier balance in SAR == 20 SAR (not 2,800 SAR!)
      expect(suppLine.credit, equals(20.0));
      expect(suppLine.credit, isNot(equals(2800.0)));

      // TEST 14: Double-conversion regression assertions
      expect(invLine.debit, isNot(equals(392000.0)));
      expect(invLine.baseDebit, isNot(equals(392000.0)));
      expect(invLine.debit, equals(2800.0));
      expect(invLine.baseDebit, equals(2800.0));
    });
  });
}
