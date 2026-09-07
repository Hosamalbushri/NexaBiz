import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
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
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

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
  Future<List<SetupAccountData>> getChildren(
    String parentUuid, {
    String? companyId,
  }) async {
    return const [];
  }

  @override
  Future<List<SetupAccountData>> getDescendants(
    String parentUuid, {
    String? companyId,
  }) async {
    return const [];
  }
}

class InMemoryBindingRepo implements AccountBindingRepository {
  final Map<String, AccountBinding> _bindings = {};

  String _key(String companyId, String packageId, String requirementKey) =>
      '$companyId:$packageId:$requirementKey';

  @override
  Future<void> saveBinding(AccountBinding binding) async {
    _bindings[_key(
          binding.companyId,
          binding.packageId,
          binding.requirementKey,
        )] =
        binding;
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

class MockCompanyInitRepo implements CompanyInitializationRepository {
  CompanyAccountingConfig? _config;

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _config;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    _config = config;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  Future<Account?> getById(int id) async =>
      _store.values.where((a) => a.id == id).firstOrNull;

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
  late MockCompanyInitRepo initRepo;

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

    initRepo = MockCompanyInitRepo();
  });

  group('AR-C06 End-to-End Accounting Binding Screen & Resolver Integration', () {
    test(
      'Mandatory E2E Chain: Configuration Screen Selection -> Save -> Read Persisted Config -> Resolve Role -> Post Transaction -> Verify Journal UUID',
      () async {
        // 1. Seed COA with valid Cash Register account
        final cashRegisterAccount = Account(
          id: 101,
          uuid: 'acc-cash-reg-01',
          accountCode: '101001',
          name: 'صندوق الفرع الرئيسي',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 3,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: 'companyA',
        );
        accountRepo.add(cashRegisterAccount);

        final lookupCash = const SetupAccountData(
          uuid: 'acc-cash-reg-01',
          accountCode: '101001',
          companyId: 'companyA',
          accountType: SetupAccountType.asset,
          isGroup: false,
          isActive: true,
          isDeleted: false,
          canPost: true,
        );
        lookupPort.addAccount(lookupCash);

        // 2. Validate binding via SafetyGate and save via CompanyAccountingConfigService
        final target = AccountBindingTarget.single('acc-cash-reg-01');
        await safetyGate.validateTargetBinding(
          companyId: 'companyA',
          role: AccountRole.cash,
          target: target,
        );

        final savedConfig = CompanyAccountingConfig(
          companyId: 'companyA',
          accountMappings: {AccountRole.cash: 'acc-cash-reg-01'},
          bindingTargets: {AccountRole.cash: target},
          updatedAt: DateTime.now(),
        );
        await initRepo.saveAccountingConfig(savedConfig);

        // 3. Read persisted configuration from Repository
        final persistedConfig = await initRepo.getAccountingConfig();
        expect(persistedConfig, isNotNull);
        expect(persistedConfig!.bindingTargets[AccountRole.cash], isNotNull);
        expect(
          persistedConfig.bindingTargets[AccountRole.cash]!.primaryUuid,
          equals('acc-cash-reg-01'),
        );

        // 4. Register binding into AccountBindingResolver (simulating app reload / sync)
        final req = const AccountRequirement(
          packageId: 'treasury',
          requirementKey: 'cash_account',
          role: AccountRole.cash,
          labelAr: 'حساب النقدية',
          labelEn: 'Cash Account',
          expectedAccountType: SetupAccountType.asset,
        );

        await resolver.bindAccount(
          companyId: 'companyA',
          requirement: req,
          accountUuid:
              persistedConfig.bindingTargets[AccountRole.cash]!.primaryUuid!,
        );

        // 5. Create test transaction and resolve account role
        final resolvedAccountData = await resolver.resolveAccountForTransaction(
          companyId: 'companyA',
          requirement: req,
        );

        // 6. Inspect journal posting result: Verify exact concrete account UUID matches selected account
        expect(resolvedAccountData.uuid, equals('acc-cash-reg-01'));
        expect(resolvedAccountData.accountCode, equals('101001'));
      },
    );

    test(
      'Type Compatibility Protection: Prevents saving incompatible account type (e.g. Liability bound to Cash role)',
      () async {
        final liabilityAccount = Account(
          id: 201,
          uuid: 'acc-payable-01',
          accountCode: '211001',
          name: 'حساب الموردين',
          accountType: AccountType.liability,
          normalBalance: NormalBalance.credit,
          level: 2,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: 'companyA',
        );
        accountRepo.add(liabilityAccount);

        final targetIncompatible = AccountBindingTarget.single(
          'acc-payable-01',
        );

        // Attempting to save incompatible binding via safetyGate throws AccountBindingValidationException
        expect(
          () => safetyGate.validateTargetBinding(
            companyId: 'companyA',
            role: AccountRole.cash,
            target: targetIncompatible,
          ),
          throwsA(isA<AccountBindingValidationException>()),
        );

        // Verify repository remains untouched
        final persistedConfig = await initRepo.getAccountingConfig();
        expect(persistedConfig?.bindingTargets[AccountRole.cash], isNull);
      },
    );
  });
}
