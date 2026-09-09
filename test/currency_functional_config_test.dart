import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/company/functional_currency_service.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late SettingsRepository settingsRepository;
  late AccountingDatabase db;
  late CurrencyRepositoryImpl currencyRepository;
  late FunctionalCurrencyService functionalCurrencyService;

  const companyA = 'COMPANY-UUID-AAA';
  const companyB = 'COMPANY-UUID-BBB';

  setUp(() async {
    Hive.init('./test_tmp_hive_currency_02');
    if (await Hive.boxExists(HiveBoxes.settings)) {
      await Hive.deleteBoxFromDisk(HiveBoxes.settings);
    }
    settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    settingsRepository = SettingsRepository(box: settingsBox);

    db = AccountingDatabase(executor: NativeDatabase.memory());
    currencyRepository = CurrencyRepositoryImpl(
      db,
      readCompanyId: () => companyA,
    );

    functionalCurrencyService = FunctionalCurrencyService(
      settingsRepository: settingsRepository,
      currencyRepository: currencyRepository,
      db: db,
    );

    // Seed master currencies for companyA
    await currencyRepository.upsert(
      const CurrencyDraft(
        code: 'USD',
        nameEn: 'US Dollar',
        nameAr: 'دولار أمريكي',
        symbol: '\$',
        decimalDigits: 2,
        isActive: true,
      ),
    );
    await currencyRepository.upsert(
      const CurrencyDraft(
        code: 'EUR',
        nameEn: 'Euro',
        nameAr: 'يورو',
        symbol: '€',
        decimalDigits: 2,
        isActive: true,
      ),
    );
    await currencyRepository.upsert(
      const CurrencyDraft(
        code: 'INACTIVE_CUR',
        nameEn: 'Old Currency',
        nameAr: 'عملة قديمة',
        symbol: 'O',
        decimalDigits: 2,
        isActive: false,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await settingsBox.close();
    await Hive.deleteBoxFromDisk(HiveBoxes.settings);
  });

  group('CURRENCY-02 — System and Functional Currency Configuration', () {
    test('1. No functional currency configured -> explicit CurrencyRequiredException', () async {
      // Company profile initialized with default empty currency code
      expect(
        () => functionalCurrencyService.getFunctionalCurrency(companyA),
        throwsA(isA<CurrencyRequiredException>()),
      );
    });

    test('2. Invalid currency code -> InvalidFunctionalCurrencyException', () async {
      expect(
        () => functionalCurrencyService.setFunctionalCurrency('NON_EXISTENT', companyA),
        throwsA(isA<InvalidFunctionalCurrencyException>()),
      );
    });

    test('3. Inactive functional currency -> InvalidFunctionalCurrencyException', () async {
      expect(
        () => functionalCurrencyService.setFunctionalCurrency('INACTIVE_CUR', companyA),
        throwsA(isA<InvalidFunctionalCurrencyException>()),
      );
    });

    test('4. Valid currency configured -> success', () async {
      await functionalCurrencyService.setFunctionalCurrency('USD', companyA);

      final currency = await functionalCurrencyService.getFunctionalCurrency(companyA);
      expect(currency.code, equals('USD'));
      expect(currency.nameEn, equals('US Dollar'));
      expect(currency.isActive, isTrue);
    });

    test('5. Changing currency before accounting postings -> succeeds', () async {
      await functionalCurrencyService.setFunctionalCurrency('USD', companyA);
      final initial = await functionalCurrencyService.getFunctionalCurrency(companyA);
      expect(initial.code, equals('USD'));

      // Reconfigure before postings
      await functionalCurrencyService.setFunctionalCurrency('EUR', companyA);
      final updated = await functionalCurrencyService.getFunctionalCurrency(companyA);
      expect(updated.code, equals('EUR'));
    });

    test('6. Attempting unsafe change after accounting postings -> throws FunctionalCurrencyLockedException', () async {
      await functionalCurrencyService.setFunctionalCurrency('USD', companyA);

      // Insert a posted journal entry into the database for companyA
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              uuid: '11111111-2222-3333-4444-555555555555',
              entryDate: nowMs,
              voucherNumber: 'V-001',
              voucherType: 'JV',
              currencyCode: 'USD',
              isPosted: const Value(true),
              companyId: Value(companyA),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      // Verify that changing functional currency is locked
      expect(
        () => functionalCurrencyService.setFunctionalCurrency('EUR', companyA),
        throwsA(isA<FunctionalCurrencyLockedException>()),
      );

      // Verify current currency remains USD
      final current = await functionalCurrencyService.getFunctionalCurrency(companyA);
      expect(current.code, equals('USD'));
    });

    test('7. Application restart preserves functional currency configuration', () async {
      await functionalCurrencyService.setFunctionalCurrency('USD', companyA);

      // Simulate app restart by re-instantiating service and repository
      final newSettingsRepo = SettingsRepository(box: settingsBox);
      final newService = FunctionalCurrencyService(
        settingsRepository: newSettingsRepo,
        currencyRepository: currencyRepository,
        db: db,
      );

      final currency = await newService.getFunctionalCurrency(companyA);
      expect(currency.code, equals('USD'));
    });

    test('8. Multi-tenant isolation: Company A cannot inherit Company B currency', () async {
      // Configure USD for companyA
      await functionalCurrencyService.setFunctionalCurrency('USD', companyA);

      // Seed currency for companyB repository context
      final repoB = CurrencyRepositoryImpl(db, readCompanyId: () => companyB);
      await repoB.upsert(
        const CurrencyDraft(
          code: 'SAR',
          nameEn: 'Saudi Riyal',
          nameAr: 'ريال سعودي',
          symbol: 'ر.س',
          decimalDigits: 2,
          isActive: true,
        ),
      );

      final serviceB = FunctionalCurrencyService(
        settingsRepository: settingsRepository,
        currencyRepository: repoB,
        db: db,
      );

      // Company B has NOT been configured yet -> must throw CurrencyRequiredException
      expect(
        () => serviceB.getFunctionalCurrency(companyB),
        throwsA(isA<CurrencyRequiredException>()),
      );

      // Configure Company B with SAR
      await serviceB.setFunctionalCurrency('SAR', companyB);

      // Verify independent configurations
      final curA = await functionalCurrencyService.getFunctionalCurrency(companyA);
      final curB = await serviceB.getFunctionalCurrency(companyB);

      expect(curA.code, equals('USD'));
      expect(curB.code, equals('SAR'));
    });
  });
}
