import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_currency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> box;
  late AccountingDatabase db;
  String activeCompanyId = 'company-A';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_phase_4');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AccountingDatabase.memory();

    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      box = Hive.box<dynamic>(HiveBoxes.settings);
      await box.clear();
    } else {
      box = await Hive.openBox<dynamic>(HiveBoxes.settings);
      await box.clear();
    }
    activeCompanyId = 'company-A';
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  CompanyInitializationRepositoryImpl createInitRepo() {
    return CompanyInitializationRepositoryImpl(
      box: box,
      readCompanyId: () => activeCompanyId,
    );
  }

  AccountRepositoryImpl createAccountRepo() {
    return AccountRepositoryImpl(
      db,
      readCompanyId: () => activeCompanyId,
    );
  }

  group('Phase 4 — Company, Inventory Currency & Accounting Initialization Tests', () {
    test('1. Multi-Tenant Isolation: Company A (YER, A1/A2) vs Company B (SAR, B1/B2)', () async {
      // Setup Company A
      final initRepoA = CompanyInitializationRepositoryImpl(
        box: box,
        readCompanyId: () => 'company-A',
      );
      final accountRepoA = AccountRepositoryImpl(
        db,
        readCompanyId: () => 'company-A',
      );

      await initRepoA.saveState(
        const CompanyInitializationState(
          companyId: 'company-A',
          companyCreated: true,
        ),
      );

      final accA1 = await accountRepoA.insert(
        const AccountDraft(
          accountCode: '1210-A',
          name: 'Inventory Company A',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final accA2 = await accountRepoA.insert(
        const AccountDraft(
          accountCode: '5110-A',
          name: 'COGS Company A',
          accountType: AccountType.expense,
          isGroup: false,
        ),
      );

      final currencyServiceA = CompanyCurrencyService(initRepository: initRepoA);
      await currencyServiceA.configureInventoryBaseCurrency(currencyCode: 'YER');

      // Setup Company B
      final initRepoB = CompanyInitializationRepositoryImpl(
        box: box,
        readCompanyId: () => 'company-B',
      );
      final accountRepoB = AccountRepositoryImpl(
        db,
        readCompanyId: () => 'company-B',
      );

      await initRepoB.saveState(
        const CompanyInitializationState(
          companyId: 'company-B',
          companyCreated: true,
        ),
      );

      final accB1 = await accountRepoB.insert(
        const AccountDraft(
          accountCode: '1210-B',
          name: 'Inventory Company B',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final accB2 = await accountRepoB.insert(
        const AccountDraft(
          accountCode: '5110-B',
          name: 'COGS Company B',
          accountType: AccountType.expense,
          isGroup: false,
        ),
      );

      final currencyServiceB = CompanyCurrencyService(initRepository: initRepoB);
      await currencyServiceB.configureInventoryBaseCurrency(currencyCode: 'SAR');

      // Verify Complete Isolation
      expect(await currencyServiceA.getInventoryBaseCurrency(), equals('YER'));
      expect(await currencyServiceB.getInventoryBaseCurrency(), equals('SAR'));

      expect(accA1.companyId, equals('company-A'));
      expect(accB1.companyId, equals('company-B'));

      // Company A cannot access Company B accounts through account repository
      expect(await accountRepoA.getByUuid(accB1.uuid), isNull);

      // Company B cannot access Company A accounts through account repository
      expect(await accountRepoB.getByUuid(accA1.uuid), isNull);
    });

    test('2. Currency Conversion: Document 100 SAR * 145 Exchange Rate -> 14,500 YER Cost', () {
      final currencyService = CompanyCurrencyService(initRepository: createInitRepo());

      final cost = currencyService.convertToInventoryBaseCurrency(
        documentAmount: 100.0,
        exchangeRate: 145.0,
      );

      expect(cost, equals(14500.00));
    });

    test('3. Invalid Account: Assigning non-existent account fails validation', () async {
      activeCompanyId = 'company-A';
      final initRepo = createInitRepo();
      final accountRepo = createAccountRepo();
      final configService = CompanyAccountingConfigService(
        accountRepository: accountRepo,
        initRepository: initRepo,
      );

      expect(
        () => configService.validateAccountForRole(
          companyId: 'company-A',
          role: AccountRole.inventory,
          accountCodeOrUuid: 'NON_EXISTENT_ACC',
        ),
        throwsA(isA<InvalidCompanyAccountException>()),
      );
    });

    test('4. Disabled Account: Assigning inactive account fails validation', () async {
      activeCompanyId = 'company-A';
      final initRepo = createInitRepo();
      final accountRepo = createAccountRepo();

      final inactiveAcc = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1299-INACTIVE',
          name: 'Inactive Inventory',
          accountType: AccountType.asset,
          isGroup: false,
          isActive: false,
        ),
      );

      final configService = CompanyAccountingConfigService(
        accountRepository: accountRepo,
        initRepository: initRepo,
      );

      expect(
        () => configService.validateAccountForRole(
          companyId: 'company-A',
          role: AccountRole.inventory,
          accountCodeOrUuid: inactiveAcc.uuid,
        ),
        throwsA(
          isA<InvalidCompanyAccountException>().having(
            (e) => e.reason,
            'reason',
            contains('inactive'),
          ),
        ),
      );
    });

    test('5. Cross-Company Account: Reject cross-company account assignment', () async {
      // Create account in Company B
      activeCompanyId = 'company-B';
      final accountRepoB = createAccountRepo();
      final accB = await accountRepoB.insert(
        const AccountDraft(
          accountCode: '1210-COMPANY-B',
          name: 'Company B Inventory Account',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      // Attempt to assign Company B's account to Company A
      activeCompanyId = 'company-A';
      final initRepoA = createInitRepo();
      final accountRepoA = createAccountRepo();
      final configServiceA = CompanyAccountingConfigService(
        accountRepository: accountRepoA,
        initRepository: initRepoA,
      );

      expect(
        () => configServiceA.validateAccountForRole(
          companyId: 'company-A',
          role: AccountRole.inventory,
          accountCodeOrUuid: accB.uuid,
        ),
        throwsA(isA<InvalidCompanyAccountException>()),
      );
    });

    test('6. Currency Immutability: Reject base currency modification after transactions exist', () async {
      activeCompanyId = 'company-A';
      final initRepo = createInitRepo();

      await initRepo.saveState(
        const CompanyInitializationState(
          companyId: 'company-A',
          companyCreated: true,
        ),
      );

      // Set initial currency
      bool hasTransactions = false;
      final currencyService = CompanyCurrencyService(
        initRepository: initRepo,
        transactionChecker: (cId) async => hasTransactions,
      );

      await currencyService.configureInventoryBaseCurrency(currencyCode: 'YER');
      expect(await currencyService.getInventoryBaseCurrency(), equals('YER'));

      // Simulate transactions created for Company A
      hasTransactions = true;

      // Attempting to change currency must be rejected
      expect(
        () => currencyService.configureInventoryBaseCurrency(currencyCode: 'USD'),
        throwsA(isA<StateError>()),
      );

      // Currency remains YER
      expect(await currencyService.getInventoryBaseCurrency(), equals('YER'));
    });
  });
}
