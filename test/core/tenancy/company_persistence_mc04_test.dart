import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepository repository;
  const companyA = 'cmp_alpha_111';
  const companyB = 'cmp_beta_222';

  setUpAll(() async {
    Hive.init('./test_hive_mc04');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    final box = await Hive.openBox<dynamic>('app_settings');
    await box.clear();
    repository = SettingsRepository();
  });

  group('Phase MC-04 — Tenant-Scoped Persistence & Hive Hardening Tests', () {
    test('TEST 1 — Company A setting differs from B', () async {
      await repository.saveProductsViewMode('grid', companyA);
      await repository.saveProductsViewMode('list', companyB);

      final modeA = await repository.loadProductsViewMode(companyA);
      final modeB = await repository.loadProductsViewMode(companyB);

      expect(modeA, equals('grid'));
      expect(modeB, equals('list'));
      expect(modeA, isNot(equals(modeB)));
    });

    test('TEST 2 — Switching A -> B returns B setting', () async {
      await repository.saveCustomersAutoLinkAccount(false, companyA);
      await repository.saveCustomersAutoLinkAccount(true, companyB);

      expect(await repository.loadCustomersAutoLinkAccount(companyA), isFalse);
      expect(await repository.loadCustomersAutoLinkAccount(companyB), isTrue);
    });

    test('TEST 3 — Switching B -> A returns A setting', () async {
      await repository.saveCustomersParentAccountId('acc_uuid_alpha_99', companyA);
      await repository.saveCustomersParentAccountId('acc_uuid_beta_88', companyB);

      expect(await repository.loadCustomersParentAccountId(companyB), equals('acc_uuid_beta_88'));
      expect(await repository.loadCustomersParentAccountId(companyA), equals('acc_uuid_alpha_99'));
    });

    test('TEST 4 — Missing B setting does not return A setting', () async {
      await repository.saveCustomersParentAccountId('acc_uuid_alpha_99', companyA);

      final parentB = await repository.loadCustomersParentAccountId(companyB);
      expect(parentB, isNull, reason: 'Missing Company B setting MUST NOT leak Company A account ID');
    });

    test('TEST 5 — Company A account ID cannot be loaded in B', () async {
      await repository.saveCustomersParentAccountId('account_uuid_company_a', companyA);

      final accountIdInB = await repository.loadCustomersParentAccountId(companyB);
      expect(accountIdInB, isNull);
    });

    test('TEST 6 — Legacy global setting migration is deterministic', () async {
      final box = await Hive.openBox<dynamic>('app_settings');
      await box.put(SettingsKeys.productsViewMode, 'grid');

      final modeC = await repository.loadProductsViewMode('cmp_gamma_333');
      expect(modeC, equals('grid'));

      await repository.saveProductsViewMode('list', 'cmp_gamma_333');

      expect(await repository.loadProductsViewMode('cmp_gamma_333'), equals('list'));
      expect(box.get(SettingsKeys.productsViewMode), equals('grid'), reason: 'Global key untouched');
    });

    test('TEST 7 — Stale configuration does not crash startup', () async {
      final box = await Hive.openBox<dynamic>('app_settings');
      await box.put('${SettingsKeys.customersParentAccountId}_$companyA', 12345);

      final loaded = await repository.loadCustomersParentAccountId(companyA);
      expect(loaded, isNull, reason: 'Corrupted / stale configuration must return null cleanly without crashing');
    });

    test('TEST 8 — System-scoped values remain global where appropriate', () async {
      await repository.saveThemeMode(ThemeMode.dark);
      await repository.saveLocale(const Locale('ar'));

      expect(await repository.loadThemeMode(), equals(ThemeMode.dark));
      final locale = await repository.loadLocale();
      expect(locale?.languageCode, equals('ar'));
    });
  });
}
