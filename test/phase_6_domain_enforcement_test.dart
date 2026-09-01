import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' hide isNotNull;

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_count/data/repositories/inventory_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_currency_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_setup_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_warehouse_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_validator.dart';

class FakePermissionGuard implements PermissionGuard {
  @override
  void requireAny(Iterable<String> permissions) {}

  @override
  void requireAll(Iterable<String> permissions) {}

  bool hasAny(Iterable<String> permissions) => true;

  bool hasAll(Iterable<String> permissions) => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late InventoryDatabase db;
  late AccountingDatabase accountingDb;
  late CompanyInitializationRepositoryImpl initRepo;
  late InitializationGuard initGuard;
  late PostingEngineImpl postingEngine;
  late InventoryAccountingPosterImpl accountingPoster;
  late PostingCoordinatorImpl postingCoordinator;
  late StockMovementsRepositoryImpl movementsRepo;
  late StockReturnsRepositoryImpl returnsRepo;
  late StockTransferRepositoryImpl transferRepo;
  late InventoryRepositoryImpl inventoryRepo;
  late CompanySetupService setupService;

  const testCompanyId = 'COMPANY-ENFORCE-001';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_phase_6');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = InventoryDatabase.memory();
    accountingDb = AccountingDatabase.memory();

    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    initRepo = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => testCompanyId,
    );

    initGuard = InitializationGuard(
      initRepository: initRepo,
      validator: const InitializationValidator(),
    );

    final costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => testCompanyId,
    );

    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => testCompanyId,
      initGuard,
    );

    accountingPoster = InventoryAccountingPosterImpl(
      accountingDb,
      readCompanyId: () => testCompanyId,
      initRepository: initRepo,
      initializationGuard: initGuard,
    );

    final validationService = StockValidationServiceImpl(
      db,
      () => testCompanyId,
    );

    final dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => testCompanyId,
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      permissionGuard: FakePermissionGuard(),
      readCompanyId: () => testCompanyId,
      initializationGuard: initGuard,
    );

    movementsRepo = StockMovementsRepositoryImpl(
      db: db,
      accountingPoster: accountingPoster,
      readCompanyId: () => testCompanyId,
      initializationGuard: initGuard,
    );

    returnsRepo = StockReturnsRepositoryImpl(
      db: db,
      costLayerService: costLayerService,
      readCompanyId: () => testCompanyId,
      initializationGuard: initGuard,
    );

    transferRepo = StockTransferRepositoryImpl(
      db: db,
      costLayerService: costLayerService,
      readCompanyId: () => testCompanyId,
      initializationGuard: initGuard,
    );

    inventoryRepo = InventoryRepositoryImpl(
      initializationGuard: initGuard,
    );

    setupService = CompanySetupService(
      settingsRepository: _InMemorySettingsRepository(),
      initRepository: initRepo,
    );
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
    await settingsBox.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 6 — Domain-Level Initialization Enforcement Tests', () {
    test('1. Uninitialized Company -> Direct PostingEngine.applyInboundPosting fails', () async {
      final docRef = InventoryDocumentRef(
        documentId: 'REC-001',
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      final line = InboundLineData(
        lineUuid: 'LINE-001',
        itemCode: 'ITEM-01',
        itemName: 'Item 01',
        quantity: 10,
        unitCost: 100,
      );

      expect(
        () => postingEngine.applyInboundPosting(
          document: docRef,
          lines: [line],
          warehouseId: 'WH-001',
          documentDate: DateTime.now(),
        ),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('2. Uninitialized Company -> Direct PostingEngine.applyOutboundPosting fails', () async {
      final docRef = InventoryDocumentRef(
        documentId: 'ISS-001',
        documentNumber: 'ISS-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
      );

      final line = OutboundLineData(
        lineUuid: 'LINE-002',
        itemCode: 'ITEM-01',
        itemName: 'Item 01',
        quantity: 5,
      );

      expect(
        () => postingEngine.applyOutboundPosting(
          document: docRef,
          lines: [line],
          warehouseId: 'WH-001',
          valuationMethod: CostValuationMethod.fifo,
        ),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('3. Uninitialized Company -> PostingCoordinator.post fails', () async {
      final docRef = InventoryDocumentRef(
        documentId: 'REC-002',
        documentNumber: 'REC-002',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      expect(
        () => postingCoordinator.post(
          document: docRef,
        ),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('4. Uninitialized Company -> InventoryAccountingPoster.postAccountingEntry fails', () async {
      final docRef = InventoryDocumentRef(
        documentId: 'REC-003',
        documentNumber: 'REC-003',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      expect(
        () => accountingPoster.postAccountingEntry(
          document: docRef,
          totalAmount: 1000,
        ),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('5. Uninitialized Company -> StockMovementsRepository.saveReceipt fails', () async {
      final receipt = StockReceipt(
        id: '00000000-0000-4000-8000-000000000004',
        receiptNumber: 'REC-004',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: '00000000-0000-4000-8000-000000000044',
            movementUuid: '00000000-0000-4000-8000-000000000004',
            movementType: 'receipt',
            itemCode: 'ITEM-01',
            itemName: 'Item 01',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: testCompanyId,
      );

      expect(
        () => movementsRepo.saveReceipt(receipt),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('6. Uninitialized Company -> StockTransferRepository.saveTransfer fails', () async {
      final transfer = StockTransfer(
        id: '00000000-0000-4000-8000-000000000006',
        transferNumber: 'TR-001',
        fromWarehouseId: 'WH-001',
        toWarehouseId: 'WH-002',
        transferDate: DateTime.now(),
        lines: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: testCompanyId,
      );

      expect(
        () => transferRepo.saveTransfer(transfer),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('7. Initialized Company -> Operations succeed', () async {
      // 1. Setup Company Profile
      final session = AuthSessionSnapshot(
        user: const AuthUser(id: 'USER-01', name: 'Admin', email: 'admin@test.com'),
        companies: [],
        roles: ['admin'],
        permissions: {'system.setup', 'settings.company'},
        capturedAt: DateTime.now(),
        currentCompanyId: testCompanyId,
      );

      await setupService.setupCompany(
        session: session,
        profile: const CompanyProfile(name: 'Enforced Company'),
        isSuperAdmin: true,
      );

      // 2. Setup Currency
      final currencyService = CompanyCurrencyService(initRepository: initRepo);
      await currencyService.configureInventoryBaseCurrency(
        currencyCode: 'SAR',
      );

      // 3. Setup Accounting Accounts
      final accountRepo = AccountRepositoryImpl(accountingDb, readCompanyId: () => testCompanyId);
      final accountService = CompanyAccountingConfigService(
        accountRepository: accountRepo,
        initRepository: initRepo,
      );

      const accInv = '00000000-0000-4000-8000-000000000101';
      const accCogs = '00000000-0000-4000-8000-000000000102';
      const accAdj = '00000000-0000-4000-8000-000000000103';
      const accPay = '00000000-0000-4000-8000-000000000104';
      const accRev = '00000000-0000-4000-8000-000000000105';
      const accRec = '00000000-0000-4000-8000-000000000106';
      const accCash = '00000000-0000-4000-8000-000000000107';
      const accFx = '00000000-0000-4000-8000-000000000108';
      const whId = '00000000-0000-4000-8000-000000000201';

      // Insert Accounts into DB first
      final now = DateTime.now().millisecondsSinceEpoch;
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accInv,
              accountCode: '1201',
              name: 'Inventory Account',
              accountType: 'asset',
              normalBalance: 'debit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accCogs,
              accountCode: '5001',
              name: 'COGS Account',
              accountType: 'expense',
              normalBalance: 'debit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accAdj,
              accountCode: '5002',
              name: 'Adjustment Account',
              accountType: 'expense',
              normalBalance: 'debit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accPay,
              accountCode: '2001',
              name: 'Payable Account',
              accountType: 'liability',
              normalBalance: 'credit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accRev,
              accountCode: '4001',
              name: 'Revenue Account',
              accountType: 'revenue',
              normalBalance: 'credit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accRec,
              accountCode: '1101',
              name: 'Receivable Account',
              accountType: 'asset',
              normalBalance: 'debit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accCash,
              accountCode: '1001',
              name: 'Cash Account',
              accountType: 'asset',
              normalBalance: 'debit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: accFx,
              accountCode: '5009',
              name: 'FX Gain/Loss Account',
              accountType: 'expense',
              normalBalance: 'debit',
              companyId: const Value(testCompanyId),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await accountService.saveAccountingConfig(
        mappings: {
          AccountRole.inventory: accInv,
          AccountRole.cogs: accCogs,
          AccountRole.adjustment: accAdj,
          AccountRole.payable: accPay,
          AccountRole.revenue: accRev,
          AccountRole.receivable: accRec,
          AccountRole.cash: accCash,
          AccountRole.fxGainLoss: accFx,
        },
      );

      // 4. Setup Warehouse in DB & Config
      await db.into(db.warehouses).insert(
            WarehousesCompanion(
              uuid: const Value(whId),
              code: const Value('WH-01'),
              name: const Value('Active Warehouse'),
              companyId: const Value(testCompanyId),
              isActive: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final warehouseRepo = WarehouseRepositoryImpl(db, null, () => testCompanyId);
      final warehouseService = CompanyWarehouseConfigService(
        warehouseRepository: warehouseRepo,
        initRepository: initRepo,
      );
      await warehouseService.configureDefaultWarehouse(warehouseId: whId);

      // 5. Finalize Initialization
      await initRepo.finalizeInitialization();

      // Verify Initialization completed
      final isInit = await initGuard.isInitialized();
      expect(isInit, isTrue);

      const recUuid = '00000000-0000-4000-8000-000000000301';
      const lineUuid = '00000000-0000-4000-8000-000000000302';

      // Save receipt should now succeed!
      final receipt = StockReceipt(
        id: recUuid,
        receiptNumber: 'REC-OK-01',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: recUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-01',
            itemName: 'Item 01',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: testCompanyId,
      );

      await movementsRepo.saveReceipt(receipt);
      final saved = await movementsRepo.getReceiptById(recUuid);
      expect(saved, isNotNull);
      expect(saved!.receiptNumber, equals('REC-OK-01'));
    });

    test('8. RBAC Authorization Gate -> Configuration mutation rejected for non-admin user', () async {
      final session = AuthSessionSnapshot(
        user: const AuthUser(id: 'USER-LIMITED', name: 'User', email: 'user@test.com'),
        companies: [],
        roles: ['user'],
        permissions: {'inventory.view'},
        capturedAt: DateTime.now(),
        currentCompanyId: testCompanyId,
      );

      expect(
        () => setupService.setupCompany(
          session: session,
          profile: const CompanyProfile(name: 'Unauthorized Attempt'),
          userPermissions: ['inventory.view'], // Lacks system.setup or settings.company
          isSuperAdmin: false,
        ),
        throwsA(isA<CompanySetupException>()),
      );
    });
  });
}

class _InMemorySettingsRepository implements SettingsRepository {
  CompanyProfile _profile = const CompanyProfile();

  @override
  Future<CompanyProfile> loadCompanyProfile() async => _profile;

  @override
  Future<void> saveCompanyProfile(CompanyProfile profile) async {
    _profile = profile;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
