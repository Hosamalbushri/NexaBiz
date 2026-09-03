import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_mode.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_hierarchy_resolver.dart';

class HierarchyFakeLookupPort implements SetupAccountLookupPort {
  HierarchyFakeLookupPort(this.accounts, this.descendantsMap);

  final Map<String, SetupAccountData> accounts;
  final Map<String, List<SetupAccountData>> descendantsMap;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async {
    final list = descendantsMap[parentUuid] ?? const [];
    return list.where((a) => companyId == null || companyId.isEmpty || a.companyId == companyId).toList();
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    final list = descendantsMap[parentUuid] ?? const [];
    return list.where((a) => companyId == null || companyId.isEmpty || a.companyId == companyId).toList();
  }
}

class InMemoryAccountRepositoryAdapter implements AccountRepository {
  InMemoryAccountRepositoryAdapter(this.accountsList);

  final List<Account> accountsList;

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    if (includeInactive) return accountsList;
    return accountsList.where((a) => a.isActive && !a.isDeleted).toList();
  }

  @override
  Future<List<Account>> getChildren(String parentUuid) async {
    return accountsList.where((a) => a.parentId == parentUuid).toList();
  }

  @override
  Future<Account?> getByUuid(String uuid) async {
    try {
      return accountsList.firstWhere((a) => a.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Account?> getById(int id) async => null;
  @override
  Future<Account?> getByAccountCode(String accountCode) async => null;
  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async => const [];
  @override
  Future<List<Account>> search(String query, {bool includeInactive = false}) async => const [];
  @override
  Future<bool> hasChildren(String uuid) async => accountsList.any((a) => a.parentId == uuid);
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
  Future<List<Account>> getByType(AccountType type, {bool includeInactive = false}) async => const [];
  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) => Stream.value(accountsList);
}

void main() {
  group('Setup Account Hierarchy Remediation — Unit & Integration Test Matrix', () {
    late InMemoryAccountBindingRepository bindingRepository;

    const companyA = 'comp_main_01';
    const companyB = 'comp_other_02';

    // Account Tree for Company A:
    // A (Parent Group 1100 Customers)
    //  ├── B (Group 1110 Retail Customers)
    //  │    ├── C (Leaf 1111 Customer Cash)
    //  │    └── D (Leaf 1112 Customer Credit)
    //  └── E (Leaf 1120 Wholesale Customer)
    //
    // Account Tree for Company B (Tenant Isolation Test):
    //  └── F (Leaf 1119 Company B Customer - parentId is A, but companyId is companyB)

    const accountA = SetupAccountData(
      uuid: 'uuid_parent_A',
      accountCode: '1100',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: true,
      canPost: false,
    );

    const accountB = SetupAccountData(
      uuid: 'uuid_group_B',
      accountCode: '1110',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: true,
      canPost: false,
    );

    const accountC = SetupAccountData(
      uuid: 'uuid_leaf_C',
      accountCode: '1111',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const accountD = SetupAccountData(
      uuid: 'uuid_leaf_D',
      accountCode: '1112',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const accountE = SetupAccountData(
      uuid: 'uuid_leaf_E',
      accountCode: '1120',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const accountF = SetupAccountData(
      uuid: 'uuid_leaf_F_compB',
      accountCode: '1119',
      accountType: SetupAccountType.asset,
      companyId: companyB,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const exactRequirement = AccountRequirement(
      packageId: 'sales',
      requirementKey: 'sales_revenue_account',
      role: AccountRole.revenue,
      labelAr: 'حساب إيراد المبيعات',
      labelEn: 'Sales Revenue Account',
      isRequired: true,
      bindingMode: AccountBindingMode.exact,
    );

    const parentRequirement = AccountRequirement(
      packageId: 'customers',
      requirementKey: 'ar_account',
      role: AccountRole.receivable,
      labelAr: 'حساب الذمم المدينة الرئيسي',
      labelEn: 'Accounts Receivable Parent Account',
      isRequired: true,
      bindingMode: AccountBindingMode.parent,
    );

    setUp(() {
      bindingRepository = InMemoryAccountBindingRepository();
    });

    test('1. Exact requirement rejects summary/group accounts and requires posting leaf account', () async {
      final lookupPort = HierarchyFakeLookupPort(
        {'uuid_parent_A': accountA, 'uuid_leaf_C': accountC},
        {},
      );
      final resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );

      // Attempting to bind Group account A to exact requirement must fail
      expect(
        () async => resolver.bindAccount(
          companyId: companyA,
          requirement: exactRequirement,
          accountUuid: accountA.uuid,
        ),
        throwsA(isA<AccountBindingException>()),
      );

      // Binding Leaf account C to exact requirement must succeed
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: exactRequirement,
        accountUuid: accountC.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.bindingMode, equals(AccountBindingMode.exact));
    });

    test('2. Parent requirement permits binding summary/group accounts', () async {
      final lookupPort = HierarchyFakeLookupPort(
        {'uuid_parent_A': accountA},
        {'uuid_parent_A': [accountB, accountC, accountD, accountE]},
      );
      final resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );

      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: parentRequirement,
        accountUuid: accountA.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.bindingMode, equals(AccountBindingMode.parent));

      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: parentRequirement,
      );

      expect(result.isBound, isTrue);
      expect(result.account?.uuid, equals(accountA.uuid));
      expect(result.descendants.length, equals(4));
    });

    test('3. AccountHierarchyResolver returns direct children vs full nested descendants with company isolation', () async {
      final now = DateTime.now();
      final domainAccounts = [
        Account(
          id: 1,
          uuid: 'uuid_parent_A',
          accountCode: '1100',
          name: 'حساب العملاء الرئيسي',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 0,
          isGroup: true,
          isActive: true,
          isSystemAccount: false,
          companyId: companyA,
          createdAt: now,
          updatedAt: now,
        ),
        Account(
          id: 2,
          uuid: 'uuid_group_B',
          accountCode: '1110',
          name: 'عملاء التجزئة',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: true,
          parentId: 'uuid_parent_A',
          companyId: companyA,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
        ),
        Account(
          id: 3,
          uuid: 'uuid_leaf_C',
          accountCode: '1111',
          name: 'عميل نقدي',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          parentId: 'uuid_group_B',
          companyId: companyA,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
        ),
        Account(
          id: 4,
          uuid: 'uuid_leaf_D',
          accountCode: '1112',
          name: 'عميل أجل',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          parentId: 'uuid_group_B',
          companyId: companyA,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
        ),
        Account(
          id: 5,
          uuid: 'uuid_leaf_E',
          accountCode: '1120',
          name: 'عملاء الجملة',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: false,
          parentId: 'uuid_parent_A',
          companyId: companyA,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
        ),
        Account(
          id: 6,
          uuid: 'uuid_leaf_F_compB',
          accountCode: '1119',
          name: 'عميل شركة أخرى',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 1,
          isGroup: false,
          parentId: 'uuid_parent_A',
          companyId: companyB, // Company B account!
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final repo = InMemoryAccountRepositoryAdapter(domainAccounts);
      final hierarchyResolver = AccountHierarchyResolver(repo);

      // Direct children of A for Company A -> B and E (F omitted due to companyId mismatch)
      final childrenA = await hierarchyResolver.getChildren(
        companyId: companyA,
        parentUuid: 'uuid_parent_A',
      );
      expect(childrenA.map((a) => a.uuid), containsAll(['uuid_group_B', 'uuid_leaf_E']));
      expect(childrenA.map((a) => a.uuid), isNot(contains('uuid_leaf_F_compB')));

      // Recursive descendants of A for Company A -> B, C, D, E
      final descendantsA = await hierarchyResolver.getDescendants(
        companyId: companyA,
        parentUuid: 'uuid_parent_A',
      );
      expect(
        descendantsA.map((a) => a.uuid),
        containsAll(['uuid_group_B', 'uuid_leaf_C', 'uuid_leaf_D', 'uuid_leaf_E']),
      );
      expect(descendantsA.map((a) => a.uuid), isNot(contains('uuid_leaf_F_compB')));
    });

    test('4. Parent account with no children resolves to isConfiguredButEmpty without crashing', () async {
      final lookupPort = HierarchyFakeLookupPort(
        {'uuid_parent_A': accountA},
        {'uuid_parent_A': []}, // No children
      );
      final resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );

      await resolver.bindAccount(
        companyId: companyA,
        requirement: parentRequirement,
        accountUuid: accountA.uuid,
      );

      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: parentRequirement,
      );

      expect(result.isBound, isTrue);
      expect(result.descendants, isEmpty);
      expect(result.isConfiguredButEmpty, isTrue);
    });

    test('5. Missing or stale parent account does not crash package load, but blocks transaction posting', () async {
      final lookupPort = HierarchyFakeLookupPort({}, {});
      final resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );

      // Package load resolution when unbound returns unbound result safely (no exception thrown)
      final unboundResult = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: parentRequirement,
      );
      expect(unboundResult.isUnbound, isTrue);

      // Transaction resolution for missing parent throws controlled AccountBindingException
      expect(
        () async => resolver.resolveAccountForTransaction(
          companyId: companyA,
          requirement: parentRequirement,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('6. Json deserialization defaults to exact binding mode for backward compatibility', () {
      final legacyJson = {
        'companyId': companyA,
        'packageId': 'sales',
        'requirementKey': 'sales_revenue_account',
        'accountUuid': 'uuid_123',
        'status': 'bound',
        'boundAt': 1600000000000,
      };

      final binding = AccountBinding.fromJson(legacyJson);
      expect(binding.bindingMode, equals(AccountBindingMode.exact));
      expect(binding.status, equals(AccountBindingStatus.bound));
    });
  });
}
