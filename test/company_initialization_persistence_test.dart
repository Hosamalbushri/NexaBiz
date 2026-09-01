import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';

import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> box;
  String currentTenant = 'company-tenant-a';

  setUp(() async {
    Hive.init('./test_hive_temp');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      box = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await box.clear();
    currentTenant = 'company-tenant-a';
  });

  tearDown(() async {
    await box.clear();
  });

  CompanyInitializationRepositoryImpl createRepo() {
    return CompanyInitializationRepositoryImpl(
      box: box,
      readCompanyId: () => currentTenant,
    );
  }

  group('Phase 1 — Company Initialization Domain & Persistence Tests', () {
    test('1. Persistence & Round-Trip Serialization', () async {
      final repo = createRepo();

      final state = CompanyInitializationState(
        companyId: currentTenant,
        companyCreated: true,
        inventoryCurrencyConfigured: true,
        accountingConfigured: true,
        warehouseConfigured: true,
        inventorySettingsConfigured: true,
        initializationCompleted: true,
        updatedAt: DateTime.utc(2026, 8, 30),
      );

      await repo.saveState(state);
      final loadedState = await repo.getState();

      expect(loadedState.companyId, equals(currentTenant));
      expect(loadedState.companyCreated, isTrue);
      expect(loadedState.inventoryCurrencyConfigured, isTrue);
      expect(loadedState.initializationCompleted, isTrue);
    });

    test('2. Company Scoping & Multi-Tenant Isolation', () async {
      currentTenant = 'company-tenant-a';
      final repoTenantA = createRepo();

      final inventoryConfigA = const CompanyInventoryConfig(
        companyId: 'company-tenant-a',
        inventoryBaseCurrencyId: 'YER',
      );
      await repoTenantA.saveInventoryConfig(inventoryConfigA);

      // Switch context to Tenant B
      currentTenant = 'company-tenant-b';
      final repoTenantB = createRepo();

      final loadedConfigB = await repoTenantB.getInventoryConfig();
      expect(loadedConfigB, isNull);

      final inventoryConfigB = const CompanyInventoryConfig(
        companyId: 'company-tenant-b',
        inventoryBaseCurrencyId: 'USD',
      );
      await repoTenantB.saveInventoryConfig(inventoryConfigB);

      final reloadedConfigB = await repoTenantB.getInventoryConfig();
      expect(reloadedConfigB?.inventoryBaseCurrencyId, equals('USD'));

      // Switch back to Tenant A
      currentTenant = 'company-tenant-a';
      final reloadedConfigA = await repoTenantA.getInventoryConfig();
      expect(reloadedConfigA?.inventoryBaseCurrencyId, equals('YER'));
    });

    test('3. Single Base Currency Per Tenant Invariant Guard', () async {
      currentTenant = 'company-tenant-a';
      final repo = createRepo();

      final config = const CompanyInventoryConfig(
        companyId: 'company-tenant-a',
        inventoryBaseCurrencyId: 'YER',
      );
      await repo.saveInventoryConfig(config);

      final invalidAttempt = const CompanyInventoryConfig(
        companyId: 'company-tenant-a',
        inventoryBaseCurrencyId: 'USD',
      );

      expect(
        () async => await repo.saveInventoryConfig(invalidAttempt),
        throwsA(isA<StateError>()),
      );
    });

    test('4. InitializationValidator — Incomplete State Evaluation', () async {
      const validator = InitializationValidator();

      final state = const CompanyInitializationState(
        companyId: 'company-tenant-a',
        companyCreated: true,
        inventoryCurrencyConfigured: false,
        accountingConfigured: false,
        warehouseConfigured: false,
        inventorySettingsConfigured: false,
        initializationCompleted: false,
      );

      final result = validator.validate(
        state: state,
        inventoryConfig: null,
        accountingConfig: null,
        warehouseConfig: null,
      );

      expect(result.isReady, isFalse);
      expect(result.missingRequirements.length, greaterThanOrEqualTo(5));
      expect(
        result.missingRequirements,
        contains('Inventory base currency is not configured'),
      );
      expect(
        result.missingRequirements,
        contains('System chart of accounts mappings are incomplete'),
      );
      expect(
        result.missingRequirements,
        contains('Default primary warehouse is not configured'),
      );
    });

    test('5. InitializationValidator — Complete State Evaluation', () async {
      const validator = InitializationValidator();

      final state = const CompanyInitializationState(
        companyId: 'company-tenant-a',
        companyCreated: true,
        inventoryCurrencyConfigured: true,
        accountingConfigured: true,
        warehouseConfigured: true,
        inventorySettingsConfigured: true,
        initializationCompleted: true,
      );

      final inventoryConfig = const CompanyInventoryConfig(
        companyId: 'company-tenant-a',
        inventoryBaseCurrencyId: 'YER',
      );

      final accountingConfig = const CompanyAccountingConfig(
        companyId: 'company-tenant-a',
        accountMappings: {
          AccountRole.inventory: '1230',
          AccountRole.cogs: '5100',
          AccountRole.revenue: '4100',
          AccountRole.receivable: '1120',
          AccountRole.payable: '2110',
          AccountRole.cash: '1110',
          AccountRole.adjustment: '5200',
          AccountRole.fxGainLoss: '7100',
        },
      );

      final warehouseConfig = const CompanyWarehouseConfig(
        companyId: 'company-tenant-a',
        defaultWarehouseId: 'wh-main-001',
      );

      final result = validator.validate(
        state: state,
        inventoryConfig: inventoryConfig,
        accountingConfig: accountingConfig,
        warehouseConfig: warehouseConfig,
      );

      expect(result.isReady, isTrue);
      expect(result.missingRequirements, isEmpty);
    });
  });
}
