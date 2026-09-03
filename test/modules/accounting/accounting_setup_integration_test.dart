import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/accounting/accounting_module.dart';
import 'package:stock_count/modules/accounting/accounting_module_setup.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';

class FakeSetupAccountLookupPort implements SetupAccountLookupPort {
  FakeSetupAccountLookupPort(this.accounts);

  final Map<String, SetupAccountData> accounts;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }
}

class FakeCompanyInitializationRepository implements CompanyInitializationRepository {
  CompanyInitializationState _state = const CompanyInitializationState(
    companyId: 'company_100',
    initializationCompleted: false,
  );
  CompanyAccountingConfig? _config;

  @override
  Future<CompanyInitializationState> getState() async => _state;

  @override
  Future<void> saveState(CompanyInitializationState state) async {
    _state = state;
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _config;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    _config = config;
  }

  @override
  Future<CompanyInitializationState> finalizeInitialization() async => _state;

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async => null;

  @override
  Future<CompanyWarehouseConfig?> getWarehouseConfig() async => null;

  @override
  Future<void> saveInventoryConfig(CompanyInventoryConfig config) async {}

  @override
  Future<void> saveWarehouseConfig(CompanyWarehouseConfig config) async {}
}

void main() {
  group('Phase 3 — Accounting Setup Integration Tests', () {
    late CentralSetupRegistry registry;

    setUp(() {
      registry = CentralSetupRegistry();
    });

    test('1. CentralSetupRegistry discovers Accounting setup via module registration', () {
      AccountingModule.register(setupRegistry: registry);

      expect(registry.isRegistered('accounting'), isTrue);

      final setup = registry.get('accounting');
      expect(setup, isNotNull);
      expect(setup!.packageId, equals('accounting'));
      expect(setup.displayName('ar'), equals('إعدادات المحاسبة'));
      expect(setup.displayName('en'), equals('Accounting Setup'));
      expect(setup.sortOrder, equals(10));
    });

    test('2. Accounting setup definition exposes all required sections and fields', () {
      registerAccountingSetup(registry);

      final setup = registry.get('accounting')!;
      final sectionIds = setup.sections.map((s) => s.id).toList();

      expect(
        sectionIds,
        containsAll([
          'currency',
          'fiscal_period',
          'chart_of_accounts',
          'accounting_defaults',
        ]),
      );

      final coaSection = setup.sections.firstWhere((s) => s.id == 'chart_of_accounts');
      expect(coaSection.fields.map((f) => f.key), containsAll([
        'account_role_inventory',
        'account_role_revenue',
      ]));

      final currencySection = setup.sections.firstWhere((s) => s.id == 'currency');
      expect(currencySection.fields.first.key, equals('defaultCurrencyCode'));
      expect(currencySection.fields.first.defaultValue, equals('SAR'));
    });

    test('3. Preserves existing CompanyAccountingConfigService validation rules', () async {
      final lookupPort = FakeSetupAccountLookupPort({
        '1230': const SetupAccountData(
          uuid: 'acc_inv_uuid',
          accountCode: '1230',
          accountType: SetupAccountType.asset,
          companyId: 'company_100',
          isActive: true,
          isDeleted: false,
          isGroup: false,
          canPost: true,
        ),
      });
      final initRepo = FakeCompanyInitializationRepository();
      final configService = CompanyAccountingConfigService(
        accountLookupPort: lookupPort,
        initRepository: initRepo,
      );

      final validatedAccount = await configService.validateAccountForRole(
        companyId: 'company_100',
        role: AccountRole.inventory,
        accountCodeOrUuid: '1230',
      );
      expect(validatedAccount.accountCode, equals('1230'));

      expect(
        () async => configService.validateAccountForRole(
          companyId: 'company_100',
          role: AccountRole.inventory,
          accountCodeOrUuid: 'non_existent',
        ),
        throwsA(isA<InvalidCompanyAccountException>()),
      );
    });

    test('4. Preserves legacy accountingSetupSteps definitions and metadata', () {
      expect(accountingSetupSteps.length, equals(2));
      expect(accountingSetupSteps[0].id, equals('accounting_currencies_setup_step'));
      expect(accountingSetupSteps[1].id, equals('accounting_role_mapping_setup_step'));
      expect(accountingSetupSteps[0].moduleId, equals('accounting'));
      expect(accountingSetupSteps[1].moduleId, equals('accounting'));
    });
  });
}
