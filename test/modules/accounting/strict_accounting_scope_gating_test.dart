import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/customers/accounting_customer_account_link_adapter.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_treasury_adapter.dart';
import 'package:stock_count/app/sales/accounting_sale_treasury_adapter.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_scope_resolver.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class MockInitRepo implements CompanyInitializationRepository {
  CompanyAccountingConfig? config;
  String currentCompanyId = 'comp_A';

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => config;

  @override
  Future<CompanyInitializationState> getState() async {
    return CompanyInitializationState(
      companyId: currentCompanyId,
      accountingConfigured: config != null,
      warehouseConfigured: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAccountRepo implements AccountRepository {
  final Map<String, Account> _store = {};

  void add(Account account) => _store[account.uuid] = account;
  void clear() => _store.clear();

  @override
  Future<Account?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async {
    return _store.values.where((a) => a.accountCode == code).firstOrNull;
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    if (includeInactive) return _store.values.toList();
    return _store.values.where((a) => a.isActive && !a.isDeleted).toList();
  }

  @override
  Future<List<Account>> getChildren(String parentUuid) async {
    return _store.values
        .where((a) => a.parentId == parentUuid && a.isActive && !a.isDeleted)
        .toList();
  }

  @override
  Future<Account?> getById(int id) async =>
      _store.values.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Account createCoaAcc({
  required int id,
  required String uuid,
  required String code,
  required String name,
  required AccountType accountType,
  required String companyId,
  String? parentId,
  bool isGroup = false,
  bool isActive = true,
  bool isDeleted = false,
}) {
  return Account(
    id: id,
    uuid: uuid,
    accountCode: code,
    name: name,
    accountType: accountType,
    normalBalance: accountType.normalBalance,
    parentId: parentId,
    level: parentId == null ? 1 : 2,
    isGroup: isGroup,
    isActive: isActive,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    deletedAt: isDeleted ? DateTime.now() : null,
  );
}

void main() {
  group('AR-C05.1 — Strict Accounting Scope Gating Matrix (Tests A through L)', () {
    late MockAccountRepo accountRepo;
    late MockInitRepo initRepo;
    late AccountingScopeResolver scopeResolver;

    const companyA = 'comp_A';
    const companyB = 'comp_B';

    setUp(() {
      accountRepo = MockAccountRepo();
      initRepo = MockInitRepo();
      scopeResolver = AccountingScopeResolver(
        accountRepository: accountRepo,
        initRepository: initRepo as dynamic,
      );

      // Seed standard Chart of Accounts
      // Cash Parent Group & Descendants
      accountRepo.add(
        createCoaAcc(
          id: 1,
          uuid: 'grp-cash-01',
          code: '101000',
          name: 'مظلة الصناديق',
          accountType: AccountType.asset,
          companyId: companyA,
          isGroup: true,
        ),
      );
      accountRepo.add(
        createCoaAcc(
          id: 2,
          uuid: 'acc-cash-main',
          code: '101001',
          name: 'الصندوق الرئيسي',
          accountType: AccountType.asset,
          companyId: companyA,
          parentId: 'grp-cash-01',
        ),
      );
      accountRepo.add(
        createCoaAcc(
          id: 3,
          uuid: 'acc-cash-petty',
          code: '101002',
          name: 'صندوق المصروفات',
          accountType: AccountType.asset,
          companyId: companyA,
          parentId: 'grp-cash-01',
        ),
      );

      // Customer/Receivable Parent Group & Descendants
      accountRepo.add(
        createCoaAcc(
          id: 4,
          uuid: 'grp-rec-01',
          code: '102000',
          name: 'مظلة العملاء A',
          accountType: AccountType.asset,
          companyId: companyA,
          isGroup: true,
        ),
      );
      accountRepo.add(
        createCoaAcc(
          id: 5,
          uuid: 'acc-rec-cust1',
          code: '102001',
          name: 'العميل الأول',
          accountType: AccountType.asset,
          companyId: companyA,
          parentId: 'grp-rec-01',
        ),
      );

      // Scope B for Group B
      accountRepo.add(
        createCoaAcc(
          id: 6,
          uuid: 'grp-cash-02',
          code: '101900',
          name: 'مظلة الصناديق B',
          accountType: AccountType.asset,
          companyId: companyA,
          isGroup: true,
        ),
      );
      accountRepo.add(
        createCoaAcc(
          id: 7,
          uuid: 'acc-cash-scopeB',
          code: '101901',
          name: 'صندوق نطاق B',
          accountType: AccountType.asset,
          companyId: companyA,
          parentId: 'grp-cash-02',
        ),
      );
    });

    test(
      'TEST A: Unconfigured Cash Role → Returns NOT_CONFIGURED and Empty Accounts List',
      () async {
        initRepo.config = null; // Unconfigured

        final result = await scopeResolver.resolveScope(
          companyId: companyA,
          role: AccountRole.cash,
        );

        expect(result.status, equals(AccountingScopeStatus.notConfigured));
        expect(result.isReady, isFalse);
        expect(result.accounts, isEmpty);

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );
        final cashBoxes = await salesAdapter.listCashBoxAccounts();
        expect(cashBoxes, isEmpty);

        final defaultBox = await salesAdapter.findDefaultCashBox();
        expect(defaultBox, isNull);
      },
    );

    test(
      'TEST B: Configured Cash Parent Account → Returns Eligible Descendants of Parent Only',
      () async {
        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {AccountRole.cash: 'grp-cash-01'},
        );

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );
        final cashBoxes = await salesAdapter.listCashBoxAccounts();

        expect(cashBoxes.length, equals(2));
        expect(
          cashBoxes.map((c) => c.accountId),
          containsAll(['acc-cash-main', 'acc-cash-petty']),
        );
        expect(
          cashBoxes.map((c) => c.accountId),
          isNot(contains('acc-cash-scopeB')),
        );
      },
    );

    test(
      'TEST C: Unconfigured Customer Role → findSystemCustomersParent returns null & search returns []',
      () async {
        initRepo.config = null;

        final custAdapter = AccountingCustomerAccountLinkAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );

        final parent = await custAdapter.findSystemCustomersParent();
        expect(parent, isNull);

        final searchResults = await custAdapter.search('العميل');
        expect(searchResults, isEmpty);
      },
    );

    test(
      'TEST D: Configured Customer Parent → Search and Lookup Return Only Scoped Descendants',
      () async {
        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {AccountRole.receivable: 'grp-rec-01'},
        );

        final custAdapter = AccountingCustomerAccountLinkAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );

        final parent = await custAdapter.findSystemCustomersParent();
        expect(parent, isNotNull);
        expect(parent!.accountId, equals('grp-rec-01'));

        final searchResults = await custAdapter.search('العميل');
        expect(searchResults.length, equals(1));
        expect(searchResults.first.accountId, equals('acc-rec-cust1'));
      },
    );

    test(
      'TEST E: Unconfigured Supplier Role → Returns NOT_CONFIGURED',
      () async {
        initRepo.config = null;

        final result = await scopeResolver.resolveScope(
          companyId: companyA,
          role: AccountRole.payable,
        );

        expect(result.status, equals(AccountingScopeStatus.notConfigured));
        expect(result.isReady, isFalse);
      },
    );

    test(
      'TEST F: Configured Supplier Parent → Returns Only Descendants Under Supplier Scope',
      () async {
        accountRepo.add(
          createCoaAcc(
            id: 8,
            uuid: 'grp-pay-01',
            code: '201000',
            name: 'مظلة الموردين',
            accountType: AccountType.liability,
            companyId: companyA,
            isGroup: true,
          ),
        );
        accountRepo.add(
          createCoaAcc(
            id: 9,
            uuid: 'acc-pay-supp1',
            code: '201001',
            name: 'المورد الأول',
            accountType: AccountType.liability,
            companyId: companyA,
            parentId: 'grp-pay-01',
          ),
        );

        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {AccountRole.payable: 'grp-pay-01'},
        );

        final result = await scopeResolver.resolveScope(
          companyId: companyA,
          role: AccountRole.payable,
        );

        expect(result.isReady, isTrue);
        expect(result.accounts.length, equals(1));
        expect(result.accounts.first.uuid, equals('acc-pay-supp1'));
      },
    );

    test(
      'TEST G & H: Receipts & Payments Treasury Without Configuration → Returns Empty List',
      () async {
        initRepo.config = null;

        final rpAdapter = AccountingRpTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );

        final cashBoxes = await rpAdapter.listCashBoxAccounts();
        expect(cashBoxes, isEmpty);

        final searchResults = await rpAdapter.searchPostingAccounts('صندوق');
        expect(searchResults, isEmpty);

        final defaultCash = await rpAdapter.findDefaultCashBox();
        expect(defaultCash, isNull);
      },
    );

    test(
      'TEST I: Configuration Removed → State Immediately Transitions to NOT_CONFIGURED & Returns Empty',
      () async {
        // 1. Configured
        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {AccountRole.cash: 'grp-cash-01'},
        );

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );
        var cashBoxes = await salesAdapter.listCashBoxAccounts();
        expect(cashBoxes.isNotEmpty, isTrue);

        // 2. Configuration Removed
        initRepo.config = null;

        cashBoxes = await salesAdapter.listCashBoxAccounts();
        expect(cashBoxes, isEmpty);
      },
    );

    test(
      'TEST J: Configuration Changed (Scope A → Scope B) → Scope A Accounts Disappear & Scope B Returned',
      () async {
        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );

        // 1. Configured to Scope A
        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {AccountRole.cash: 'grp-cash-01'},
        );
        var cashBoxes = await salesAdapter.listCashBoxAccounts();
        expect(cashBoxes.map((c) => c.accountId), contains('acc-cash-main'));
        expect(
          cashBoxes.map((c) => c.accountId),
          isNot(contains('acc-cash-scopeB')),
        );

        // 2. Switched to Scope B
        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {AccountRole.cash: 'grp-cash-02'},
        );

        cashBoxes = await salesAdapter.listCashBoxAccounts();
        expect(cashBoxes.map((c) => c.accountId), contains('acc-cash-scopeB'));
        expect(
          cashBoxes.map((c) => c.accountId),
          isNot(contains('acc-cash-main')),
        );
      },
    );

    test(
      'TEST K: Multi-Company Isolation → Company B Query Cannot Access Company A Configured Scope',
      () async {
        accountRepo.add(
          createCoaAcc(
            id: 10,
            uuid: 'grp-compB-cash',
            code: '101000',
            name: 'صناديق شركة B',
            accountType: AccountType.asset,
            companyId: companyB,
            isGroup: true,
          ),
        );

        initRepo.config = const CompanyAccountingConfig(
          companyId: companyA,
          accountMappings: {
            AccountRole.cash: 'grp-cash-01', // Belongs to companyA
          },
        );

        // Querying as companyB
        final result = await scopeResolver.resolveScope(
          companyId: companyB,
          role: AccountRole.cash,
        );

        expect(result.status, equals(AccountingScopeStatus.invalid));
        expect(
          result.errorMessage,
          contains('Cross-company account assignment rejected'),
        );
      },
    );

    test(
      'TEST L: Default COA Seeded but Unconfigured → Module Displays NOT_CONFIGURED & Zero Data',
      () async {
        // Seeded accounts exist in repo, but company accounting configuration is missing
        initRepo.config = null;

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );
        final rpAdapter = AccountingRpTreasuryAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );
        final custAdapter = AccountingCustomerAccountLinkAdapter(
          accountRepo,
          initRepository: initRepo as dynamic,
        );

        expect(await salesAdapter.listCashBoxAccounts(), isEmpty);
        expect(await rpAdapter.listCashBoxAccounts(), isEmpty);
        expect(await rpAdapter.searchPostingAccounts(''), isEmpty);
        expect(await custAdapter.findSystemCustomersParent(), isNull);
        expect(await custAdapter.search(''), isEmpty);
      },
    );
  });
}
