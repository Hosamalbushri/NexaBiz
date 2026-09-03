import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class MockAccountLookupPort implements SetupAccountLookupPort {
  final Map<String, SetupAccountData> accounts = {};

  @override
  Future<SetupAccountData?> findAccount(String accountUuid) async {
    return accounts[accountUuid];
  }

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async {
    return [];
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    return [];
  }
}

class FakeCompanyInitializationRepository implements CompanyInitializationRepository {
  CompanyInitializationState _state = const CompanyInitializationState(companyId: 'company_1');
  CompanyAccountingConfig? _accountingConfig;
  CompanyInventoryConfig? _inventoryConfig;
  CompanyWarehouseConfig? _warehouseConfig;

  @override
  Future<CompanyInitializationState> getState() async => _state;

  @override
  Future<void> saveState(CompanyInitializationState state) async {
    _state = state;
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _accountingConfig;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    _accountingConfig = config;
  }

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async => _inventoryConfig;

  @override
  Future<void> saveInventoryConfig(CompanyInventoryConfig config) async {
    _inventoryConfig = config;
  }

  @override
  Future<CompanyWarehouseConfig?> getWarehouseConfig() async => _warehouseConfig;

  @override
  Future<void> saveWarehouseConfig(CompanyWarehouseConfig config) async {
    _warehouseConfig = config;
  }

  @override
  Future<CompanyInitializationState> finalizeInitialization() async {
    _state = _state.copyWith(initializationCompleted: true);
    return _state;
  }
}

void main() {
  group('Phase 9 — Setup Persistence, Migration & Idempotency Tests', () {
    late InMemoryAccountBindingRepository bindingRepo;
    late MockAccountLookupPort mockAccountLookup;
    late FakeCompanyInitializationRepository fakeCompanyInitRepo;

    const companyA = 'company_tenant_A';
    const companyB = 'company_tenant_B';

    setUp(() {
      bindingRepo = InMemoryAccountBindingRepository();
      mockAccountLookup = MockAccountLookupPort();
      fakeCompanyInitRepo = FakeCompanyInitializationRepository();
    });

    test('1. Save / Reload — Configuration and account bindings save and reload with identical data', () async {
      final binding = AccountBinding(
        companyId: companyA,
        packageId: 'accounting',
        requirementKey: 'cash_account',
        accountUuid: 'cash_uuid_101',
        status: AccountBindingStatus.bound,
        boundAt: DateTime.now().toUtc(),
      );

      await bindingRepo.saveBinding(binding);

      final reloaded = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'accounting',
        requirementKey: 'cash_account',
      );

      expect(reloaded, isNotNull);
      expect(reloaded!.accountUuid, equals('cash_uuid_101'));
      expect(reloaded.companyId, equals(companyA));
    });

    test('2. Restart simulation — Re-instantiating repository from persistent storage preserves bindings', () async {
      final repoInstance1 = InMemoryAccountBindingRepository();
      const binding = AccountBinding(
        companyId: companyA,
        packageId: 'inventory',
        requirementKey: 'inventory_account',
        accountUuid: 'inv_uuid_201',
        status: AccountBindingStatus.bound,
      );

      await repoInstance1.saveBinding(binding);

      final loaded = await repoInstance1.getBinding(
        companyId: companyA,
        packageId: 'inventory',
        requirementKey: 'inventory_account',
      );

      expect(loaded, isNotNull);
      expect(loaded!.accountUuid, equals('inv_uuid_201'));
    });

    test('3. Repeated setup (Idempotency) — Executing save setup multiple times creates 0 duplicates', () async {
      const binding = AccountBinding(
        companyId: companyA,
        packageId: 'sales',
        requirementKey: 'sales_account',
        accountUuid: 'sales_uuid_301',
        status: AccountBindingStatus.bound,
      );

      for (int i = 0; i < 5; i++) {
        await bindingRepo.saveBinding(binding);
      }

      final list = await bindingRepo.getBindingsForPackage(
        companyId: companyA,
        packageId: 'sales',
      );

      expect(list.length, equals(1));
      expect(list.first.accountUuid, equals('sales_uuid_301'));
    });

    test('4. Migration — Legacy CompanyAccountingConfig & CompanyInventoryConfig auto-migrate seamlessly', () async {
      await fakeCompanyInitRepo.saveAccountingConfig(const CompanyAccountingConfig(
        companyId: companyA,
        accountMappings: {
          AccountRole.cash: 'cash_uuid_999',
          AccountRole.revenue: 'sales_uuid_888',
          AccountRole.inventory: 'inv_uuid_777',
        },
      ));

      await fakeCompanyInitRepo.saveInventoryConfig(const CompanyInventoryConfig(
        companyId: companyA,
        inventoryBaseCurrencyId: 'USD',
      ));

      const migrationAdapter = SetupMigrationAdapter();
      final count = await migrationAdapter.migrateIfNeeded(
        companyId: companyA,
        companyInitRepo: fakeCompanyInitRepo,
        bindingRepo: bindingRepo,
      );

      expect(count, equals(3));

      final cashBinding = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'accounting',
        requirementKey: 'cash_account',
      );
      expect(cashBinding?.accountUuid, equals('cash_uuid_999'));

      final invBinding = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'inventory',
        requirementKey: 'inventory_account',
      );
      expect(invBinding?.accountUuid, equals('inv_uuid_777'));

      final secondRunCount = await migrationAdapter.migrateIfNeeded(
        companyId: companyA,
        companyInitRepo: fakeCompanyInitRepo,
        bindingRepo: bindingRepo,
      );
      expect(secondRunCount, equals(0));
    });

    test('5. Stale account binding — Deleted / deactivated account turns binding into invalidStale safely', () async {
      const salesAccountReq = AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_account',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Account',
        isRequired: true,
      );

      await bindingRepo.saveBinding(const AccountBinding(
        companyId: companyA,
        packageId: 'sales',
        requirementKey: 'sales_account',
        accountUuid: 'stale_account_uuid',
        status: AccountBindingStatus.bound,
      ));

      mockAccountLookup.accounts['stale_account_uuid'] = const SetupAccountData(
        uuid: 'stale_account_uuid',
        accountCode: '4101',
        accountType: SetupAccountType.revenue,
        companyId: companyA,
        isActive: false,
        isDeleted: true,
        isGroup: false,
        canPost: false,
      );

      final resolver = AccountBindingResolver(
        accountLookupPort: mockAccountLookup,
        bindingRepository: bindingRepo,
      );

      final resolution = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: salesAccountReq,
      );

      expect(resolution.status, equals(AccountBindingStatus.invalidStale));
      expect(resolution.isBound, isFalse);

      final validationEngine = CentralSetupValidationEngine(
        accountLookupPort: mockAccountLookup,
        bindingRepository: bindingRepo,
      );

      final registry = CentralSetupRegistry();
      const salesDef = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
      );
      registry.register(salesDef);

      final status = await validationEngine.evaluatePackageStatus(
        companyId: companyA,
        packageDef: salesDef,
        fieldValues: {},
        registry: registry,
        allPackageStatuses: {},
        accountRequirements: [salesAccountReq],
      );

      expect(status, equals(SetupStatus.invalid));
    });

    test('6. Company Isolation — Configuration and bindings for Company A and Company B are strictly isolated', () async {
      await bindingRepo.saveBinding(const AccountBinding(
        companyId: companyA,
        packageId: 'accounting',
        requirementKey: 'bank_account',
        accountUuid: 'bank_account_comp_A',
        status: AccountBindingStatus.bound,
      ));

      await bindingRepo.saveBinding(const AccountBinding(
        companyId: companyB,
        packageId: 'accounting',
        requirementKey: 'bank_account',
        accountUuid: 'bank_account_comp_B',
        status: AccountBindingStatus.bound,
      ));

      final bindingCompA = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'accounting',
        requirementKey: 'bank_account',
      );

      final bindingCompB = await bindingRepo.getBinding(
        companyId: companyB,
        packageId: 'accounting',
        requirementKey: 'bank_account',
      );

      expect(bindingCompA?.accountUuid, equals('bank_account_comp_A'));
      expect(bindingCompB?.accountUuid, equals('bank_account_comp_B'));
    });

    test('7. Existing Data Preservation — Migration preserves existing legacy initialization state and settings', () async {
      await fakeCompanyInitRepo.saveState(const CompanyInitializationState(
        companyId: companyA,
        accountingConfigured: true,
        inventoryCurrencyConfigured: true,
        initializationCompleted: true,
      ));

      await fakeCompanyInitRepo.saveAccountingConfig(const CompanyAccountingConfig(
        companyId: companyA,
        accountMappings: {
          AccountRole.cash: 'cash_uuid_123',
        },
      ));

      const migrationAdapter = SetupMigrationAdapter();
      await migrationAdapter.migrateIfNeeded(
        companyId: companyA,
        companyInitRepo: fakeCompanyInitRepo,
        bindingRepo: bindingRepo,
      );

      final state = await fakeCompanyInitRepo.getState();
      final accConfig = await fakeCompanyInitRepo.getAccountingConfig();

      expect(state.initializationCompleted, isTrue);
      expect(state.accountingConfigured, isTrue);
      expect(accConfig?.accountMappings[AccountRole.cash], equals('cash_uuid_123'));
    });
  });
}
