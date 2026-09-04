import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/accounting/accounting_module_setup.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

class FakeCompanyInitializationRepository implements CompanyInitializationRepository {
  CompanyAccountingConfig? _accountingConfig;
  CompanyInventoryConfig? _inventoryConfig;

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _accountingConfig;

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async => _inventoryConfig;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    _accountingConfig = config;
  }

  @override
  Future<void> saveInventoryConfig(CompanyInventoryConfig config) async {
    _inventoryConfig = config;
  }

  @override
  Future<CompanyInitializationState> getState() async {
    return const CompanyInitializationState(
      companyId: 'company_1',
      initializationCompleted: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Independent Setup Section Saving & Fiscal Period Setup Removal Tests', () {
    test('Verify fiscal_period section is removed from accountingPackageSetupDefinition', () {
      final sectionIds = accountingPackageSetupDefinition.sections.map((s) => s.id).toList();
      expect(sectionIds.contains('fiscal_period'), isFalse);
      expect(sectionIds, containsAll(['currency', 'chart_of_accounts', 'accounting_defaults']));
    });

    test('Verify independent package saving persists specific package without touching others', () async {
      final fakeRepo = FakeCompanyInitializationRepository();
      final container = ProviderContainer(
        overrides: [
          companyInitializationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(companyInitializationRepositoryProvider);
      
      // Save accounting config independently
      await repo.saveAccountingConfig(CompanyAccountingConfig(
        companyId: 'company_1',
        accountMappings: {
          AccountRole.inventory: 'acc_inv_uuid_100',
          AccountRole.revenue: 'acc_rev_uuid_200',
        },
        updatedAt: DateTime.now().toUtc(),
      ));

      // Save inventory config independently
      await repo.saveInventoryConfig(CompanyInventoryConfig(
        companyId: 'company_1',
        inventoryBaseCurrencyId: 'SAR',
        defaultCostingMethod: 'WEIGHTED_AVERAGE',
        allowNegativeStock: true,
        autoPostAccountingEntries: true,
        updatedAt: DateTime.now().toUtc(),
      ));

      final fetchedAccounting = await repo.getAccountingConfig();
      final fetchedInventory = await repo.getInventoryConfig();

      expect(fetchedAccounting, isNotNull);
      expect(fetchedAccounting!.accountMappings[AccountRole.inventory], equals('acc_inv_uuid_100'));
      expect(fetchedAccounting.accountMappings[AccountRole.revenue], equals('acc_rev_uuid_200'));

      expect(fetchedInventory, isNotNull);
      expect(fetchedInventory!.defaultCostingMethod, equals('WEIGHTED_AVERAGE'));
      expect(fetchedInventory.allowNegativeStock, isTrue);
      expect(fetchedInventory.inventoryBaseCurrencyId, equals('SAR'));
    });
  });
}
