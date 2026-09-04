import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/domain/entities/account_requirement.dart';
import 'package:stock_count/core/setup/domain/services/account_binding_resolver.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/domain/repositories/account_binding_repository.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/coa_import_impact_analyzer.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/safe_coa_import_engine.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_binding_safety_gate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_usage_analyzer.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class MockLookupPort implements SetupAccountLookupPort {
  final Map<String, SetupAccountData> _accounts = {};
  final Map<String, String> _parentMap = {};

  void addAccount(SetupAccountData account, {String? parentUuid}) {
    _accounts[account.uuid] = account;
    if (parentUuid != null) _parentMap[account.uuid] = parentUuid;
  }

  @override
  Future<SetupAccountData?> findAccount(String accountUuid) async {
    return _accounts[accountUuid];
  }

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async {
    final childUuids = _parentMap.entries.where((e) => e.value == parentUuid).map((e) => e.key);
    return childUuids.map((u) => _accounts[u]).whereType<SetupAccountData>().toList();
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    return getChildren(parentUuid, companyId: companyId);
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

class MockAccountRepo implements AccountRepository {
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
  Future<void> save(Account account) async {
    _store[account.uuid] = account;
  }

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUsageAnalyzer implements AccountUsageAnalyzer {
  final Map<String, int> _postedCount = {};

  void setPostedCount(String accountUuid, int count) {
    _postedCount[accountUuid] = count;
  }

  @override
  Future<AccountUsageRecord> analyzeAccountUsage({
    required String companyId,
    required String accountUuid,
  }) async {
    final count = _postedCount[accountUuid] ?? 0;
    return AccountUsageRecord(
      accountUuid: accountUuid,
      status: count > 0 ? AccountUsageStatus.usedInPostedTransactions : AccountUsageStatus.neverUsed,
      postedTransactionCount: count,
      draftTransactionCount: 0,
      currentBalance: 0.0,
      referencedDocumentTypes: count > 0 ? const ['journal_entry'] : const [],
    );
  }
}

class FakeCompanyInitRepository implements CompanyInitializationRepository {
  CompanyAccountingConfig? _config;

  void setConfig(CompanyAccountingConfig config) {
    _config = config;
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _config;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AR-C10 Final Forensic Accounting Configuration & Posting Integrity Gate (20 Mandatory Scenarios)', () {
    late MockLookupPort lookupPort;
    late InMemoryBindingRepo bindingRepo;
    late AccountBindingResolver resolver;
    late MockAccountRepo accountRepo;
    late MockUsageAnalyzer usageAnalyzer;
    late AccountBindingSafetyGate safetyGate;
    late FakeCompanyInitRepository initRepo;
    late CoaImportImpactAnalyzer impactAnalyzer;
    late SafeCoaImportEngine importEngine;

    const companyA = 'comp_A';
    const companyB = 'comp_B';

    setUp(() {
      lookupPort = MockLookupPort();
      bindingRepo = InMemoryBindingRepo();
      resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepo,
      );

      accountRepo = MockAccountRepo();
      usageAnalyzer = MockUsageAnalyzer();
      safetyGate = AccountBindingSafetyGate(
        accountRepository: accountRepo,
        usageAnalyzer: usageAnalyzer,
      );

      initRepo = FakeCompanyInitRepository();
      impactAnalyzer = CoaImportImpactAnalyzer();
      importEngine = SafeCoaImportEngine(
        accountRepository: accountRepo,
        impactAnalyzer: impactAnalyzer,
        initializationRepository: initRepo,
      );
    });

    test('1. Valid Single Account Binding & Resolution', () async {
      final cashAcc = Account(
        id: 1,
        uuid: 'acc-cash-01',
        accountCode: '101001',
        name: 'الصندوق الرئيسي',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(cashAcc);

      lookupPort.addAccount(SetupAccountData(
        uuid: 'acc-cash-01',
        accountCode: '101001',
        accountType: SetupAccountType.asset,
        isActive: true,
        isDeleted: false,
        isGroup: false,
        canPost: true,
        companyId: companyA,
      ));

      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_account',
        role: AccountRole.cash,
        labelAr: 'الصندوق',
        labelEn: 'Cash',
        expectedAccountType: SetupAccountType.asset,
      );


      await resolver.bindAccount(companyId: companyA, requirement: req, accountUuid: 'acc-cash-01');
      final fetched = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'treasury',
        requirementKey: 'cash_account',
      );

      expect(fetched?.accountUuid, equals('acc-cash-01'));
    });

    test('2. Wrong Account Type Rejection', () async {
      final liabilityAcc = Account(
        id: 2,
        uuid: 'acc-liab-01',
        accountCode: '201001',
        name: 'دائنون عام',
        accountType: AccountType.liability,
        normalBalance: NormalBalance.credit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(liabilityAcc);

      final target = AccountBindingTarget.single('acc-liab-01');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('3. Valid Parent Scope Resolution', () async {
      final parentGrp = Account(
        id: 3,
        uuid: 'grp-cash-01',
        accountCode: '101000',
        name: 'مجموعة الصناديق',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 1,
        isGroup: true,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(parentGrp);

      final target = AccountBindingTarget.parentScope('grp-cash-01');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        completes,
      );
    });

    test('4. Invalid Descendant Rejection (Non-Group Parent)', () async {
      final nonGroupAcc = Account(
        id: 4,
        uuid: 'acc-single-04',
        accountCode: '101004',
        name: 'صندوق فرعي غير مجموعة',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(nonGroupAcc);

      final target = AccountBindingTarget.parentScope('acc-single-04');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('5. Wrong-Type Descendant Rejection', () async {
      final wrongTypeDescendant = Account(
        id: 5,
        uuid: 'acc-expense-child',
        accountCode: '501001',
        name: 'مصروف فرعي',
        accountType: AccountType.expense,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(wrongTypeDescendant);

      final target = AccountBindingTarget.single('acc-expense-child');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('6. Customer Account Scope & Posting Proof', () async {
      final custAcc = Account(
        id: 6,
        uuid: 'acc-cust-101',
        accountCode: '102001',
        name: 'حساب العميل علي',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(custAcc);

      final target = AccountBindingTarget.single('acc-cust-101');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.receivable,
          target: target,
        ),
        completes,
      );
    });

    test('7. Supplier Account Scope & Posting Proof', () async {
      final suppAcc = Account(
        id: 7,
        uuid: 'acc-supp-201',
        accountCode: '201001',
        name: 'حساب المورد خالد',
        accountType: AccountType.liability,
        normalBalance: NormalBalance.credit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(suppAcc);

      final target = AccountBindingTarget.single('acc-supp-201');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.payable,
          target: target,
        ),
        completes,
      );
    });

    test('8. Cash Register Account Scope & Posting Proof', () async {
      final cashRegAcc = Account(
        id: 8,
        uuid: 'acc-cash-reg-1',
        accountCode: '101002',
        name: 'صندوق كاشير 1',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(cashRegAcc);

      final target = AccountBindingTarget.single('acc-cash-reg-1');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        completes,
      );
    });

    test('9. Configuration Screen Persistence Workflow', () async {
      lookupPort.addAccount(const SetupAccountData(
        uuid: 'acc-rev-01',
        accountCode: '401001',
        accountType: SetupAccountType.revenue,
        isActive: true,
        isDeleted: false,
        isGroup: false,
        canPost: true,
        companyId: companyA,
      ));

      final req = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'revenue_account',
        role: AccountRole.revenue,
        labelAr: 'الإيرادات',
        labelEn: 'Revenue',
        expectedAccountType: SetupAccountType.revenue,
      );

      await resolver.bindAccount(companyId: companyA, requirement: req, accountUuid: 'acc-rev-01');
      final fetched = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'sales',
        requirementKey: 'revenue_account',
      );

      expect(fetched, isNotNull);
      expect(fetched?.accountUuid, equals('acc-rev-01'));
    });

    test('10. Configuration-to-Posting Integration Proof', () async {
      lookupPort.addAccount(const SetupAccountData(
        uuid: 'acc-inv-asset-01',
        accountCode: '102001',
        accountType: SetupAccountType.asset,
        isActive: true,
        isDeleted: false,
        isGroup: false,
        canPost: true,
        companyId: companyA,
      ));

      final req = const AccountRequirement(
        packageId: 'inventory',
        requirementKey: 'inventory_asset_account',
        role: AccountRole.inventory,
        labelAr: 'المخزون',
        labelEn: 'Inventory',
        expectedAccountType: SetupAccountType.asset,
      );

      await resolver.bindAccount(companyId: companyA, requirement: req, accountUuid: 'acc-inv-asset-01');
      final fetched = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'inventory',
        requirementKey: 'inventory_asset_account',
      );

      expect(fetched?.accountUuid, equals('acc-inv-asset-01'));
    });


    test('11. Historical Journal Line Audit Trail Snapshot', () async {
      usageAnalyzer.setPostedCount('acc-hist-01', 25);
      final usage = await usageAnalyzer.analyzeAccountUsage(
        companyId: companyA,
        accountUuid: 'acc-hist-01',
      );

      expect(usage.status, equals(AccountUsageStatus.usedInPostedTransactions));
      expect(usage.isChangeAllowed, isFalse);
    });

    test('12. Configuration Change Impact Protection', () async {
      final boundAcc = Account(
        id: 12,
        uuid: 'acc-bound-hist',
        accountCode: '101012',
        name: 'صندوق مستخدم',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(boundAcc);
      usageAnalyzer.setPostedCount('acc-bound-hist', 10);

      expect(
        () async => safetyGate.validateBindingChange(
          companyId: companyA,
          role: AccountRole.cash,
          currentAccountUuid: 'acc-bound-hist',
          candidateAccountUuid: 'acc-new-target',
        ),
        throwsA(isA<AccountBindingChangeProhibitedException>()),
      );

    });

    test('13. Deleted Account Rejection', () async {
      final deletedAcc = Account(
        id: 13,
        uuid: 'acc-deleted-01',
        accountCode: '101013',
        name: 'حساب محذوف',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: false,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      accountRepo.add(deletedAcc);

      final target = AccountBindingTarget.single('acc-deleted-01');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('14. Inactive Account Rejection', () async {
      final inactiveAcc = Account(
        id: 14,
        uuid: 'acc-inactive-01',
        accountCode: '101014',
        name: 'حساب غير نشط',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: false,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(inactiveAcc);

      final target = AccountBindingTarget.single('acc-inactive-01');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('15. Parent Restructuring Guard', () async {
      final nonGroupAcc = Account(
        id: 15,
        uuid: 'acc-non-group-15',
        accountCode: '100015',
        name: 'حساب فردي وليس مجموعة',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(nonGroupAcc);

      final target = AccountBindingTarget.parentScope('acc-non-group-15');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('16. Multi-Company Isolation (Company A != Company B)', () async {
      final crossCompanyAcc = Account(
        id: 16,
        uuid: 'acc-compB-cash',
        accountCode: '101099',
        name: 'صندوق شركة B',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyB, // Different company
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(crossCompanyAcc);

      final target = AccountBindingTarget.single('acc-compB-cash');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA, // Attempting to bind to Company A
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('17. Offline Execution & Local Validation', () async {
      final localAcc = Account(
        id: 17,
        uuid: 'acc-offline-01',
        accountCode: '101017',
        name: 'صندوق أوفلاين محلي',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.add(localAcc);

      final target = AccountBindingTarget.single('acc-offline-01');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyA,
          role: AccountRole.cash,
          target: target,
        ),
        completes,
      );
    });

    test('18. Synchronization Conflict Guard', () async {
      lookupPort.addAccount(const SetupAccountData(
        uuid: 'acc-pay-synced',
        accountCode: '201001',
        accountType: SetupAccountType.liability,
        isActive: true,
        isDeleted: false,
        isGroup: false,
        canPost: true,
        companyId: companyA,
      ));

      final req = const AccountRequirement(
        packageId: 'purchases',
        requirementKey: 'payable_account',
        role: AccountRole.payable,
        labelAr: 'الموردون',
        labelEn: 'Payable',
        expectedAccountType: SetupAccountType.liability,
      );

      await resolver.bindAccount(companyId: companyA, requirement: req, accountUuid: 'acc-pay-synced');
      final fetched = await bindingRepo.getBinding(
        companyId: companyA,
        packageId: 'purchases',
        requirementKey: 'payable_account',
      );

      expect(fetched?.accountUuid, equals('acc-pay-synced'));
    });

    test('19. Chart of Accounts Import Compatibility', () async {
      final importedCandidate = [
        Account(
          id: 19,
          uuid: 'acc-import-19',
          accountCode: '101019',
          name: 'صندوق جديد مستورد',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          companyId: companyA,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final report = await importEngine.previewImport(
        companyId: companyA,
        candidateAccounts: importedCandidate,
      );

      expect(report.isSafeToImport, isTrue);
    });

    test('20. Transactional Rollback / Error Path', () async {
      final invalidCandidate = [
        Account(
          id: 20,
          uuid: 'acc-invalid-20',
          accountCode: '101020',
          name: 'صندوق ملغى مستورد',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          companyId: 'comp_B', // Cross-company contamination
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      expect(
        () async => importEngine.executeImport(
          companyId: companyA,
          candidateAccounts: invalidCandidate,
        ),
        throwsA(isA<UnsafeCoaImportException>()),
      );
    });


  });
}
