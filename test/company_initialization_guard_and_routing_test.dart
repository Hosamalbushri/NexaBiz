import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_initialization_route_guard.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';

class FakeStockValidationService implements StockValidationService {
  @override
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  }) async => [];

  @override
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  }) async => 100.0;
}

class FakeDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async => [];
}

class FakePostingEngine implements PostingEngine {
  @override
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  }) async => 1000.0;

  @override
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  }) async => 1000.0;

  @override
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  }) async => 1000.0;

  @override
  Future<void> reversePosting({required InventoryDocumentRef document}) async {}
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late InventoryDatabase db;
  late CompanyInitializationRepositoryImpl initRepository;
  late InitializationGuard initializationGuard;
  const currentCompanyId = 'company-test-alpha';

  setUp(() async {
    db = InventoryDatabase.memory();
    Hive.init('./test_hive_temp_p5');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    initRepository = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => currentCompanyId,
    );

    initializationGuard = InitializationGuard(initRepository: initRepository);

    // Initialize company state with uninitialized flags
    await initRepository.saveState(
      (await initRepository.getState()).copyWith(
        companyCreated: true,
        companyId: currentCompanyId,
        inventoryCurrencyConfigured: false,
        accountingConfigured: false,
        warehouseConfigured: false,
        inventorySettingsConfigured: false,
        initializationCompleted: false,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await settingsBox.clear();
  });

  group('Phase 5 — Initialization Guard & Routing Enforcement Tests', () {
    const routeGuard = CompanyInitializationRouteGuard();

    test('1. Unauthenticated Access Rejection', () {
      final decision = routeGuard.evaluateRoute(
        path: '/inventory/receipts',
        isAuthenticated: false,
        isInitializationComplete: false,
        isPublicRoute: false,
        canAccessSetup: true,
      );

      expect(decision, equals(RouteRedirectDecision.redirectToLogin));
    });

    test('2. Incomplete Initialization Inventory Routing Blocking', () {
      final decision = routeGuard.evaluateRoute(
        path: '/inventory/receipts',
        isAuthenticated: true,
        isInitializationComplete: false,
        isPublicRoute: false,
        canAccessSetup: true,
      );

      expect(decision, equals(RouteRedirectDecision.redirectToSetup));
    });

    test('3. Complete Initialization Normal Application Access Allowed', () {
      final decision = routeGuard.evaluateRoute(
        path: '/inventory/receipts',
        isAuthenticated: true,
        isInitializationComplete: true,
        isPublicRoute: false,
        canAccessSetup: true,
      );

      expect(decision, equals(RouteRedirectDecision.allow));
    });

    test('4. Deep-Link Bypass Prevention to Inventory Sub-Routes', () {
      final deepLinkDecision = routeGuard.evaluateRoute(
        path: '/inventory/stock-count/new',
        isAuthenticated: true,
        isInitializationComplete: false,
        isPublicRoute: false,
        canAccessSetup: true,
      );

      expect(deepLinkDecision, equals(RouteRedirectDecision.redirectToSetup));
    });

    test('5. Direct Service Bypass Rejection (Below UI Layer)', () async {
      // Create posting coordinator configured with initializationGuard
      final coordinator = PostingCoordinatorImpl(
        db: db,
        stockValidationService: FakeStockValidationService(),
        dependencyDetector: FakeDependencyDetector(),
        postingEngine: FakePostingEngine(),
        accountingPoster: FakeAccountingPoster(),
        permissionGuard: FakePermissionGuard(),
        readCompanyId: () => currentCompanyId,
        initializationGuard: initializationGuard,
      );

      final docRef = InventoryDocumentRef(
        documentId: 'doc-001',
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-001',
        status: InventoryDocumentStatus.draft,
      );

      expect(
        () async => await coordinator.post(document: docRef),
        throwsA(
          isA<UninitializedCompanyException>().having(
            (e) => e.missingRequirements,
            'missingRequirements',
            isNotEmpty,
          ),
        ),
      );
    });

    test('6. Authorized Setup Route Access Allowed', () {
      final decision = routeGuard.evaluateRoute(
        path: '/setup',
        isAuthenticated: true,
        isInitializationComplete: false,
        isPublicRoute: false,
        canAccessSetup: true, // Authorized
      );

      expect(decision, equals(RouteRedirectDecision.allow));
    });

    test('7. Unauthorized Setup Route Access Rejection', () {
      final decision = routeGuard.evaluateRoute(
        path: '/setup',
        isAuthenticated: true,
        isInitializationComplete: false,
        isPublicRoute: false,
        canAccessSetup: false, // Unauthorized
      );

      expect(decision, equals(RouteRedirectDecision.accessDenied));
    });

    test(
      '8. Full Complete Initialization State Unlocks Service & Route Guards',
      () async {
        // Set all initialization flags to complete
        await initRepository.saveInventoryConfig(
          const CompanyInventoryConfig(
            companyId: currentCompanyId,
            inventoryBaseCurrencyId: 'YER',
          ),
        );

        await initRepository.saveAccountingConfig(
          const CompanyAccountingConfig(
            companyId: currentCompanyId,
            accountMappings: {
              AccountRole.inventory: 'acc-inv-001',
              AccountRole.cogs: 'acc-cogs-001',
              AccountRole.revenue: 'acc-rev-001',
              AccountRole.receivable: 'acc-rec-001',
              AccountRole.payable: 'acc-pay-001',
              AccountRole.cash: 'acc-cash-001',
              AccountRole.adjustment: 'acc-adj-001',
              AccountRole.fxGainLoss: 'acc-fx-001',
            },
          ),
        );

        await initRepository.saveWarehouseConfig(
          const CompanyWarehouseConfig(
            companyId: currentCompanyId,
            defaultWarehouseId: 'wh-main-001',
          ),
        );

        await initRepository.saveState(
          (await initRepository.getState()).copyWith(
            companyCreated: true,
            inventoryCurrencyConfigured: true,
            accountingConfigured: true,
            warehouseConfigured: true,
            inventorySettingsConfigured: true,
            initializationCompleted: true,
          ),
        );

        final isReady = await initializationGuard.isInitialized();
        expect(isReady, isTrue);

        final decision = routeGuard.evaluateRoute(
          path: '/inventory/receipts',
          isAuthenticated: true,
          isInitializationComplete: isReady,
          isPublicRoute: false,
          canAccessSetup: true,
        );

        expect(decision, equals(RouteRedirectDecision.allow));
      },
    );
  });
}
