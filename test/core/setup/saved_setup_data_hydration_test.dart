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
      companyId: 'company_hydration_test',
      initializationCompleted: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Saved Setup Data Hydration Tests', () {
    test('Verify stored accounting and inventory configurations are successfully hydrated into setup registry fields', () async {
      final fakeRepo = FakeCompanyInitializationRepository();
      await fakeRepo.saveAccountingConfig(CompanyAccountingConfig(
        companyId: 'company_hydration_test',
        accountMappings: {
          AccountRole.inventory: 'acc_inv_uuid_999',
          AccountRole.revenue: 'acc_rev_uuid_888',
        },
        updatedAt: DateTime.now().toUtc(),
      ));

      await fakeRepo.saveInventoryConfig(CompanyInventoryConfig(
        companyId: 'company_hydration_test',
        inventoryBaseCurrencyId: 'SAR',
        defaultCostingMethod: 'FIFO',
        allowNegativeStock: true,
        autoPostAccountingEntries: true,
        updatedAt: DateTime.now().toUtc(),
      ));

      final container = ProviderContainer(
        overrides: [
          companyInitializationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(companyInitializationRepositoryProvider);
      final accountingConfig = await repo.getAccountingConfig();
      final inventoryConfig = await repo.getInventoryConfig();

      expect(accountingConfig, isNotNull);
      expect(accountingConfig!.accountMappings[AccountRole.inventory], equals('acc_inv_uuid_999'));
      expect(accountingConfig.accountMappings[AccountRole.revenue], equals('acc_rev_uuid_888'));

      expect(inventoryConfig, isNotNull);
      expect(inventoryConfig!.defaultCostingMethod, equals('FIFO'));
      expect(inventoryConfig.allowNegativeStock, isTrue);
    });
  });
}
