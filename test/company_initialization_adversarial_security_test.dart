import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/auth/domain/services/local_access_policy.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/product_warehouse_stock.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_repository.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_initialization_route_guard.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_setup_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_warehouse_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';

class FakeStockValidationService implements StockValidationService {
  @override
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  }) async =>
      [];

  @override
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  }) async =>
      100.0;
}

class FakeDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async =>
      [];
}

class FakePostingEngine implements PostingEngine {
  @override
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  }) async =>
      1000.0;

  @override
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  }) async =>
      1000.0;

  @override
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  }) async =>
      1000.0;

  @override
  Future<void> reversePosting({
    required InventoryDocumentRef document,
  }) async {}
}

class FakeAccountingPoster implements InventoryAccountingPoster {
  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}

  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}
}

class FakePermissionGuard implements PermissionGuard {
  @override
  void requireAny(Iterable<String> permissions) {}

  @override
  void requireAll(Iterable<String> permissions) {}

  bool hasAny(Iterable<String> permissions) => true;

  bool hasAll(Iterable<String> permissions) => true;
}

class MockWarehouseRepository implements WarehouseRepository {
  MockWarehouseRepository(this.warehouses);

  final List<Warehouse> warehouses;

  @override
  Future<List<Warehouse>> getAllWarehouses() async => warehouses;

  @override
  Stream<List<Warehouse>> watchAllWarehouses() => Stream.value(warehouses);

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    try {
      return warehouses.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Warehouse?> getDefaultWarehouse() async {
    try {
      return warehouses.firstWhere((w) => w.isDefault);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Warehouse> ensureDefaultWarehouse() async => warehouses.first;

  @override
  Future<void> saveWarehouse(Warehouse warehouse) async {}

  @override
  Future<void> deleteWarehouse(String id) async {}

  @override
  Future<List<ProductWarehouseStock>> getStocksForWarehouse(String warehouseId) async => [];

  @override
  Future<ProductWarehouseStock?> getStock(String itemCode, String warehouseId) async => null;

  @override
  Future<void> updateWarehouseStock(String itemCode, String warehouseId, double deltaQty) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase inventoryDb;
  late AccountingDatabase accountingDb;
  late Box<dynamic> settingsBox;
  late Box<SyncOperation> syncQueueBox;
  late SettingsRepository settingsRepo;

  const companyA = 'COMPANY_ALPHA_YER';
  const companyB = 'COMPANY_BETA_SAR';

  late CompanyInitializationRepositoryImpl initRepoA;
  late CompanyInitializationRepositoryImpl initRepoB;
  late AccountRepositoryImpl accountRepoDb;
  late CompanyAccountingConfigService accountingConfigServiceA;
  late CompanyWarehouseConfigService warehouseConfigServiceA;
  late CompanySetupService setupServiceA;
  late InitializationGuard initGuardA;

  setUp(() async {
    inventoryDb = InventoryDatabase.memory();
    accountingDb = AccountingDatabase.memory();

    Hive.init('./test_hive_temp_p7');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    settingsRepo = SettingsRepository(box: settingsBox);

    syncQueueBox = await Hive.openBox<SyncOperation>('sync_queue_test_p7');
    await syncQueueBox.clear();

    initRepoA = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => companyA,
    );

    initRepoB = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => companyB,
    );

    accountRepoDb = AccountRepositoryImpl(
      accountingDb,
      readCompanyId: () => companyA,
    );

    accountingConfigServiceA = CompanyAccountingConfigService(
      accountRepository: accountRepoDb,
      initRepository: initRepoA,
    );

    final mockWarehouseRepo = MockWarehouseRepository([
      Warehouse(
        id: 'wh-A-valid',
        code: 'WH-A',
        name: 'Main Warehouse Company A',
        companyId: companyA,
        isActive: true,
      ),
      Warehouse(
        id: 'wh-B-valid',
        code: 'WH-B',
        name: 'Main Warehouse Company B',
        companyId: companyB,
        isActive: true,
      ),
    ]);

    warehouseConfigServiceA = CompanyWarehouseConfigService(
      warehouseRepository: mockWarehouseRepo,
      initRepository: initRepoA,
    );

    setupServiceA = CompanySetupService(
      settingsRepository: settingsRepo,
      initRepository: initRepoA,
    );

    initGuardA = InitializationGuard(initRepository: initRepoA);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed Accounts for Company A
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '10000000-0000-4000-8000-0000000000a1',
            accountCode: '1230-A',
            name: 'Inventory Acc Company A',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: const Value(companyA),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '10000000-0000-4000-8000-0000000000a2',
            accountCode: '5100-A',
            name: 'COGS Acc Company A',
            accountType: 'expense',
            normalBalance: 'debit',
            companyId: const Value(companyA),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '10000000-0000-4000-8000-0000000000a3',
            accountCode: '2110-A',
            name: 'Payable Acc Company A',
            accountType: 'liability',
            normalBalance: 'credit',
            companyId: const Value(companyA),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );

    // Seed Accounts for Company B
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '20000000-0000-4000-8000-0000000000b1',
            accountCode: '1230-B',
            name: 'Inventory Acc Company B',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: const Value(companyB),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
  });

  tearDown(() async {
    await inventoryDb.close();
    await accountingDb.close();
    await settingsBox.clear();
    await syncQueueBox.clear();
  });

  Future<CompanyInitializationState> performFullCompanySetup({
    required String companyId,
    required bool isAuthenticated,
    required bool canAccessSetup,
    required String inventoryBaseCurrencyId,
    required Map<AccountRole, String> accountMappings,
    required String defaultWarehouseId,
    CompanySetupService? setupSvc,
    CompanyInitializationRepositoryImpl? repo,
    CompanyAccountingConfigService? accountingSvc,
    CompanyWarehouseConfigService? warehouseSvc,
  }) async {
    final activeRepo = repo ?? initRepoA;
    final activeSetup = setupSvc ?? setupServiceA;
    final activeAccounting = accountingSvc ?? accountingConfigServiceA;
    final activeWarehouse = warehouseSvc ?? warehouseConfigServiceA;

    if (!isAuthenticated) {
      throw const CompanySetupException('Authentication required');
    }
    if (!canAccessSetup) {
      throw StateError('Access Denied: User lacks setup authorization');
    }

    final session = AuthSessionSnapshot(
      user: const AuthUser(id: 'user-001', name: 'Admin', email: 'admin@nexabiz.com'),
      companies: [AuthCompany(id: companyId, name: 'Company Alpha', code: 'ALPHA')],
      roles: const ['admin'],
      permissions: const {'system.setup'},
      capturedAt: DateTime.now(),
      currentCompanyId: companyId,
    );

    await activeSetup.setupCompany(
      session: session,
      profile: const CompanyProfile(name: 'Company Corp'),
      userPermissions: ['system.setup'],
    );

    await activeRepo.saveInventoryConfig(CompanyInventoryConfig(
      companyId: companyId,
      inventoryBaseCurrencyId: inventoryBaseCurrencyId,
    ));

    await activeAccounting.saveAccountingConfig(mappings: accountMappings);
    await activeWarehouse.configureDefaultWarehouse(warehouseId: defaultWarehouseId);
    await activeWarehouse.configureInventoryOperationalSettings(
      allowNegativeStock: false,
      defaultCostingMethod: 'FIFO',
    );

    final currentState = await activeRepo.getState();
    final finalState = currentState.copyWith(initializationCompleted: true);
    await activeRepo.saveState(finalState);

    return finalState;
  }

  group('Phase 7 — Adversarial Security, Multi-Tenancy, Sync & Idempotency Tests', () {
    // -------------------------------------------------------------------------
    // 1. CROSS-TENANT ATTACKS
    // -------------------------------------------------------------------------
    test('1.1 Cross-Tenant Isolation: Company A cannot read/write Company B setup config', () async {
      await initRepoB.saveInventoryConfig(const CompanyInventoryConfig(
        companyId: companyB,
        inventoryBaseCurrencyId: 'SAR',
      ));

      final configA = await initRepoA.getInventoryConfig();
      expect(configA, isNull);

      final stateA = await initRepoA.getState();
      expect(stateA.companyId, equals(companyA));
      expect(stateA.initializationCompleted, isFalse);
    });

    test('1.2 Cross-Tenant Attack: Company A cannot assign Company B account', () async {
      expect(
        () async => await accountingConfigServiceA.saveAccountingConfig(
          mappings: {
            AccountRole.inventory: '20000000-0000-4000-8000-0000000000b1', // Company B account
          },
        ),
        throwsA(isA<InvalidCompanyAccountException>()),
      );
    });

    test('1.3 Cross-Tenant Attack: Company A cannot assign Company B warehouse', () async {
      expect(
        () async => await warehouseConfigServiceA.configureDefaultWarehouse(
          warehouseId: 'wh-B-valid', // Company B warehouse
        ),
        throwsA(isA<InvalidWarehouseException>()),
      );
    });

    test('1.4 Cross-Tenant Currency Attack: Inventory base currency immutability violation rejected', () async {
      await initRepoA.saveInventoryConfig(const CompanyInventoryConfig(
        companyId: companyA,
        inventoryBaseCurrencyId: 'YER',
      ));

      expect(
        () async => await initRepoA.saveInventoryConfig(const CompanyInventoryConfig(
          companyId: companyA,
          inventoryBaseCurrencyId: 'USD',
        )),
        throwsA(isA<StateError>()),
      );
    });

    // -------------------------------------------------------------------------
    // 2. AUTHORIZATION ATTACKS
    // -------------------------------------------------------------------------
    test('2.1 Authorization Attack: Authenticated user without setup privilege rejected', () async {
      expect(
        () async => await performFullCompanySetup(
          companyId: companyA,
          isAuthenticated: true,
          canAccessSetup: false, // Unauthorized user
          inventoryBaseCurrencyId: 'YER',
          accountMappings: {
            AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
            AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
            AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
          },
          defaultWarehouseId: 'wh-A-valid',
        ),
        throwsA(isA<StateError>()),
      );
    });

    // -------------------------------------------------------------------------
    // 3. ROUTING ATTACKS
    // -------------------------------------------------------------------------
    test('3.1 Routing Deep-Link Attack: Deep link to inventory blocked when setup incomplete', () async {
      const guard = CompanyInitializationRouteGuard();

      final decision = guard.evaluateRoute(
        path: '/inventory/stock-receipt/new',
        isAuthenticated: true,
        isInitializationComplete: false,
        isPublicRoute: false,
        canAccessSetup: true,
      );

      expect(decision, equals(RouteRedirectDecision.redirectToSetup));
    });

    test('3.2 Application Restart Routing: Incomplete state retains setup redirection after restart', () async {
      const guard = CompanyInitializationRouteGuard();

      final state = await initRepoA.getState();
      expect(state.initializationCompleted, isFalse);

      final decision = guard.evaluateRoute(
        path: '/dashboard',
        isAuthenticated: true,
        isInitializationComplete: state.initializationCompleted,
        isPublicRoute: false,
        canAccessSetup: true,
      );

      expect(decision, equals(RouteRedirectDecision.redirectToSetup));
    });

    // -------------------------------------------------------------------------
    // 4. DOMAIN SERVICE BYPASS ATTACKS
    // -------------------------------------------------------------------------
    test('4.1 Direct Domain Bypass: PostingCoordinator rejected when setup incomplete', () async {
      final coordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: FakeStockValidationService(),
        dependencyDetector: FakeDependencyDetector(),
        postingEngine: FakePostingEngine(),
        accountingPoster: FakeAccountingPoster(),
        permissionGuard: FakePermissionGuard(),
        initializationGuard: initGuardA,
      );

      final docRef = InventoryDocumentRef(
        documentId: 'doc-bypass-1',
        documentNumber: 'DOC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-A-valid',
        status: InventoryDocumentStatus.draft,
        currencyCode: 'YER',
        exchangeRate: 1.0,
      );

      expect(
        () async => await coordinator.post(document: docRef),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('4.2 Direct Poster Bypass: InventoryAccountingPoster rejects posting when accounts unconfigured', () async {
      final poster = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyA,
        initRepository: initRepoA,
      );

      final docRef = InventoryDocumentRef(
        documentId: 'doc-poster-1',
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-A-valid',
        status: InventoryDocumentStatus.posted,
        currencyCode: 'YER',
        exchangeRate: 1.0,
      );

      expect(
        () async => await poster.postAccountingEntry(
          document: docRef,
          totalAmount: 100.0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    // -------------------------------------------------------------------------
    // 5. IDEMPOTENCY ATTACKS
    // -------------------------------------------------------------------------
    test('5.1 Setup Idempotency: Re-executing complete setup twice maintains valid state', () async {
      final firstSetup = await performFullCompanySetup(
        companyId: companyA,
        isAuthenticated: true,
        canAccessSetup: true,
        inventoryBaseCurrencyId: 'YER',
        accountMappings: {
          AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
          AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
          AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
        },
        defaultWarehouseId: 'wh-A-valid',
      );

      expect(firstSetup.initializationCompleted, isTrue);

      final secondSetup = await performFullCompanySetup(
        companyId: companyA,
        isAuthenticated: true,
        canAccessSetup: true,
        inventoryBaseCurrencyId: 'YER',
        accountMappings: {
          AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
          AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
          AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
        },
        defaultWarehouseId: 'wh-A-valid',
      );

      expect(secondSetup.initializationCompleted, isTrue);
      expect(secondSetup.companyId, equals(companyA));
    });

    // -------------------------------------------------------------------------
    // 6. FAILURE RECOVERY ATTACKS
    // -------------------------------------------------------------------------
    test('6.1 Failure Recovery: Partial setup failure leaves initializationIncomplete, retry succeeds', () async {
      expect(
        () async => await performFullCompanySetup(
          companyId: companyA,
          isAuthenticated: true,
          canAccessSetup: true,
          inventoryBaseCurrencyId: 'YER',
          accountMappings: {
            AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
            AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
            AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
          },
          defaultWarehouseId: 'wh-INVALID-NON-EXISTENT',
        ),
        throwsA(isA<InvalidWarehouseException>()),
      );

      final statePostFailure = await initRepoA.getState();
      expect(statePostFailure.initializationCompleted, isFalse);

      final recoveredSetup = await performFullCompanySetup(
        companyId: companyA,
        isAuthenticated: true,
        canAccessSetup: true,
        inventoryBaseCurrencyId: 'YER',
        accountMappings: {
          AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
          AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
          AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
        },
        defaultWarehouseId: 'wh-A-valid',
      );

      expect(recoveredSetup.initializationCompleted, isTrue);
    });

    // -------------------------------------------------------------------------
    // 7. SYNCHRONIZATION ATTACKS
    // -------------------------------------------------------------------------
    test('7.1 Sync Queue Tenant Boundary: Cross-tenant SyncOperation enqueue strictly rejected', () async {
      final queueA = SyncQueue(
        box: syncQueueBox,
        companyId: companyA,
      );

      final invalidCrossTenantOp = SyncOperation(
        id: 'op-cross-tenant-1',
        companyId: companyB,
        entityType: 'company_profile',
        entityId: companyB,
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'companyId': companyB},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () async => await queueA.enqueue(invalidCrossTenantOp),
        throwsA(isA<SecurityException>()),
      );
    });
  });
}
