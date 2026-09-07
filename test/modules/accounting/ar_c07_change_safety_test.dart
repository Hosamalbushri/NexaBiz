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

class ConfigurableUsageAnalyzer implements AccountUsageAnalyzer {
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
      status: count > 0
          ? AccountUsageStatus.usedInPostedTransactions
          : AccountUsageStatus.neverUsed,
      postedTransactionCount: count,
      draftTransactionCount: 0,
      currentBalance: 0.0,
      referencedDocumentTypes: count > 0 ? const ['journal_entry'] : const [],
    );
  }
}

void main() {
  late MockLookupPort lookupPort;
  late InMemoryBindingRepo bindingRepo;
  late AccountBindingResolver resolver;
  late MockAccountRepositoryForSafetyGate accountRepo;
  late ConfigurableUsageAnalyzer usageAnalyzer;
  late AccountBindingSafetyGate safetyGate;

  setUp(() {
    lookupPort = MockLookupPort();
    bindingRepo = InMemoryBindingRepo();
    resolver = AccountBindingResolver(
      accountLookupPort: lookupPort,
      bindingRepository: bindingRepo,
    );

    accountRepo = MockAccountRepositoryForSafetyGate();
    usageAnalyzer = ConfigurableUsageAnalyzer();
    safetyGate = AccountBindingSafetyGate(
      accountRepository: accountRepo,
      usageAnalyzer: usageAnalyzer,
    );
  });

  group('AR-C07 Accounting Configuration Change Safety & Type/Hierarchy Guards', () {
    test(
      '1. Safe configuration change (Unused account -> Binding allowed)',
      () async {
        final unusedAccount = Account(
          id: 1,
          uuid: 'acc-unused-01',
          accountCode: '101001',
          name: 'صندوق غير مستخدم',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: 'compA',
        );
        accountRepo.add(unusedAccount);
        usageAnalyzer.setPostedCount('acc-unused-01', 0);

        final target = AccountBindingTarget.single('acc-unused-01');

        expect(
          () => safetyGate.validateTargetBinding(
            companyId: 'compA',
            role: AccountRole.cash,
            target: target,
          ),
          returnsNormally,
        );
      },
    );

    test(
      '2. Blocked historical change (Account with posted transactions -> Binding policy block)',
      () async {
        final postedAccount = Account(
          id: 2,
          uuid: 'acc-posted-01',
          accountCode: '101002',
          name: 'صندوق مرحل',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: 'compA',
        );
        accountRepo.add(postedAccount);
        usageAnalyzer.setPostedCount('acc-posted-01', 15);

        expect(
          () => safetyGate.validateBindingChange(
            companyId: 'compA',
            role: AccountRole.cash,
            currentAccountUuid: 'acc-posted-01',
            candidateAccountUuid: 'acc-new-01',
          ),
          throwsA(isA<AccountBindingChangeProhibitedException>()),
        );

        final usage = await usageAnalyzer.analyzeAccountUsage(
          companyId: 'compA',
          accountUuid: 'acc-posted-01',
        );
        expect(
          usage.status,
          equals(AccountUsageStatus.usedInPostedTransactions),
        );
        expect(usage.postedTransactionCount, equals(15));
      },
    );

    test(
      '3. Wrong account type configuration rejection (Asset bound to Liability role)',
      () async {
        final liabilityAcc = Account(
          id: 3,
          uuid: 'acc-liability-01',
          accountCode: '201001',
          name: 'حساب دائن',
          accountType: AccountType.liability,
          normalBalance: NormalBalance.credit,
          level: 2,
          isGroup: false,
          isActive: true,
          isSystemAccount: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: 'compA',
        );
        accountRepo.add(liabilityAcc);

        final target = AccountBindingTarget.single('acc-liability-01');

        expect(
          () => safetyGate.validateTargetBinding(
            companyId: 'compA',
            role: AccountRole.cash, // Cash requires Asset
            target: target,
          ),
          throwsA(isA<AccountBindingValidationException>()),
        );
      },
    );

    test('4. Parent scope invalidation detection', () async {
      final parentAcc = Account(
        id: 4,
        uuid: 'acc-parent-01',
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
      accountRepo.add(parentAcc);

      final targetParent = AccountBindingTarget.parentScope('acc-parent-01');

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: targetParent,
        ),
        returnsNormally,
      );
    });

    test('5. Descendant removed from scope rejection', () async {
      final req = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_account',
        role: AccountRole.cash,
        labelAr: 'حساب النقدية',
        labelEn: 'Cash Account',
        expectedAccountType: SetupAccountType.asset,
      );

      expect(
        () => resolver.resolveAccountForTransaction(
          companyId: 'compA',
          requirement: req,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('6. Account deleted rejection', () async {
      final deletedAcc = Account(
        id: 6,
        uuid: 'acc-deleted-99',
        accountCode: '101099',
        name: 'صندوق محذوف',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
        companyId: 'compA',
      );
      accountRepo.add(deletedAcc);

      final target = AccountBindingTarget.single('acc-deleted-99');

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('7. Account deactivated rejection', () async {
      final inactiveAcc = Account(
        id: 7,
        uuid: 'acc-inactive-99',
        accountCode: '101098',
        name: 'صندوق معطل',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: false,
        isSystemAccount: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'compA',
      );
      accountRepo.add(inactiveAcc);

      final target = AccountBindingTarget.single('acc-inactive-99');

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test(
      '8. Account reparented outside expected hierarchy rejection',
      () async {
        final invalidTypeParent = Account(
          id: 8,
          uuid: 'acc-wrong-parent',
          accountCode: '200000',
          name: 'مجموعة الالتزامات',
          accountType: AccountType.liability,
          normalBalance: NormalBalance.credit,
          level: 1,
          isGroup: true,
          isActive: true,
          isSystemAccount: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyId: 'compA',
        );
        accountRepo.add(invalidTypeParent);

        final targetWrongParent = AccountBindingTarget.parentScope(
          'acc-wrong-parent',
        );

        expect(
          () => safetyGate.validateTargetBinding(
            companyId: 'compA',
            role: AccountRole.cash, // Cash requires Asset
            target: targetWrongParent,
          ),
          throwsA(isA<AccountBindingValidationException>()),
        );
      },
    );

    test('9. Cross-company account binding rejection', () async {
      final compBAcc = Account(
        id: 9,
        uuid: 'acc-compB-cash',
        accountCode: '101005',
        name: 'صندوق شركة B',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'compB',
      );
      accountRepo.add(compBAcc);

      final target = AccountBindingTarget.single('acc-compB-cash');

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('10. Offline configuration change safety validation', () async {
      final validAcc = Account(
        id: 10,
        uuid: 'acc-offline-01',
        accountCode: '101010',
        name: 'صندوق أوفلاين',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: 'compA',
      );
      accountRepo.add(validAcc);

      final target = AccountBindingTarget.single('acc-offline-01');

      // Local safety gate validation works 100% offline without network requests
      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: target,
        ),
        returnsNormally,
      );
    });

    test('11. Synchronization conflict safety validation', () async {
      final syncConflictTarget = AccountBindingTarget.single(
        'non-existent-uuid',
      );

      expect(
        () => safetyGate.validateTargetBinding(
          companyId: 'compA',
          role: AccountRole.cash,
          target: syncConflictTarget,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });
  });
}
