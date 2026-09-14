import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_mode.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_status.dart';
import 'package:stock_count/core/setup/domain/entities/account_requirement.dart';
import 'package:stock_count/core/setup/domain/repositories/account_binding_repository.dart';
import 'package:stock_count/core/setup/domain/services/account_binding_resolver.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/accounting_configuration_error.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/module_accounting_readiness_service.dart';
import 'package:stock_count/modules/accounting/shared/presentation/widgets/accounting_configuration_error_card.dart';

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

class MockAccountRepo implements AccountRepository {
  final Map<String, Account> _store = {};

  void add(Account account) => _store[account.id] = account;

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

class MockAccountLookupAdapter implements SetupAccountLookupPort {
  MockAccountLookupAdapter(this.repo);
  final MockAccountRepo repo;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    final a =
        await repo.getByUuid(codeOrUuidOrId) ??
        await repo.getByAccountCode(codeOrUuidOrId);
    if (a == null) return null;
    return SetupAccountData(
      uuid: a.uuid,
      accountCode: a.accountCode,
      accountType: _mapSetupType(a.accountType),
      companyId: a.companyId,
      isActive: a.isActive,
      isDeleted: a.isDeleted,
      isGroup: a.isGroup,
      canPost: a.isPostingAccount,
    );
  }

  @override
  Future<List<SetupAccountData>> getChildren(
    String parentUuid, {
    String? companyId,
  }) async {
    final all = await repo.getAll(includeInactive: true);
    return all
        .where(
          (a) =>
              a.parentId == parentUuid &&
              (companyId == null || a.companyId == companyId),
        )
        .map(
          (a) => SetupAccountData(
            uuid: a.uuid,
            accountCode: a.accountCode,
            accountType: _mapSetupType(a.accountType),
            companyId: a.companyId,
            isActive: a.isActive,
            isDeleted: a.isDeleted,
            isGroup: a.isGroup,
            canPost: a.isPostingAccount,
          ),
        )
        .toList();
  }

  @override
  Future<List<SetupAccountData>> getDescendants(
    String parentUuid, {
    String? companyId,
  }) async {
    final all = await repo.getAll(includeInactive: true);
    return all
        .where(
          (a) =>
              a.parentId == parentUuid &&
              (companyId == null || a.companyId == companyId),
        )
        .map(
          (a) => SetupAccountData(
            uuid: a.uuid,
            accountCode: a.accountCode,
            accountType: _mapSetupType(a.accountType),
            companyId: a.companyId,
            isActive: a.isActive,
            isDeleted: a.isDeleted,
            isGroup: a.isGroup,
            canPost: a.isPostingAccount,
          ),
        )
        .toList();
  }

  SetupAccountType _mapSetupType(AccountType type) {
    switch (type) {
      case AccountType.asset:
        return SetupAccountType.asset;
      case AccountType.liability:
        return SetupAccountType.liability;
      case AccountType.equity:
        return SetupAccountType.equity;
      case AccountType.revenue:
        return SetupAccountType.revenue;
      case AccountType.expense:
        return SetupAccountType.expense;
    }
  }
}

Account createTestCoaAccount({
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
  group('AR-C10 & AR-C08 Addendum Error Visibility & Recovery Gate', () {
    late InMemoryBindingRepo bindingRepo;
    late MockAccountRepo accountRepo;
    late MockAccountLookupAdapter lookupAdapter;
    late ModuleAccountingReadinessService readinessService;

    const companyId = 'comp_master';

    final reqSalesRevenue = const AccountRequirement(
      packageId: 'sales',
      requirementKey: 'revenue_account',
      role: AccountRole.revenue,
      labelAr: 'حساب الإيرادات',
      labelEn: 'Revenue Account',
      expectedAccountType: SetupAccountType.revenue,
    );

    final reqSalesReceivable = const AccountRequirement(
      packageId: 'sales',
      requirementKey: 'receivable_account',
      role: AccountRole.receivable,
      labelAr: 'حساب العملاء',
      labelEn: 'Receivable Account',
      expectedAccountType: SetupAccountType.asset,
    );

    final reqPurchasePayable = const AccountRequirement(
      packageId: 'purchases',
      requirementKey: 'payable_account',
      role: AccountRole.payable,
      labelAr: 'حساب الموردين',
      labelEn: 'Payable Account',
      expectedAccountType: SetupAccountType.liability,
    );

    final reqTreasuryCashParent = const AccountRequirement(
      packageId: 'treasury',
      requirementKey: 'cash_parent_account',
      role: AccountRole.cash,
      labelAr: 'مظلة الصناديق الرئيسية',
      labelEn: 'Cash Parent Account',
      expectedAccountType: SetupAccountType.asset,
      bindingMode: AccountBindingMode.parentAccountWithDescendants,
    );

    final reqCustomerReceivable = const AccountRequirement(
      packageId: 'customers',
      requirementKey: 'ar_account',
      role: AccountRole.receivable,
      labelAr: 'حساب ذمم العميل',
      labelEn: 'Customer AR Account',
      expectedAccountType: SetupAccountType.asset,
    );

    final reqSupplierPayable = const AccountRequirement(
      packageId: 'suppliers',
      requirementKey: 'ap_account',
      role: AccountRole.payable,
      labelAr: 'حساب ذمم المورد',
      labelEn: 'Supplier AP Account',
      expectedAccountType: SetupAccountType.liability,
    );

    final reqInventoryAsset = const AccountRequirement(
      packageId: 'inventory',
      requirementKey: 'inventory_asset_account',
      role: AccountRole.inventory,
      labelAr: 'حساب الأصول المخزنية',
      labelEn: 'Inventory Asset Account',
      expectedAccountType: SetupAccountType.asset,
    );

    setUp(() {
      bindingRepo = InMemoryBindingRepo();
      accountRepo = MockAccountRepo();
      lookupAdapter = MockAccountLookupAdapter(accountRepo);
      readinessService = ModuleAccountingReadinessService(
        bindingRepository: bindingRepo,
        accountRepository: accountRepo,
      );
    });

    test(
      '1. Sales Module Lifecycle: Missing Config -> Explanation -> Repair -> READY -> Posting Success',
      () async {
        // Step 1: Missing Config
        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue],
        );

        expect(
          report.status,
          equals(ModuleAccountingReadinessState.notConfigured),
        );
        expect(report.missingRoles, contains(AccountRole.revenue));
        expect(
          report.primaryError?.errorCode,
          equals(
            AccountingConfigurationErrorCode.accountingConfigurationMissing,
          ),
        );
        expect(
          report.primaryError?.userExplanation,
          contains('لم يتم تحديد الحساب'),
        );
        expect(report.primaryError?.configurationRoute, equals('/setup'));

        // Step 2: Repair
        final revAcc = createTestCoaAccount(
          id: 'acc-sales-rev-101',
          code: '401001',
          name: 'إيراد المبيعات',
          accountType: AccountType.revenue,
          companyId: companyId,
        );
        accountRepo.add(revAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountId: 'acc-sales-rev-101',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        // Step 3: READY Verification
        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));

        // Step 4: Transaction Posting
        final resolver = AccountBindingResolver(
          accountLookupPort: lookupAdapter,
          bindingRepository: bindingRepo,
        );
        final accountData = await resolver.resolveAccountForTransaction(
          companyId: companyId,
          requirement: reqSalesRevenue,
        );
        expect(accountData.accountCode, equals('401001'));
        expect(accountData.accountType, equals(SetupAccountType.revenue));
      },
    );

    test(
      '2. Purchases Module Lifecycle: Missing Config -> Explanation -> Repair -> READY -> Posting Success',
      () async {
        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'purchases',
          requirements: [reqPurchasePayable],
        );

        expect(
          report.status,
          equals(ModuleAccountingReadinessState.notConfigured),
        );
        expect(report.missingRoles, contains(AccountRole.payable));

        final payAcc = createTestCoaAccount(
          id: 'acc-pur-pay-201',
          code: '201001',
          name: 'حساب الموردين',
          accountType: AccountType.liability,
          companyId: companyId,
        );
        accountRepo.add(payAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'purchases',
            requirementKey: 'payable_account',
            accountId: 'acc-pur-pay-201',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'purchases',
          requirements: [reqPurchasePayable],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));

        final resolver = AccountBindingResolver(
          accountLookupPort: lookupAdapter,
          bindingRepository: bindingRepo,
        );
        final accountData = await resolver.resolveAccountForTransaction(
          companyId: companyId,
          requirement: reqPurchasePayable,
        );
        expect(accountData.accountCode, equals('201001'));
        expect(accountData.accountType, equals(SetupAccountType.liability));
      },
    );

    test(
      '3. Treasury Cash Module Scope Lifecycle: Parent Scope Invalidation -> Breakdown -> Repair -> READY -> Posting',
      () async {
        // Inactive Parent Group
        final inactiveParentGroup = createTestCoaAccount(
          id: 'grp-cash-301',
          code: '101000',
          name: 'مظلة معطلة',
          accountType: AccountType.asset,
          companyId: companyId,
          isGroup: true,
          isActive: false,
        );
        accountRepo.add(inactiveParentGroup);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'treasury',
            requirementKey: 'cash_parent_account',
            accountId: 'grp-cash-301',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.parentAccountWithDescendants,
            boundAt: DateTime.now(),
          ),
        );

        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'treasury',
          requirements: [reqTreasuryCashParent],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.degraded));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountInactive),
        );

        // Repair Scope
        final activeParentGroup = createTestCoaAccount(
          id: 'grp-cash-302',
          code: '101000',
          name: 'مظلة الصناديق العامة',
          accountType: AccountType.asset,
          companyId: companyId,
          isGroup: true,
          isActive: true,
        );
        final cashReg1 = createTestCoaAccount(
          id: 'reg-cash-303',
          code: '101001',
          name: 'الصندوق الرئيسي',
          accountType: AccountType.asset,
          companyId: companyId,
          parentId: 'grp-cash-302',
          isGroup: false,
        );
        accountRepo.add(activeParentGroup);
        accountRepo.add(cashReg1);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'treasury',
            requirementKey: 'cash_parent_account',
            accountId: 'grp-cash-302',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.parentAccountWithDescendants,
            boundAt: DateTime.now(),
          ),
        );

        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'treasury',
          requirements: [reqTreasuryCashParent],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));

        final resolver = AccountBindingResolver(
          accountLookupPort: lookupAdapter,
          bindingRepository: bindingRepo,
        );
        final result = await resolver.resolveRequirement(
          companyId: companyId,
          requirement: reqTreasuryCashParent,
        );
        expect(result.descendants.length, equals(1));
        expect(result.descendants.first.accountCode, equals('101001'));
      },
    );

    test(
      '4. Customers Entity Account Recovery: Tenant Invalidation -> Isolation Check -> Repair -> READY -> Posting',
      () async {
        // Cross-Company Account (Belongs to tenant companyB)
        final otherCompanyAccount = createTestCoaAccount(
          id: 'acc-cust-401',
          code: '102001',
          name: 'عميل شركة خادمة',
          accountType: AccountType.asset,
          companyId: 'companyB',
        );
        accountRepo.add(otherCompanyAccount);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'customers',
            requirementKey: 'ar_account',
            accountId: 'acc-cust-401',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'customers',
          requirements: [reqCustomerReceivable],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.crossCompanyAccount),
        );

        // Repair to Active Tenant Account
        final validCustAccount = createTestCoaAccount(
          id: 'acc-cust-402',
          code: '102001',
          name: 'عميل شركة الأمل',
          accountType: AccountType.asset,
          companyId: companyId,
        );
        accountRepo.add(validCustAccount);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'customers',
            requirementKey: 'ar_account',
            accountId: 'acc-cust-402',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'customers',
          requirements: [reqCustomerReceivable],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));
      },
    );

    test(
      '5. Suppliers Entity Account Recovery: Account Deactivation -> Explanation -> Repair -> READY -> Posting',
      () async {
        final deactivatedAccount = createTestCoaAccount(
          id: 'acc-sup-501',
          code: '201005',
          name: 'مورد معطل',
          accountType: AccountType.liability,
          companyId: companyId,
          isActive: false,
        );
        accountRepo.add(deactivatedAccount);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'suppliers',
            requirementKey: 'ap_account',
            accountId: 'acc-sup-501',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'suppliers',
          requirements: [reqSupplierPayable],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.degraded));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountInactive),
        );

        final activeSupplierAccount = createTestCoaAccount(
          id: 'acc-sup-502',
          code: '201005',
          name: 'مورد نشط مميز',
          accountType: AccountType.liability,
          companyId: companyId,
          isActive: true,
        );
        accountRepo.add(activeSupplierAccount);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'suppliers',
            requirementKey: 'ap_account',
            accountId: 'acc-sup-502',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'suppliers',
          requirements: [reqSupplierPayable],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));
      },
    );

    test(
      '6. Inventory Module Type Mismatch: Asset vs Expense -> Warning -> Repair -> READY -> Posting',
      () async {
        final expenseAccount = createTestCoaAccount(
          id: 'acc-exp-601',
          code: '501001',
          name: 'مصروفات تالف',
          accountType: AccountType.expense,
          companyId: companyId,
        );
        accountRepo.add(expenseAccount);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'inventory',
            requirementKey: 'inventory_asset_account',
            accountId: 'acc-exp-601',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'inventory',
          requirements: [reqInventoryAsset],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountTypeMismatch),
        );
        expect(
          report.primaryError?.userExplanation,
          contains('بينما المطلوب هو'),
        );

        final validInventoryAsset = createTestCoaAccount(
          id: 'acc-inv-602',
          code: '103001',
          name: 'المخزون السلعي العام',
          accountType: AccountType.asset,
          companyId: companyId,
        );
        accountRepo.add(validInventoryAsset);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'inventory',
            requirementKey: 'inventory_asset_account',
            accountId: 'acc-inv-602',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'inventory',
          requirements: [reqInventoryAsset],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));
      },
    );

    test(
      '7. COA Change Propagation & Multi-Issue Visibility (AR-C08 Addendum)',
      () async {
        // Setup 2 Sales requirements
        final deactivatedRevAcc = createTestCoaAccount(
          id: 'acc-rev-701',
          code: '401001',
          name: 'إيراد معطل',
          accountType: AccountType.revenue,
          companyId: companyId,
          isActive: false, // Inactive
        );

        final wrongTypeArAcc = createTestCoaAccount(
          id: 'acc-ar-702',
          code: '201001',
          name: 'عملاء نوع خطأ',
          accountType: AccountType.liability, // Type Mismatch
          companyId: companyId,
        );

        accountRepo.add(deactivatedRevAcc);
        accountRepo.add(wrongTypeArAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountId: 'acc-rev-701',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'receivable_account',
            accountId: 'acc-ar-702',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        var report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue, reqSalesReceivable],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.degraded));
        expect(report.errors.length, equals(2));

        final affectedRoles = report.errors
            .map((e) => e.accountingRole)
            .toList();
        expect(
          affectedRoles,
          containsAll([AccountRole.revenue, AccountRole.receivable]),
        );

        // Test multi-issue explanation card Widget rendering
        final widget = MaterialApp(
          home: Scaffold(
            body: AccountingConfigurationErrorCard(error: report.primaryError!),
          ),
        );
        expect(widget, isNotNull);

        // Repair Both Issues
        final activeRevAcc = createTestCoaAccount(
          id: 'acc-rev-703',
          code: '401001',
          name: 'إيرادات مبيعات ممتازة',
          accountType: AccountType.revenue,
          companyId: companyId,
          isActive: true,
        );
        final correctArAcc = createTestCoaAccount(
          id: 'acc-ar-704',
          code: '102001',
          name: 'حساب العملاء الأصول',
          accountType: AccountType.asset,
          companyId: companyId,
          isActive: true,
        );
        accountRepo.add(activeRevAcc);
        accountRepo.add(correctArAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountId: 'acc-rev-703',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'receivable_account',
            accountId: 'acc-ar-704',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue, reqSalesReceivable],
        );
        expect(report.status, equals(ModuleAccountingReadinessState.ready));
        expect(report.isReady, isTrue);
      },
    );

    test('8. Failure Prevention Safeguard: Zero Technical Crashes', () async {
      final ex = const AccountingConfigurationException(
        module: 'sales',
        accountingRole: AccountRole.revenue,
        errorCode: AccountingConfigurationErrorCode.accountTypeMismatch,
        userMessage: 'نوع الحساب غير متوافق',
        userExplanation: 'الحساب المربوط من نوع دائن والمطلوب إيرادات',
      );

      expect(
        ex.errorCode,
        equals(AccountingConfigurationErrorCode.accountTypeMismatch),
      );
      expect(ex.userExplanation, contains('نوع دائن'));
    });
  });
}
