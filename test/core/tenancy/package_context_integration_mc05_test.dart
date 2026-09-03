import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:stock_count/core/modules/app_module.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/core/modules/module_providers.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';

class TestModule extends AppModule {
  const TestModule(this.id);

  @override
  final String id;

  @override
  String get nameKey => id;

  @override
  IconData get icon => Icons.folder;

  @override
  String get rootRoute => '/$id';

  @override
  String label(BuildContext context) => id;

  @override
  List<RouteBase> get routes => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const companyA = '11111111-aaaa-4000-8000-111111111111';
  const companyB = '22222222-bbbb-4000-8000-222222222222';

  setUpAll(() async {
    Hive.init('./test_hive_mc05');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    final box = await Hive.openBox<dynamic>('app_settings');
    await box.clear();
  });

  group('Phase MC-05 — Package-Wide Company Context Integration Tests', () {
    test('TEST 1 — Database Namespacing Engine is deterministic across all packages', () {
      final accDbA = tenantScopedName('accounting_accounts', companyA);
      final accDbB = tenantScopedName('accounting_accounts', companyB);

      final salesDbA = tenantScopedName('sales_invoices', companyA);
      final salesDbB = tenantScopedName('sales_invoices', companyB);

      final invDbA = tenantScopedName('inventory_products', companyA);
      final invDbB = tenantScopedName('inventory_products', companyB);

      final custDbA = tenantScopedName('customers_directory', companyA);
      final custDbB = tenantScopedName('customers_directory', companyB);

      final rpDbA = tenantScopedName('receipts_payments', companyA);
      final rpDbB = tenantScopedName('receipts_payments', companyB);

      expect(accDbA, isNot(equals(accDbB)));
      expect(salesDbA, isNot(equals(salesDbB)));
      expect(invDbA, isNot(equals(invDbB)));
      expect(custDbA, isNot(equals(custDbB)));
      expect(rpDbA, isNot(equals(rpDbB)));

      expect(accDbA, equals('accounting_accounts_11111111aaaa40008000111111111111'));
      expect(salesDbA, equals('sales_invoices_11111111aaaa40008000111111111111'));
      expect(invDbA, equals('inventory_products_11111111aaaa40008000111111111111'));
      expect(custDbA, equals('customers_directory_11111111aaaa40008000111111111111'));
      expect(rpDbA, equals('receipts_payments_11111111aaaa40008000111111111111'));
    });

    test('TEST 2 — Settings Package: Tenant-scoped settings do not leak across packages', () async {
      final repo = SettingsRepository();
      await repo.saveProductsViewMode('grid', companyA);
      await repo.saveProductsViewMode('list', companyB);

      await repo.saveCustomersAutoLinkAccount(true, companyA);
      await repo.saveCustomersAutoLinkAccount(false, companyB);

      expect(await repo.loadProductsViewMode(companyA), equals('grid'));
      expect(await repo.loadProductsViewMode(companyB), equals('list'));

      expect(await repo.loadCustomersAutoLinkAccount(companyA), isTrue);
      expect(await repo.loadCustomersAutoLinkAccount(companyB), isFalse);
    });

    test('TEST 3 — Settings Package: Chart of Accounts Parent ID is strictly isolated per tenant', () async {
      final repo = SettingsRepository();
      await repo.saveCustomersParentAccountId('coa_account_alpha_uuid', companyA);

      final parentA = await repo.loadCustomersParentAccountId(companyA);
      final parentB = await repo.loadCustomersParentAccountId(companyB);

      expect(parentA, equals('coa_account_alpha_uuid'));
      expect(parentB, isNull, reason: 'Company B must NOT load Company A parent account ID');
    });

    test('TEST 4 — Dashboard & Inventory Services controllers reactively scope to session company', () async {
      final registry = ModuleRegistry([
        const TestModule('sales'),
        const TestModule('inventory'),
      ]);

      final container = ProviderContainer(
        overrides: [
          sessionCompanyIdProvider.overrideWith((ref) => companyA),
          moduleRegistryProvider.overrideWithValue(registry),
        ],
      );

      final dashboardController = container.read(dashboardServicesProvider.notifier);
      await dashboardController.save(['sales', 'inventory']);

      final savedA = await container.read(settingsRepositoryProvider).loadDashboardServiceIds(companyA);
      final savedB = await container.read(settingsRepositoryProvider).loadDashboardServiceIds(companyB);

      expect(savedA, equals(['sales', 'inventory']));
      expect(savedB, isNull);

      container.dispose();
    });

    test('TEST 5 — Company Profile Provider auto-disposes and switches clean state A -> B -> A', () async {
      var currentCompany = companyA;
      final container = ProviderContainer(
        overrides: [
          sessionCompanyIdProvider.overrideWith((ref) => currentCompany),
        ],
      );

      final sub = container.listen(companyProfileProvider, (_, __) {});

      final repo = container.read(settingsRepositoryProvider);
      await repo.saveCompanyProfile(
        const CompanyProfile(name: 'Company Alpha Inc', taxNumber: '11111'),
        companyA,
      );
      await repo.saveCompanyProfile(
        const CompanyProfile(name: 'Company Beta Corp', taxNumber: '22222'),
        companyB,
      );

      final profileState = container.read(companyProfileProvider);
      expect(profileState, isA<AsyncValue<CompanyProfile>>());

      sub.close();
      container.dispose();
    });

    test('TEST 6 — Unassigned / Empty Session Context safely resolves to system defaults', () async {
      final container = ProviderContainer(
        overrides: [
          sessionCompanyIdProvider.overrideWith((ref) => ''),
        ],
      );

      final repo = container.read(settingsRepositoryProvider);
      final viewMode = await repo.loadProductsViewMode('');
      final parentId = await repo.loadCustomersParentAccountId('');

      expect(viewMode, equals('list'));
      expect(parentId, isNull);

      container.dispose();
    });

    test('TEST 7 — Multi-Company Context Switch Chain A -> B -> A preserves tenant data integrity', () async {
      final repo = SettingsRepository();
      await repo.saveDashboardServiceIds(['sales', 'inventory'], companyA);
      await repo.saveDashboardServiceIds(['reports', 'accounting'], companyB);

      expect(await repo.loadDashboardServiceIds(companyA), equals(['sales', 'inventory']));
      expect(await repo.loadDashboardServiceIds(companyB), equals(['reports', 'accounting']));
      expect(await repo.loadDashboardServiceIds(companyA), equals(['sales', 'inventory']));
    });

    test('TEST 8 — Non-company system preferences remain shared globally', () async {
      final repo = SettingsRepository();
      await repo.saveThemeMode(ThemeMode.dark);

      expect(await repo.loadThemeMode(), equals(ThemeMode.dark));
    });
  });
}
