import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/inventory/inventory_module.dart';
import 'package:stock_count/modules/inventory/inventory_module_setup.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';

class FakeSetupAccountLookupPort implements SetupAccountLookupPort {
  FakeSetupAccountLookupPort(this.accounts);

  final Map<String, SetupAccountData> accounts;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }
}

void main() {
  group('Phase 5 — Inventory Setup Integration Tests', () {
    late CentralSetupRegistry registry;
    late InMemoryAccountBindingRepository bindingRepository;
    late FakeSetupAccountLookupPort lookupPort;
    late AccountBindingResolver resolver;

    const companyA = 'company_A';
    const companyB = 'company_B';

    const validInventoryAccount = SetupAccountData(
      uuid: 'uuid_inv_asset_100',
      accountCode: '1300',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const validCogsAccount = SetupAccountData(
      uuid: 'uuid_cogs_200',
      accountCode: '5100',
      accountType: SetupAccountType.expense,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const crossCompanyAccount = SetupAccountData(
      uuid: 'uuid_cogs_cross_999',
      accountCode: '5100',
      accountType: SetupAccountType.expense,
      companyId: companyB,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    setUp(() {
      registry = CentralSetupRegistry();
      bindingRepository = InMemoryAccountBindingRepository();
      lookupPort = FakeSetupAccountLookupPort({
        validInventoryAccount.uuid: validInventoryAccount,
        validCogsAccount.uuid: validCogsAccount,
        crossCompanyAccount.uuid: crossCompanyAccount,
      });
      resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );
    });

    test('1. CentralSetupRegistry discovers Inventory setup via module registration', () {
      InventoryModule.register(setupRegistry: registry);

      expect(registry.isRegistered('inventory'), isTrue);

      final setup = registry.get('inventory');
      expect(setup, isNotNull);
      expect(setup!.packageId, equals('inventory'));
      expect(setup.displayName('ar'), equals('إعدادات المخزون'));
      expect(setup.displayName('en'), equals('Inventory Setup'));
      expect(setup.sortOrder, equals(20));
    });

    test('2. Inventory setup definition exposes all required sections and fields', () {
      registerInventorySetup(registry);

      final setup = registry.get('inventory')!;
      final sectionIds = setup.sections.map((s) => s.id).toList();

      expect(
        sectionIds,
        containsAll([
          'currency',
          'costing_policy',
          'warehouse',
          'account_requirements',
        ]),
      );

      final currencySection = setup.sections.firstWhere((s) => s.id == 'currency');
      expect(currencySection.fields.first.key, equals('inventoryValuationCurrencyId'));
      expect(currencySection.fields.first.defaultValue, equals('SAR'));

      final costingSection = setup.sections.firstWhere((s) => s.id == 'costing_policy');
      expect(
        costingSection.fields.map((f) => f.key),
        containsAll([
          'defaultCostingMethod',
          'allowNegativeStock',
          'quantityPrecision',
          'costPrecision',
        ]),
      );
    });

    test('3. Binds Inventory account requirements successfully with UUID references', () async {
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: inventoryAccountRequirement,
        accountUuid: validInventoryAccount.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.accountUuid, equals('uuid_inv_asset_100'));

      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: inventoryAccountRequirement,
      );

      expect(result.isBound, isTrue);
      expect(result.account?.uuid, equals('uuid_inv_asset_100'));
    });

    test('4. Missing account invariant — safe initialization; controlled error during transaction', () async {
      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: cogsAccountRequirement,
      );

      expect(result.isUnbound, isTrue);
      expect(result.account, isNull);

      expect(
        () async => resolver.resolveAccountForTransaction(
          companyId: companyA,
          requirement: cogsAccountRequirement,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('5. Multi-tenant company isolation rejects cross-company account assignment', () async {
      expect(
        () async => resolver.bindAccount(
          companyId: companyA,
          requirement: cogsAccountRequirement,
          accountUuid: crossCompanyAccount.uuid, // belongs to companyB
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });

    test('6. Preserves existing CompanyInventoryConfig and CompanyWarehouseConfig persistence', () {
      const invConfig = CompanyInventoryConfig(
        companyId: companyA,
        inventoryBaseCurrencyId: 'SAR',
        defaultCostingMethod: 'FIFO',
        allowNegativeStock: false,
      );

      expect(invConfig.inventoryBaseCurrencyId, equals('SAR'));
      expect(invConfig.defaultCostingMethod, equals('FIFO'));
      expect(invConfig.allowNegativeStock, isFalse);

      const whConfig = CompanyWarehouseConfig(
        companyId: companyA,
        defaultWarehouseId: 'wh_main_01',
      );

      expect(whConfig.defaultWarehouseId, equals('wh_main_01'));
      expect(whConfig.isValid, isTrue);
    });
  });
}
