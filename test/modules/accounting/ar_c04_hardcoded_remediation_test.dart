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
    return const [];
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    return const [];
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

  group('AR-C04 Hardcoded Account Remediation Verification', () {
    test('1. Valid configuration resolution through AccountBindingResolver', () async {
      final acc = const SetupAccountData(
        uuid: 'acc-cash-01',
        accountCode: '101001',
        companyId: 'companyA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(acc);

      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_account',
        role: AccountRole.cash,
        labelAr: 'حساب النقدية',
        labelEn: 'Cash Account',
        expectedAccountType: SetupAccountType.asset,
        bindingMode: AccountBindingMode.exact,
      );

      await resolver.bindAccount(
        companyId: 'companyA',
        requirement: req,
        accountUuid: 'acc-cash-01',
      );

      final resolved = await resolver.resolveAccountForTransaction(
        companyId: 'companyA',
        requirement: req,
      );

      expect(resolved.uuid, equals('acc-cash-01'));
      expect(resolved.accountCode, equals('101001'));
    });

    test('2. Rejects wrong account type at resolution time (e.g. Asset bound to Liability requirement)', () async {
      final accAsset = const SetupAccountData(
        uuid: 'acc-asset-01',
        accountCode: '123001',
        companyId: 'companyA',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(accAsset);

      final reqLiability = const AccountRequirement(
        packageId: 'accounting',
        requirementKey: 'payable_account',
        role: AccountRole.payable,
        labelAr: 'حساب الموردين',
        labelEn: 'Payable Account',
        expectedAccountType: SetupAccountType.liability,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.bindAccount(
          companyId: 'companyA',
          requirement: reqLiability,
          accountUuid: 'acc-asset-01',
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('3. Rejects cross-company account binding at transaction resolution time', () async {
      final accOtherCompany = const SetupAccountData(
        uuid: 'acc-compB-01',
        accountCode: '111001',
        companyId: 'companyB',
        accountType: SetupAccountType.asset,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(accOtherCompany);

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
          companyId: 'companyA',
          requirement: req,
          accountUuid: 'acc-compB-01',
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });

    test('4. SafetyGate rejects incorrect classification for AccountRole at posting/config time', () async {
      final accLiability = Account(
        id: 101,
        uuid: 'acc-liab-01',
        accountCode: '211001',
        name: 'حساب التزام',
        accountType: AccountType.liability,
        normalBalance: NormalBalance.credit,

        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'companyA',
      );
      accountRepo.add(accLiability);

      final invalidTarget = AccountBindingTarget.single('acc-liab-01');

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'companyA',
          role: AccountRole.cash,
          target: invalidTarget,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('5. Unconfigured requirement throws descriptive AccountBindingException at posting time', () async {
      final reqUnconfigured = const AccountRequirement(
        packageId: 'inventory',
        requirementKey: 'cogs_account',
        role: AccountRole.cogs,
        labelAr: 'حساب تكلفة المبيعات',
        labelEn: 'COGS Account',
        expectedAccountType: SetupAccountType.expense,
        bindingMode: AccountBindingMode.exact,
      );

      expect(
        () => resolver.resolveAccountForTransaction(
          companyId: 'companyA',
          requirement: reqUnconfigured,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });
  });
}
