import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_currency_service.dart';

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(this.accounts, {this.readCompanyId});

  final List<Account> accounts;
  final String Function()? readCompanyId;

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    if (readCompanyId == null) return accounts;
    final currentCid = readCompanyId!();
    return accounts.where((a) => a.description?.contains('tenant:$currentCid') ?? true).toList();
  }

  @override
  Future<Account?> getByUuid(String uuid) async {
    final all = await getAll(includeInactive: true);
    for (final acc in all) {
      if (acc.uuid == uuid) return acc;
    }
    return null;
  }

  @override
  Future<Account?> getByAccountCode(String code) async {
    final all = await getAll(includeInactive: true);
    for (final acc in all) {
      if (acc.accountCode == code) return acc;
    }
    return null;
  }

  @override
  Future<List<Account>> getByType(AccountType type, {bool includeInactive = false}) async {
    final all = await getAll(includeInactive: includeInactive);
    return all.where((a) => a.accountType == type).toList();
  }


  @override
  Future<Account?> getById(int id) async => null;


  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async => [];

  @override
  Future<List<Account>> getChildren(String parentUuid) async => [];

  @override
  Future<bool> hasChildren(String uuid) async => false;

  @override
  Future<bool> isUsedInTransactions(String uuid) async => false;

  @override
  Future<Account> insert(AccountDraft draft) async => throw UnimplementedError();

  @override
  Future<Account> update(int id, AccountDraft draft) async => throw UnimplementedError();

  @override
  Future<void> deactivate(int id) async {}

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  Future<void> seedDefaultChart() async {}

  @override
  Future<List<Account>> search(String query, {bool includeInactive = false}) async => accounts;

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) => Stream.value(accounts);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late CompanyInitializationRepositoryImpl initRepository;
  late CompanyCurrencyService currencyService;
  late FakeAccountRepository fakeAccountRepo;
  late CompanyAccountingConfigService accountingConfigService;

  const currentCompanyId = 'company-yer-tenant';
  final now = DateTime.utc(2026, 8, 30);

  Account createAccount({
    required int id,
    required String uuid,
    required String accountCode,
    required String name,
    required AccountType accountType,
    required NormalBalance normalBalance,
    String? tenantCompanyId,
    bool isGroup = false,
    bool isActive = true,
    bool isDeleted = false,
  }) {
    return Account(
      id: id,
      uuid: uuid,
      accountCode: accountCode,
      name: name,
      accountType: accountType,
      normalBalance: normalBalance,
      level: 1,
      isGroup: isGroup,
      isActive: isActive,
      isSystemAccount: false,
      createdAt: now,
      updatedAt: now,
      description: tenantCompanyId != null ? 'tenant:$tenantCompanyId' : null,
      deletedAt: isDeleted ? now : null,
    );
  }

  setUp(() async {
    Hive.init('./test_hive_temp_p3');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    initRepository = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => currentCompanyId,
    );

    await initRepository.saveState(
      (await initRepository.getState()).copyWith(companyId: currentCompanyId),
    );
  });

  tearDown(() async {
    await settingsBox.clear();
  });

  group('Phase 3 — Inventory Base Currency & Accounting Configuration Tests', () {
    test('1. YER Company Setup & Inventory Base Currency', () async {
      currencyService = CompanyCurrencyService(initRepository: initRepository);

      await currencyService.configureInventoryBaseCurrency(
        currencyCode: 'YER',
      );

      final baseCurr = await currencyService.getInventoryBaseCurrency();
      expect(baseCurr, equals('YER'));
    });

    test('2. SAR Company Setup & Inventory Base Currency', () async {
      currencyService = CompanyCurrencyService(initRepository: initRepository);

      await currencyService.configureInventoryBaseCurrency(
        currencyCode: 'SAR',
      );

      final baseCurr = await currencyService.getInventoryBaseCurrency();
      expect(baseCurr, equals('SAR'));
    });

    test('3. Document Currency Conversion (100 SAR * 145 = 14,500 YER)', () {
      currencyService = CompanyCurrencyService(initRepository: initRepository);

      final convertedCost = currencyService.convertToInventoryBaseCurrency(
        documentAmount: 100.0,
        exchangeRate: 145.0,
      );

      expect(convertedCost, equals(14500.0));
    });

    test('4. Currency Conversion Rounding Accuracy', () {
      currencyService = CompanyCurrencyService(initRepository: initRepository);

      final convertedCost = currencyService.convertToInventoryBaseCurrency(
        documentAmount: 33.333,
        exchangeRate: 3.75,
        decimalPlaces: 2,
      );

      expect(convertedCost, equals(125.0));
    });

    test('5. Currency Immutability Guard — Change Rejected After Transactions', () async {
      bool hasTransactions = true;

      currencyService = CompanyCurrencyService(
        initRepository: initRepository,
        transactionChecker: (companyId) async => hasTransactions,
      );

      await currencyService.configureInventoryBaseCurrency(
        currencyCode: 'YER',
      );

      // Attempting to change to USD when transactions exist
      expect(
        () async => await currencyService.configureInventoryBaseCurrency(
          currencyCode: 'USD',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('6. Duplicate Currency Attempt Handling (Idempotent)', () async {
      currencyService = CompanyCurrencyService(initRepository: initRepository);

      await currencyService.configureInventoryBaseCurrency(
        currencyCode: 'YER',
      );

      // Re-configuring to exact same base currency succeeds
      await currencyService.configureInventoryBaseCurrency(
        currencyCode: 'YER',
      );

      final baseCurr = await currencyService.getInventoryBaseCurrency();
      expect(baseCurr, equals('YER'));
    });

    test('7. Cross-Company Account Rejection', () async {
      final validAccountOtherTenant = createAccount(
        id: 1,
        uuid: 'acc-other-001',
        tenantCompanyId: 'company-other-tenant',
        accountCode: '1230',
        name: 'Inventory Stock Other',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
      );

      fakeAccountRepo = FakeAccountRepository(
        [validAccountOtherTenant],
        readCompanyId: () => currentCompanyId,
      );
      accountingConfigService = CompanyAccountingConfigService(
        accountRepository: fakeAccountRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await accountingConfigService.saveAccountingConfig(
          mappings: {
            AccountRole.inventory: 'acc-other-001',
          },
        ),
        throwsA(isA<InvalidCompanyAccountException>()),
      );
    });

    test('8. Invalid / Non-Existent Account Rejection', () async {
      fakeAccountRepo = FakeAccountRepository([]);
      accountingConfigService = CompanyAccountingConfigService(
        accountRepository: fakeAccountRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await accountingConfigService.saveAccountingConfig(
          mappings: {
            AccountRole.inventory: 'non-existent-9999',
          },
        ),
        throwsA(isA<InvalidCompanyAccountException>().having(
          (e) => e.reason,
          'reason',
          contains('does not exist'),
        )),
      );
    });

    test('9. Disabled / Inactive Account Rejection', () async {
      final inactiveAccount = createAccount(
        id: 2,
        uuid: 'acc-inactive-001',
        accountCode: '1230',
        name: 'Inactive Inventory',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        isActive: false,
      );

      fakeAccountRepo = FakeAccountRepository([inactiveAccount]);
      accountingConfigService = CompanyAccountingConfigService(
        accountRepository: fakeAccountRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await accountingConfigService.saveAccountingConfig(
          mappings: {
            AccountRole.inventory: 'acc-inactive-001',
          },
        ),
        throwsA(isA<InvalidCompanyAccountException>().having(
          (e) => e.reason,
          'reason',
          contains('inactive'),
        )),
      );
    });

    test('10. Valid Company Accounting Configuration', () async {
      final validInventoryAcc = createAccount(
        id: 3,
        uuid: 'acc-inv-001',
        accountCode: '1230',
        name: 'Inventory Stock Main',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
      );

      final validCogsAcc = createAccount(
        id: 4,
        uuid: 'acc-cogs-001',
        accountCode: '5100',
        name: 'Cost of Goods Sold',
        accountType: AccountType.expense,
        normalBalance: NormalBalance.debit,
      );

      fakeAccountRepo = FakeAccountRepository([validInventoryAcc, validCogsAcc]);
      accountingConfigService = CompanyAccountingConfigService(
        accountRepository: fakeAccountRepo,
        initRepository: initRepository,
      );

      final savedConfig = await accountingConfigService.saveAccountingConfig(
        mappings: {
          AccountRole.inventory: 'acc-inv-001',
          AccountRole.cogs: 'acc-cogs-001',
        },
      );

      expect(savedConfig.accountMappings[AccountRole.inventory], equals('acc-inv-001'));
      expect(savedConfig.accountMappings[AccountRole.cogs], equals('acc-cogs-001'));
    });
  });
}
