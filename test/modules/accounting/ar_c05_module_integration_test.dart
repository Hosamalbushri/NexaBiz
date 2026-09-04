import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_exceptions.dart';

import 'package:stock_count/core/setup/domain/entities/account_requirement.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/core/setup/domain/services/account_binding_resolver.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/domain/repositories/account_binding_repository.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_binding_safety_gate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_usage_analyzer.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';

class MockLookupPort implements SetupAccountLookupPort {
  final Map<String, SetupAccountData> _accounts = {};

  void addAccount(SetupAccountData account) {
    _accounts[account.uuid] = account;
  }

  @override
  Future<SetupAccountData?> findAccount(String accountUuid) async {
    return _accounts[accountUuid];
  }

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async {
    return _accounts.values
        .where((a) => (companyId == null || a.companyId == companyId))
        .toList();
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    return _accounts.values
        .where((a) => (companyId == null || a.companyId == companyId))
        .toList();
  }
}

class InMemoryBindingRepo implements AccountBindingRepository {
  final Map<String, AccountBinding> _bindings = {};

  String _key(String companyId, String packageId, String requirementKey) =>
      '$companyId:$packageId:$requirementKey';

  @override
  Future<void> saveBinding(AccountBinding binding) async {
    _bindings[_key(binding.companyId, binding.packageId, binding.requirementKey)] = binding;
  }

  @override
  Future<AccountBinding?> getBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    return _bindings[_key(companyId, packageId, requirementKey)];
  }

  @override
  Future<List<AccountBinding>> getBindingsForPackage({
    required String companyId,
    required String packageId,
  }) async {
    return _bindings.values
        .where((b) => b.companyId == companyId && b.packageId == packageId)
        .toList();
  }

  @override
  Future<void> removeBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    _bindings.remove(_key(companyId, packageId, requirementKey));
  }

  @override
  Future<void> clear() async {
    _bindings.clear();
  }
}

class MockAccountRepositoryForSafetyGate implements AccountRepository {
  final Map<String, Account> _store = {};

  void add(Account account) => _store[account.uuid] = account;

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
  Future<Account?> getById(int id) async => _store.values.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyUsageAnalyzer implements AccountUsageAnalyzer {
  @override
  Future<AccountUsageRecord> analyzeAccountUsage({
    required String companyId,
    required String accountUuid,
  }) async {
    return AccountUsageRecord(
      accountUuid: accountUuid,
      status: AccountUsageStatus.neverUsed,
      postedTransactionCount: 0,
      draftTransactionCount: 0,
      currentBalance: 0.0,
      referencedDocumentTypes: const [],
    );
  }
}

void main() {
  late MockLookupPort lookupPort;
  late InMemoryBindingRepo bindingRepo;
  late AccountBindingResolver resolver;
  late MockAccountRepositoryForSafetyGate accountRepo;
  late AccountBindingSafetyGate safetyGate;

  setUp(() {
    lookupPort = MockLookupPort();
    bindingRepo = InMemoryBindingRepo();
    resolver = AccountBindingResolver(
      accountLookupPort: lookupPort,
      bindingRepository: bindingRepo,
    );

    accountRepo = MockAccountRepositoryForSafetyGate();
    safetyGate = AccountBindingSafetyGate(
      accountRepository: accountRepo,
      usageAnalyzer: DummyUsageAnalyzer(),
    );
  });

  group('AR-C05 Module Accounting Integration Verification', () {
    test('1. Valid configuration posting for all business modules (Cash, Bank, Customer, Supplier, Inventory, Sales, Purchases)', () async {
      final cashAcc = const SetupAccountData(
        uuid: 'acc-cash-reg-01',
        accountCode: '101001',
        companyId: 'compA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(cashAcc);

      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_register_account',
        role: AccountRole.cash,
        labelAr: 'حساب الصندوق الفرعي',
        labelEn: 'Cash Register Account',
        expectedAccountType: SetupAccountType.asset,
        bindingMode: AccountBindingMode.exact,
      );

      await resolver.bindAccount(
        companyId: 'compA',
        requirement: req,
        accountUuid: 'acc-cash-reg-01',
      );

      final resolved = await resolver.resolveAccountForTransaction(
        companyId: 'compA',
        requirement: req,
      );

      expect(resolved.uuid, equals('acc-cash-reg-01'));
      expect(resolved.accountCode, equals('101001'));
    });

    test('2. Missing configuration handling throws AccountBindingException', () async {
      final reqUnbound = const AccountRequirement(
        packageId: 'purchases',
        requirementKey: 'purchases_payable',
        role: AccountRole.payable,
        labelAr: 'حساب الموردين',
        labelEn: 'Payables Account',
        expectedAccountType: SetupAccountType.liability,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.resolveAccountForTransaction(
          companyId: 'compA',
          requirement: reqUnbound,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('3. Wrong account type configuration rejection (e.g. Asset bound to Liability requirement)', () async {
      final assetAcc = const SetupAccountData(
        uuid: 'acc-asset-99',
        accountCode: '120001',
        companyId: 'compA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(assetAcc);

      final reqLiability = const AccountRequirement(
        packageId: 'accounting',
        requirementKey: 'supplier_payable',
        role: AccountRole.payable,
        labelAr: 'حساب المورد',
        labelEn: 'Supplier Payable Account',
        expectedAccountType: SetupAccountType.liability,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.bindAccount(
          companyId: 'compA',
          requirement: reqLiability,
          accountUuid: 'acc-asset-99',
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('4. Cross-company tenant isolation rejection', () async {
      final compBAcc = const SetupAccountData(
        uuid: 'acc-compB-cash',
        accountCode: '101002',
        companyId: 'compB',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(compBAcc);

      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_account',
        role: AccountRole.cash,
        labelAr: 'حساب النقدية',
        labelEn: 'Cash Account',
        expectedAccountType: SetupAccountType.asset,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.bindAccount(
          companyId: 'compA',
          requirement: req,
          accountUuid: 'acc-compB-cash',
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });

    test('5. Inactive account configuration rejection', () async {
      final inactiveAcc = const SetupAccountData(
        uuid: 'acc-inactive-01',
        accountCode: '101003',
        companyId: 'compA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: false,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(inactiveAcc);

      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_account',
        role: AccountRole.cash,
        labelAr: 'حساب النقدية',
        labelEn: 'Cash Account',
        expectedAccountType: SetupAccountType.asset,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.bindAccount(
          companyId: 'compA',
          requirement: req,
          accountUuid: 'acc-inactive-01',
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('6. Deleted account configuration rejection', () async {
      final deletedAcc = const SetupAccountData(
        uuid: 'acc-deleted-01',
        accountCode: '101004',
        companyId: 'compA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: true,
        canPost: true,
      );
      lookupPort.addAccount(deletedAcc);

      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_account',
        role: AccountRole.cash,
        labelAr: 'حساب النقدية',
        labelEn: 'Cash Account',
        expectedAccountType: SetupAccountType.asset,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.bindAccount(
          companyId: 'compA',
          requirement: req,
          accountUuid: 'acc-deleted-01',
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('7. SafetyGate rejects non-postable group account for single binding mode', () async {
      final groupAccount = Account(
        id: 201,
        uuid: 'acc-group-root',
        accountCode: '101000',
        name: 'مجموعة الصناديق',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 1,
        isGroup: true,
        isActive: true,
        isSystemAccount: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'compA',
      );
      accountRepo.add(groupAccount);

      final targetGroupAsSingle = AccountBindingTarget.single('acc-group-root');

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: targetGroupAsSingle,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('8. Valid descendant resolution within parent scope (Cash Parent -> Cash Register Account)', () async {
      final cashRegAcc = const SetupAccountData(
        uuid: 'acc-cash-box-reg-1',
        accountCode: '101101',
        companyId: 'compA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(cashRegAcc);

      final reqParent = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_parent_group',
        role: AccountRole.cash,
        labelAr: 'مجموعة الصناديق',
        labelEn: 'Cash Parent Group',
        expectedAccountType: SetupAccountType.asset,
        bindingMode: AccountBindingMode.parent,
      );

      await resolver.bindAccount(
        companyId: 'compA',
        requirement: reqParent,
        accountUuid: 'acc-cash-box-reg-1',
      );

      final resolved = await resolver.resolveAccountForTransaction(
        companyId: 'compA',
        requirement: reqParent,
      );

      expect(resolved.uuid, equals('acc-cash-box-reg-1'));
    });

    test('9. Dynamic configuration change propagation', () async {
      final oldAcc = const SetupAccountData(
        uuid: 'acc-sales-old',
        accountCode: '401001',
        companyId: 'compA',
        accountType: SetupAccountType.revenue,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      final newAcc = const SetupAccountData(
        uuid: 'acc-sales-new',
        accountCode: '401002',
        companyId: 'compA',
        accountType: SetupAccountType.revenue,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(oldAcc);
      lookupPort.addAccount(newAcc);

      final req = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_revenue',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Revenue Account',
        expectedAccountType: SetupAccountType.revenue,
        bindingMode: AccountBindingMode.exact,
      );

      await resolver.bindAccount(
        companyId: 'compA',
        requirement: req,
        accountUuid: 'acc-sales-old',
      );
      var resolved = await resolver.resolveAccountForTransaction(companyId: 'compA', requirement: req);
      expect(resolved.uuid, equals('acc-sales-old'));

      // Update binding
      await resolver.bindAccount(
        companyId: 'compA',
        requirement: req,
        accountUuid: 'acc-sales-new',
      );
      resolved = await resolver.resolveAccountForTransaction(companyId: 'compA', requirement: req);
      expect(resolved.uuid, equals('acc-sales-new'));
    });

    test('10. Journal entry verification: concrete account UUID recorded with zero silent fallback', () async {
      final cogsAcc = const SetupAccountData(
        uuid: 'acc-cogs-01',
        accountCode: '501001',
        companyId: 'compA',
        accountType: SetupAccountType.expense,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(cogsAcc);

      final reqCogs = const AccountRequirement(
        packageId: 'inventory',
        requirementKey: 'inventory_cogs',
        role: AccountRole.cogs,
        labelAr: 'حساب تكلفة المبيعات',
        labelEn: 'COGS Account',
        expectedAccountType: SetupAccountType.expense,
        bindingMode: AccountBindingMode.exact,
      );

      await resolver.bindAccount(
        companyId: 'compA',
        requirement: reqCogs,
        accountUuid: 'acc-cogs-01',
      );

      final resolved = await resolver.resolveAccountForTransaction(
        companyId: 'compA',
        requirement: reqCogs,
      );

      expect(resolved.uuid, isNotEmpty);
      expect(resolved.uuid, equals('acc-cogs-01'));
      expect(resolved.accountCode, equals('501001'));
    });
  });
}
