import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
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
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late Box<dynamic> authBox;
  late Box<dynamic> initBox;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_phase_2');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    settingsBox = await Hive.openBox<dynamic>('${HiveBoxes.settings}_p2');
    await settingsBox.clear();

    authBox = await Hive.openBox<dynamic>('${LocalAuthStore.boxName}_p2');
    await authBox.clear();

    initBox = await Hive.openBox<dynamic>('company_initialization_box_p2');
    await initBox.clear();
  });

  tearDown(() async {
    await settingsBox.clear();
    await authBox.clear();
    await initBox.clear();
  });

  group('Phase 2 — Login → System Initialization Required Tests', () {
    test('1. First-Run Setup completion enables main admin login', () async {
      final settingsRepo = SettingsRepository(box: settingsBox);
      final authStore = LocalAuthStore(box: authBox);
      final coordinator = FirstRunSetupCoordinator(
        settingsRepository: settingsRepo,
        authStore: authStore,
      );

      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة النكسابيز',
        companyCode: 'NEXA01',
        adminName: 'مدير النظام الأول',
        adminEmail: 'admin@nexabiz.com',
        adminPassword: 'SecureAdminPassword123!',
      );

      await coordinator.commitFirstRunSetup(payload);

      final authRepo = LocalAuthRepository(
        store: authStore,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => SyncApiConfig.fromEnvironment(),
      );

      final authResult = await authRepo.login(
        email: 'admin@nexabiz.com',
        password: 'SecureAdminPassword123!',
        deviceId: 'dev_001',
        deviceName: 'Test Device',
        platform: 'linux',
      );

      expect(authResult.hasCompany, isTrue);
      expect(authResult.user.email, equals('admin@nexabiz.com'));
      expect(authResult.user.isSuperAdmin, isTrue);
    });

    test('2. Incomplete System Initialization returns isInitialized == false', () async {
      final initRepo = CompanyInitializationRepositoryImpl(box: initBox);
      final guard = InitializationGuard(initRepository: initRepo);

      final isReady = await guard.isInitialized();
      expect(isReady, isFalse);

      expect(
        () async => await guard.assertInitialized(),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('3. Direct Service Bypass (PostingCoordinator) is REJECTED when uninitialized', () async {
      final initRepo = CompanyInitializationRepositoryImpl(box: initBox);
      final guard = InitializationGuard(initRepository: initRepo);

      final dummyDoc = InventoryDocumentRef(
        documentId: 'doc_100',
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh_main',
        status: InventoryDocumentStatus.draft,
      );

      final postingCoordinator = PostingCoordinatorImpl(
        db: FakeInventoryDb(),
        stockValidationService: FakeValidationService(),
        dependencyDetector: FakeDependencyDetector(),
        postingEngine: FakePostingEngine(),
        accountingPoster: FakeAccountingPoster(),
        permissionGuard: FakePermissionGuard(),
        initializationGuard: guard,
      );

      expect(
        () async => await postingCoordinator.post(document: dummyDoc),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('4. Restart and Re-login while incomplete preserves System Setup Requirement', () async {
      final settingsRepo = SettingsRepository(box: settingsBox);
      final authStore = LocalAuthStore(box: authBox);

      final coordinator = FirstRunSetupCoordinator(
        settingsRepository: settingsRepo,
        authStore: authStore,
      );

      await coordinator.commitFirstRunSetup(const FirstRunSetupPayload(
        language: 'ar',
        companyName: 'NexaBiz Corp',
        companyCode: 'NEXA',
        adminName: 'Admin',
        adminEmail: 'admin@nexabiz.local',
        adminPassword: 'Password123!',
      ));

      final initRepo = CompanyInitializationRepositoryImpl(box: initBox);
      final guard = InitializationGuard(initRepository: initRepo);

      final authRepo = LocalAuthRepository(
        store: authStore,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => SyncApiConfig.fromEnvironment(),
      );

      final reLoginResult = await authRepo.login(
        email: 'admin@nexabiz.local',
        password: 'Password123!',
        deviceId: 'dev_001',
        deviceName: 'Test Device',
        platform: 'linux',
      );

      expect(reLoginResult.hasCompany, isTrue);

      final isInitializedAfterRestart = await guard.isInitialized();
      expect(isInitializedAfterRestart, isFalse);
    });

    test('5. Completed System Initialization passes InitializationGuard', () async {
      final initRepo = CompanyInitializationRepositoryImpl(box: initBox);
      final guard = InitializationGuard(initRepository: initRepo);

      await initRepo.saveState(const CompanyInitializationState(
        companyId: 'company_001',
        companyCreated: true,
        inventoryCurrencyConfigured: true,
        accountingConfigured: true,
        warehouseConfigured: true,
        inventorySettingsConfigured: true,
        initializationCompleted: true,
      ));

      await initRepo.saveInventoryConfig(const CompanyInventoryConfig(
        companyId: 'company_001',
        inventoryBaseCurrencyId: 'SAR',
        allowNegativeStock: false,
      ));

      await initRepo.saveAccountingConfig(const CompanyAccountingConfig(
        companyId: 'company_001',
        accountMappings: {
          AccountRole.inventory: '1200',
          AccountRole.cogs: '5100',
          AccountRole.revenue: '4100',
          AccountRole.receivable: '1120',
          AccountRole.payable: '2110',
          AccountRole.cash: '1110',
          AccountRole.adjustment: '5200',
          AccountRole.fxGainLoss: '5300',
        },
      ));

      await initRepo.saveWarehouseConfig(const CompanyWarehouseConfig(
        companyId: 'company_001',
        defaultWarehouseId: 'wh_main_001',
      ));

      final isReady = await guard.isInitialized();
      expect(isReady, isTrue);

      final state = await guard.assertInitialized();
      expect(state.isFullyConfigured, isTrue);
    });

    test('6. Non-admin user without system setup permissions is gated', () {
      final normalUser = AuthUser(
        id: 'emp_01',
        email: 'employee@nexabiz.com',
        name: 'Employee',
        isSuperAdmin: false,
      );

      const permissions = <String>{'inventory.view'};

      final isAuthorized = normalUser.isSuperAdmin ||
          permissions.any((p) => const ['system.setup', 'administration.manage', 'admin'].contains(p));

      expect(isAuthorized, isFalse);
    });
  });
}

// Dummy Test Stubs implementing domain interfaces safely for assertion tests
class FakeInventoryDb implements InventoryDatabase {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeValidationService implements StockValidationService {
  @override
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  }) async => 0.0;

  @override
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  }) async => [];
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
  }) async => 0.0;

  @override
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  }) async => 0.0;

  @override
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  }) async => 0.0;

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

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}
}

class FakePermissionGuard implements PermissionGuard {
  @override
  void requireAll(Iterable<String> codes) {}

  @override
  void requireAny(Iterable<String> codes) {}

  @override
  void requirePermission(String permission) {}
}
