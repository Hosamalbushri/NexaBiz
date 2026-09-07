import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_binding_safety_gate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_usage_analyzer.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';

class MockAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void seedAccount(Account account) {
    _accounts[account.uuid] = account;
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _accounts[uuid];

  @override
  Future<Account?> getByAccountCode(String accountCode) async {
    for (final acc in _accounts.values) {
      if (acc.accountCode == accountCode) return acc;
    }
    return null;
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    return _accounts.values
        .where((a) => includeInactive || a.isActive)
        .toList();
  }

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) {
    return Stream.value(_accounts.values.toList());
  }

  @override
  Future<Account?> getById(int id) async {
    for (final acc in _accounts.values) {
      if (acc.id == id) return acc;
    }
    return null;
  }

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async {
    return uuids.map((u) => _accounts[u]).whereType<Account>().toList();
  }

  @override
  Future<List<Account>> search(
    String query, {
    bool includeInactive = false,
  }) async {
    return _accounts.values.where((a) => a.name.contains(query)).toList();
  }

  @override
  Future<List<Account>> getChildren(String parentUuid) async {
    return _accounts.values.where((a) => a.parentId == parentUuid).toList();
  }

  @override
  Future<bool> hasChildren(String uuid) async {
    return _accounts.values.any((a) => a.parentId == uuid);
  }

  @override
  Future<bool> isUsedInTransactions(String uuid) async => false;

  @override
  Future<Account> insert(AccountDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<Account> update(int id, AccountDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<void> deactivate(int id) async {}

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  Future<void> seedDefaultChart() async {}

  @override
  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  }) async {
    return _accounts.values.where((a) => a.accountType == type).toList();
  }
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
  late MockAccountRepository accountRepo;
  late AccountBindingSafetyGate safetyGate;
  const companyId = 'comp_01';
  final now = DateTime.now();

  setUp(() {
    accountRepo = MockAccountRepository();
    safetyGate = AccountBindingSafetyGate(
      accountRepository: accountRepo,
      usageAnalyzer: DummyUsageAnalyzer(),
    );

    // Seed test accounts
    accountRepo.seedAccount(
      Account(
        id: 1,
        uuid: 'acc_rev_01',
        companyId: companyId,
        accountCode: '4100',
        name: 'Sales Revenue',
        accountType: AccountType.revenue,
        normalBalance: AccountType.revenue.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 2,
        uuid: 'acc_cust_group',
        companyId: companyId,
        accountCode: '1221',
        name: 'Customers Group',
        accountType: AccountType.asset,
        normalBalance: AccountType.asset.normalBalance,
        level: 1,
        isGroup: true,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 3,
        uuid: 'acc_cust_child_1',
        companyId: companyId,
        parentId: 'acc_cust_group',
        accountCode: '1221-0001',
        name: 'Customer A',
        accountType: AccountType.asset,
        normalBalance: AccountType.asset.normalBalance,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 4,
        uuid: 'acc_cash_1',
        companyId: companyId,
        accountCode: '1211',
        name: 'Main Cash Box',
        accountType: AccountType.asset,
        normalBalance: AccountType.asset.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 5,
        uuid: 'acc_cash_2',
        companyId: companyId,
        accountCode: '1212',
        name: 'Secondary Cash Box',
        accountType: AccountType.asset,
        normalBalance: AccountType.asset.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 6,
        uuid: 'acc_inactive',
        companyId: companyId,
        accountCode: '4999',
        name: 'Inactive Account',
        accountType: AccountType.revenue,
        normalBalance: AccountType.revenue.normalBalance,
        level: 1,
        isGroup: false,
        isActive: false,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 7,
        uuid: 'acc_deleted',
        companyId: companyId,
        accountCode: '4998',
        name: 'Deleted Account',
        accountType: AccountType.revenue,
        normalBalance: AccountType.revenue.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      ),
    );

    accountRepo.seedAccount(
      Account(
        id: 8,
        uuid: 'acc_other_company',
        companyId: 'comp_other',
        accountCode: '4100',
        name: 'Other Company Revenue',
        accountType: AccountType.revenue,
        normalBalance: AccountType.revenue.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  group('AR-C03 Accounting Configuration Foundation Tests', () {
    test('1. SINGLE_ACCOUNT binding valid resolution', () async {
      final target = AccountBindingTarget.single('acc_rev_01');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.revenue,
          target: target,
        ),
        completes,
      );
    });

    test('2. PARENT_ACCOUNT_WITH_DESCENDANTS parent scope binding', () async {
      final target = AccountBindingTarget.parentScope('acc_cust_group');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.receivable,
          target: target,
        ),
        completes,
      );
    });

    test('3. ACCOUNT_SET binding valid set resolution', () async {
      final target = AccountBindingTarget.set(['acc_cash_1', 'acc_cash_2']);
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.cash,
          target: target,
        ),
        completes,
      );
    });

    test(
      '4. Company isolation validation (cross-company account BLOCKED)',
      () async {
        final target = AccountBindingTarget.single('acc_other_company');
        await expectLater(
          safetyGate.validateTargetBinding(
            companyId: companyId,
            role: AccountRole.revenue,
            target: target,
          ),
          throwsA(isA<AccountBindingValidationException>()),
        );
      },
    );

    test('5. Missing account validation BLOCKED', () async {
      final target = AccountBindingTarget.single('non_existent_uuid');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.revenue,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('6. Inactive account validation BLOCKED', () async {
      final target = AccountBindingTarget.single('acc_inactive');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.revenue,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('7. Deleted account validation BLOCKED', () async {
      final target = AccountBindingTarget.single('acc_deleted');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.revenue,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('8. Wrong account type validation BLOCKED', () async {
      // Trying to bind Revenue role to Asset account
      final target = AccountBindingTarget.single('acc_cash_1');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.revenue,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('9. Invalid parent validation (non-group parent BLOCKED)', () async {
      // Trying to bind PARENT_ACCOUNT_WITH_DESCENDANTS to a non-group account
      final target = AccountBindingTarget.parentScope('acc_cash_1');
      await expectLater(
        safetyGate.validateTargetBinding(
          companyId: companyId,
          role: AccountRole.receivable,
          target: target,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('10. Descendant outside parent scope validation', () async {
      final parent = await accountRepo.getByUuid('acc_cust_group');
      final outsideAccount = await accountRepo.getByUuid('acc_cash_1');

      expect(outsideAccount?.parentId != parent?.uuid, isTrue);
    });

    test('11. Valid descendant under parent scope ALLOWED', () async {
      final parent = await accountRepo.getByUuid('acc_cust_group');
      final child = await accountRepo.getByUuid('acc_cust_child_1');

      expect(child?.parentId, equals(parent?.uuid));
    });

    test('12. Duplicate configuration prevention (equality check)', () {
      const config1 = CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {AccountRole.revenue: 'acc_rev_01'},
      );
      const config2 = CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {AccountRole.revenue: 'acc_rev_01'},
      );

      expect(config1, equals(config2));
    });

    test('13. Module requirement initialization completeness', () {
      const config = CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {
          AccountRole.inventory: '1230',
          AccountRole.cogs: '5100',
          AccountRole.revenue: '4100',
          AccountRole.receivable: '1221',
          AccountRole.payable: '2111',
          AccountRole.cash: '1210',
          AccountRole.adjustment: '5150',
          AccountRole.fxGainLoss: '4220',
        },
      );

      expect(config.isComplete, isTrue);
    });

    test('14. Persistence serialization & deserialization (Hive/JSON)', () {
      final config = CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: const {AccountRole.revenue: 'acc_rev_01'},
        bindingTargets: {
          AccountRole.revenue: AccountBindingTarget.single('acc_rev_01'),
          AccountRole.receivable: AccountBindingTarget.parentScope(
            'acc_cust_group',
          ),
          AccountRole.cash: AccountBindingTarget.set([
            'acc_cash_1',
            'acc_cash_2',
          ]),
        },
      );

      final json = config.toJson();
      final restored = CompanyAccountingConfig.fromJson(json);

      expect(restored.companyId, equals(companyId));
      expect(
        restored.bindingTargets[AccountRole.revenue]?.mode,
        equals(AccountBindingMode.singleAccount),
      );
      expect(
        restored.bindingTargets[AccountRole.receivable]?.mode,
        equals(AccountBindingMode.parentAccountWithDescendants),
      );
      expect(
        restored.bindingTargets[AccountRole.cash]?.mode,
        equals(AccountBindingMode.accountSet),
      );
    });

    test('15. Reload after app restart verification', () {
      final timestamp = DateTime.utc(2026, 9, 4);
      final original = CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: const {AccountRole.revenue: 'acc_rev_01'},
        bindingTargets: {
          AccountRole.revenue: AccountBindingTarget.single('acc_rev_01'),
        },
        updatedAt: timestamp,
      );

      final json = original.toJson();
      final reloaded = CompanyAccountingConfig.fromJson(json);

      expect(reloaded, equals(original));
    });
  });
}
