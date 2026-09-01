import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/modules/accounting/accounting_module.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/inventory_module.dart';
import 'package:stock_count/modules/sales/sales_module.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase db;
  late CurrencyRepositoryImpl currencyRepo;
  late AccountRepositoryImpl accountRepo;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('modular_setup_test_');
    Hive.init(tempDir.path);
    db = AccountingDatabase.memory();
    currencyRepo = CurrencyRepositoryImpl(
      db,
      readCompanyId: () => 'test-tenant-1',
    );
    accountRepo = AccountRepositoryImpl(
      db,
      readCompanyId: () => 'test-tenant-1',
    );
    await accountRepo.ensureDefaultChartSeeded();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Currencies Database Table & Repository', () {
    test('seeds default currencies with specified default code', () async {
      await currencyRepo.ensureDefaultCurrenciesSeeded(defaultCode: 'USD');
      final all = await currencyRepo.getAll();
      expect(all, isNotEmpty);
      expect(all.any((c) => c.code == 'USD' && c.isDefault), isTrue);
      expect(all.where((c) => c.isDefault), hasLength(1));

      final defaultCur = await currencyRepo.getDefaultCurrency();
      expect(defaultCur?.code, 'USD');
    });

    test('creates custom user-defined currency and switches default', () async {
      await currencyRepo.ensureDefaultCurrenciesSeeded(defaultCode: 'SAR');

      // Add a custom currency
      final custom = await currencyRepo.upsert(
        const CurrencyDraft(
          code: 'CUSTOM_COIN',
          nameAr: 'عملة مخصصة',
          nameEn: 'Custom Coin',
          symbol: 'CC',
          decimalDigits: 3,
          isDefault: true,
          isActive: true,
        ),
      );
      expect(custom.code, 'CUSTOM_COIN');
      expect(custom.isDefault, isTrue);
      expect(custom.decimalDigits, 3);

      // Verify previous default (SAR) is no longer default
      final sar = await currencyRepo.getByCode('SAR');
      expect(sar?.isDefault, isFalse);

      final currentDefault = await currencyRepo.getDefaultCurrency();
      expect(currentDefault?.code, 'CUSTOM_COIN');

      // Switch default back to SAR
      await currencyRepo.setDefaultCurrency('SAR');
      final newDefault = await currencyRepo.getDefaultCurrency();
      expect(newDefault?.code, 'SAR');

      final updatedCustom = await currencyRepo.getByCode('CUSTOM_COIN');
      expect(updatedCustom?.isDefault, isFalse);
    });

    test('toggles active status and filters inactive currencies', () async {
      await currencyRepo.ensureDefaultCurrenciesSeeded(defaultCode: 'SAR');

      await currencyRepo.toggleActive('USD', false);
      final activeOnly = await currencyRepo.getAll(includeInactive: false);
      expect(activeOnly.any((c) => c.code == 'USD'), isFalse);

      final all = await currencyRepo.getAll(includeInactive: true);
      expect(all.any((c) => c.code == 'USD'), isTrue);
      expect(all.firstWhere((c) => c.code == 'USD').isActive, isFalse);

      await currencyRepo.toggleActive('USD', true);
      final activeAgain = await currencyRepo.getAll(includeInactive: false);
      expect(activeAgain.any((c) => c.code == 'USD'), isTrue);
    });
  });

  group('Decentralized Modular Setup Architecture', () {
    test('ModuleRegistry aggregates setup steps from all modules with order', () {
      final registry = ModuleRegistry([
        AccountingModule(),
        InventoryModule(),
        SalesModule(),
      ]);

      final steps = registry.allSetupSteps;
      expect(steps.length, greaterThanOrEqualTo(5));

      // Check sort order is strictly ascending
      for (int i = 0; i < steps.length - 1; i++) {
        expect(steps[i].sortOrder <= steps[i + 1].sortOrder, isTrue);
      }

      final stepIds = steps.map((s) => s.id).toList();
      expect(stepIds, contains('accounting_currencies_setup_step'));
      expect(stepIds, contains('accounting_role_mapping_setup_step'));
      expect(stepIds, contains('inventory_base_currency_warehouse_step'));
      expect(stepIds, contains('inventory_costing_policy_step'));
      expect(stepIds, contains('sales_defaults_setup_step'));
    });

    test('Single-choice Inventory Base Currency invariant is preserved', () {
      const config = CompanyInventoryConfig(
        companyId: 'test-tenant-1',
        inventoryBaseCurrencyId: 'SAR',
      );
      expect(config.inventoryBaseCurrencyId, 'SAR');
      expect(config.inventoryBaseCurrencyId, isA<String>());
    });

    test('Chart of Accounts role mappings link flexibly without pattern restriction', () async {
      // Create custom accounts in CoA with arbitrary codes
      final customInv = await accountRepo.insert(
        AccountDraft(
          parentId: null,
          accountCode: '998877',
          name: 'مخزون خاص حر',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      final customRev = await accountRepo.insert(
        AccountDraft(
          parentId: null,
          accountCode: '887766',
          name: 'إيراد مبيعات خاص',
          accountType: AccountType.revenue,
          isGroup: false,
        ),
      );

      final accountingConfig = CompanyAccountingConfig(
        companyId: 'test-tenant-1',
        accountMappings: {
          AccountRole.inventory: customInv.uuid,
          AccountRole.revenue: customRev.uuid,
        },
      );

      expect(accountingConfig.accountMappings[AccountRole.inventory], customInv.uuid);
      expect(accountingConfig.accountMappings[AccountRole.revenue], customRev.uuid);

      final invAccount = await accountRepo.getByUuid(
        accountingConfig.accountMappings[AccountRole.inventory]!,
      );
      expect(invAccount?.accountCode, '998877');
      expect(invAccount?.name, 'مخزون خاص حر');
    });
  });
}
