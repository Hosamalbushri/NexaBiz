import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> box;
  String currentCompanyId = 'company-test-1';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_phase_3');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      box = Hive.box<dynamic>(HiveBoxes.settings);
      await box.clear();
    } else {
      box = await Hive.openBox<dynamic>(HiveBoxes.settings);
      await box.clear();
    }
    currentCompanyId = 'company-test-1';
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  CompanyInitializationRepositoryImpl createRepo([String Function()? readCompanyId]) {
    return CompanyInitializationRepositoryImpl(
      box: box,
      readCompanyId: readCompanyId ?? () => currentCompanyId,
    );
  }

  CompanyAccountingConfig createCompleteAccountingConfig(String companyId) {
    return CompanyAccountingConfig(
      companyId: companyId,
      accountMappings: const {
        AccountRole.inventory: '1210',
        AccountRole.cogs: '5110',
        AccountRole.revenue: '4110',
        AccountRole.receivable: '1120',
        AccountRole.payable: '2110',
        AccountRole.cash: '1110',
        AccountRole.adjustment: '5190',
        AccountRole.fxGainLoss: '5210',
      },
    );
  }

  group('Phase 3 — System Initialization State & Configuration Foundation', () {
    test('1. Incomplete State: New company defaults to uninitialized state', () async {
      final repo = createRepo();
      final state = await repo.getState();

      expect(state.companyId, equals('company-test-1'));
      expect(state.initializationCompleted, isFalse);
      expect(state.isFullyConfigured, isFalse);

      const validator = InitializationValidator();
      final result = validator.validate(state: state);

      expect(result.isReady, isFalse);
      expect(result.missingRequirements, contains('Company profile has not been created'));
      expect(result.missingRequirements, contains('Inventory base currency is not configured'));
    });

    test('2. Complete State: Passes InitializationValidator when all sub-configs exist', () async {
      final repo = createRepo();

      // 1. Company Created
      var state = await repo.getState();
      state = state.copyWith(companyCreated: true);
      await repo.saveState(state);

      // 2. Inventory Base Currency & Operational Settings
      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-test-1',
          inventoryBaseCurrencyId: 'YER',
          allowNegativeStock: false,
          defaultCostingMethod: 'FIFO',
        ),
      );

      // 3. Accounting CoA Mappings
      await repo.saveAccountingConfig(createCompleteAccountingConfig('company-test-1'));

      // 4. Primary Warehouse Config
      await repo.saveWarehouseConfig(
        const CompanyWarehouseConfig(
          companyId: 'company-test-1',
          defaultWarehouseId: 'wh-main-01',
        ),
      );

      // 5. Finalize Initialization
      final finalState = await repo.finalizeInitialization();
      expect(finalState.initializationCompleted, isTrue);
      expect(finalState.isFullyConfigured, isTrue);

      final invConfig = await repo.getInventoryConfig();
      final accConfig = await repo.getAccountingConfig();
      final whConfig = await repo.getWarehouseConfig();

      const validator = InitializationValidator();
      final result = validator.validate(
        state: finalState,
        inventoryConfig: invConfig,
        accountingConfig: accConfig,
        warehouseConfig: whConfig,
      );

      expect(result.isReady, isTrue);
      expect(result.missingRequirements, isEmpty);
    });

    test('3. Missing Configuration: Fails validation if warehouse or CoA mappings missing', () async {
      final repo = createRepo();

      await repo.saveState(
        const CompanyInitializationState(
          companyId: 'company-test-1',
          companyCreated: true,
          inventoryCurrencyConfigured: true,
          inventorySettingsConfigured: true,
          accountingConfigured: true,
          warehouseConfigured: false, // Missing warehouse
          initializationCompleted: false,
        ),
      );

      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-test-1',
          inventoryBaseCurrencyId: 'USD',
        ),
      );
      await repo.saveAccountingConfig(createCompleteAccountingConfig('company-test-1'));

      const validator = InitializationValidator();
      final state = await repo.getState();
      final result = validator.validate(
        state: state,
        inventoryConfig: await repo.getInventoryConfig(),
        accountingConfig: await repo.getAccountingConfig(),
        warehouseConfig: await repo.getWarehouseConfig(), // null
      );

      expect(result.isReady, isFalse);
      expect(
        result.missingRequirements,
        contains('Default primary warehouse is not configured'),
      );
    });

    test('4. Inconsistent State: initializationCompleted = true overridden if sub-config missing', () async {
      final repo = createRepo();

      // Inconsistent: initializationCompleted is true in state, BUT warehouse config is null in Hive
      await repo.saveState(
        const CompanyInitializationState(
          companyId: 'company-test-1',
          companyCreated: true,
          inventoryCurrencyConfigured: true,
          inventorySettingsConfigured: true,
          accountingConfigured: true,
          warehouseConfigured: true,
          initializationCompleted: true, // Inconsistent flag!
        ),
      );

      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-test-1',
          inventoryBaseCurrencyId: 'SAR',
        ),
      );

      final guard = InitializationGuard(initRepository: repo);

      // Guard must detect missing warehouse configuration despite initializationCompleted == true
      expect(() => guard.assertInitialized(), throwsA(isA<UninitializedCompanyException>()));
      expect(await guard.isInitialized(), isFalse);
    });

    test('5. Failed Initialization: Atomically fails and remains incomplete on error', () async {
      final repo = createRepo();

      // Only save partial configs (missing accounting)
      await repo.saveState(
        const CompanyInitializationState(
          companyId: 'company-test-1',
          companyCreated: true,
        ),
      );
      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-test-1',
          inventoryBaseCurrencyId: 'YER',
        ),
      );

      // Finalize should throw StateError
      expect(() => repo.finalizeInitialization(), throwsA(isA<StateError>()));

      // State must remain incomplete
      final state = await repo.getState();
      expect(state.initializationCompleted, isFalse);
      expect(state.isFullyConfigured, isFalse);
    });

    test('6. Retry: Succeeded after completing missing required configurations', () async {
      final repo = createRepo();

      await repo.saveState(
        const CompanyInitializationState(
          companyId: 'company-test-1',
          companyCreated: true,
        ),
      );
      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-test-1',
          inventoryBaseCurrencyId: 'YER',
        ),
      );

      // 1st attempt fails
      expect(() => repo.finalizeInitialization(), throwsA(isA<StateError>()));

      // Provide missing configs
      await repo.saveAccountingConfig(createCompleteAccountingConfig('company-test-1'));
      await repo.saveWarehouseConfig(
        const CompanyWarehouseConfig(
          companyId: 'company-test-1',
          defaultWarehouseId: 'wh-main-01',
        ),
      );

      // 2nd attempt (Retry) succeeds
      final finalState = await repo.finalizeInitialization();
      expect(finalState.initializationCompleted, isTrue);
      expect(finalState.isFullyConfigured, isTrue);
    });

    test('7. Duplicate Completion: Repeated finalizeInitialization calls are safe and idempotent', () async {
      final repo = createRepo();

      await repo.saveState(
        const CompanyInitializationState(
          companyId: 'company-test-1',
          companyCreated: true,
        ),
      );
      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-test-1',
          inventoryBaseCurrencyId: 'YER',
        ),
      );
      await repo.saveAccountingConfig(createCompleteAccountingConfig('company-test-1'));
      await repo.saveWarehouseConfig(
        const CompanyWarehouseConfig(
          companyId: 'company-test-1',
          defaultWarehouseId: 'wh-main-01',
        ),
      );

      // Call 1
      final state1 = await repo.finalizeInitialization();
      expect(state1.initializationCompleted, isTrue);

      // Call 2 (Duplicate)
      final state2 = await repo.finalizeInitialization();
      expect(state2.initializationCompleted, isTrue);
      expect(state2.companyId, equals(state1.companyId));
    });

    test('8. Company Isolation: Multi-tenant setup state isolation', () async {
      final repo = createRepo(() => currentCompanyId);

      // Tenant A: Complete Setup
      currentCompanyId = 'company-tenant-A';
      await repo.saveState(
        const CompanyInitializationState(
          companyId: 'company-tenant-A',
          companyCreated: true,
        ),
      );
      await repo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: 'company-tenant-A',
          inventoryBaseCurrencyId: 'USD',
        ),
      );
      await repo.saveAccountingConfig(createCompleteAccountingConfig('company-tenant-A'));
      await repo.saveWarehouseConfig(
        const CompanyWarehouseConfig(
          companyId: 'company-tenant-A',
          defaultWarehouseId: 'wh-tenant-A',
        ),
      );
      await repo.finalizeInitialization();

      // Switch to Tenant B: Uninitialized
      currentCompanyId = 'company-tenant-B';
      final stateB = await repo.getState();
      expect(stateB.companyId, equals('company-tenant-B'));
      expect(stateB.initializationCompleted, isFalse);

      final guard = InitializationGuard(initRepository: repo);
      expect(await guard.isInitialized(), isFalse);

      // Switch back to Tenant A
      currentCompanyId = 'company-tenant-A';
      expect(await guard.isInitialized(), isTrue);
    });
  });
}
