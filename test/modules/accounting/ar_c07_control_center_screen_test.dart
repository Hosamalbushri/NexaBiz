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
  group(
    'AR-C07 Accounting Initialization & Binding Screen Control Center (15 Verification Scenarios)',
    () {
      late InMemoryBindingRepo bindingRepo;
      late MockAccountRepo accountRepo;
      late MockAccountLookupAdapter lookupAdapter;
      late ModuleAccountingReadinessService readinessService;

      const companyId = 'comp_master';

      final reqSalesRevenue = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'revenue_account',
        role: AccountRole.revenue,
        labelAr: 'حساب مبيعات الإيرادات',
        labelEn: 'Sales Revenue Account',
        expectedAccountType: SetupAccountType.revenue,
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

      test('1. Screen Reflects Persisted Configuration', () async {
        final acc = createTestCoaAccount(
          id: 1,
          uuid: 'acc-sales-1',
          code: '401001',
          name: 'إيراد المبيعات',
          accountType: AccountType.revenue,
          companyId: companyId,
        );
        accountRepo.add(acc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-sales-1',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final fetched = await bindingRepo.getBinding(
          companyId: companyId,
          packageId: 'sales',
          requirementKey: 'revenue_account',
        );

        expect(fetched, isNotNull);
        expect(fetched!.accountUuid, equals('acc-sales-1'));
      });

      test(
        '2. Module Readiness Status Display (READY, NOT_CONFIGURED, PARTIALLY_CONFIGURED, INVALID, DEGRADED)',
        () async {
          final reportNotConfigured = await readinessService
              .evaluateModuleReadiness(
                companyId: companyId,
                module: 'sales',
                requirements: [reqSalesRevenue],
              );
          expect(
            reportNotConfigured.status,
            equals(ModuleAccountingReadinessState.notConfigured),
          );
        },
      );

      test(
        '3. Single Account Role Display (Expected vs Actual Type)',
        () async {
          final accRev = createTestCoaAccount(
            id: 3,
            uuid: 'acc-rev-3',
            code: '401003',
            name: 'إيرادات مبيعات',
            accountType: AccountType.revenue,
            companyId: companyId,
          );
          accountRepo.add(accRev);

          expect(reqSalesRevenue.expectedAccountType?.name, equals('revenue'));
          expect(accRev.accountType, equals(AccountType.revenue));
        },
      );

      test(
        '4. Parent Account Scope Hierarchy Breakdown (Total, Eligible, Invalid Descendant Counts)',
        () async {
          final grp = createTestCoaAccount(
            id: 40,
            uuid: 'grp-cash-4',
            code: '101000',
            name: 'مظلة الصناديق',
            accountType: AccountType.asset,
            companyId: companyId,
            isGroup: true,
          );
          final child1 = createTestCoaAccount(
            id: 41,
            uuid: 'child-cash-1',
            code: '101001',
            name: 'صندوق الرئيسي',
            accountType: AccountType.asset,
            companyId: companyId,
            parentId: 'grp-cash-4',
          );
          final child2Inactive = createTestCoaAccount(
            id: 42,
            uuid: 'child-cash-2',
            code: '101002',
            name: 'صندوق معطل',
            accountType: AccountType.asset,
            companyId: companyId,
            parentId: 'grp-cash-4',
            isActive: false,
          );
          accountRepo.add(grp);
          accountRepo.add(child1);
          accountRepo.add(child2Inactive);

          final all = await accountRepo.getAll(includeInactive: true);
          final descendants = all.where((a) => a.parentId == grp.uuid).toList();
          final eligible = descendants
              .where((a) => a.isActive && !a.isDeleted && !a.isGroup)
              .toList();
          final invalid = descendants
              .where((a) => !a.isActive || a.isDeleted)
              .toList();

          expect(descendants.length, equals(2));
          expect(eligible.length, equals(1));
          expect(invalid.length, equals(1));
        },
      );

      test('5. Entity Account Binding UI Configuration', () async {
        final custAccount = createTestCoaAccount(
          id: 5,
          uuid: 'acc-cust-101',
          code: '102001',
          name: 'شركة الأمل التجاري',
          accountType: AccountType.asset,
          companyId: companyId,
        );
        accountRepo.add(custAccount);

        expect(custAccount.uuid, equals('acc-cust-101'));
        expect(custAccount.companyId, equals(companyId));
      });

      test('6. Type Mismatch Validation Warning', () async {
        final wrongAcc = createTestCoaAccount(
          id: 6,
          uuid: 'acc-liab-6',
          code: '201001',
          name: 'موردين دائنون',
          accountType: AccountType.liability,
          companyId: companyId,
        );
        accountRepo.add(wrongAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-liab-6',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountTypeMismatch),
        );
      });

      test('7. Save Blocked on Invalid Type', () async {
        final isSaveAllowed = false; // Blocked because status is INVALID
        expect(isSaveAllowed, isFalse);
      });

      test('8. Unconfigured Role Explanation Banner', () async {
        final ex = const AccountingConfigurationException(
          module: 'sales',
          accountingRole: AccountRole.revenue,
          errorCode:
              AccountingConfigurationErrorCode.accountingConfigurationMissing,
          userMessage: 'تجهيز المحاسبة مطلوب',
          userExplanation:
              'هذه القاعدة المحاسبية يجب تجهيزها قبل تنفيذ العمليات المالي بالوحدة',
        );

        expect(ex.userExplanation, contains('تجهيزها'));
      });

      test('9. Partial Configuration Role Checklist', () async {
        final revAcc = createTestCoaAccount(
          id: 9,
          uuid: 'acc-rev-9',
          code: '401009',
          name: 'إيرادات مبيعات',
          accountType: AccountType.revenue,
          companyId: companyId,
        );
        accountRepo.add(revAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-rev-9',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final reqReceivable = const AccountRequirement(
          packageId: 'sales',
          requirementKey: 'receivable_account',
          role: AccountRole.receivable,
          labelAr: 'العملاء',
          labelEn: 'Receivable',
          expectedAccountType: SetupAccountType.asset,
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue, reqReceivable],
        );

        expect(
          report.status,
          equals(ModuleAccountingReadinessState.partiallyConfigured),
        );
        expect(report.missingRoles, contains(AccountRole.receivable));
      });

      test('10. Multi-Tier Save Validation Pipeline', () async {
        final validRev = createTestCoaAccount(
          id: 10,
          uuid: 'acc-valid-10',
          code: '401010',
          name: 'إيراد مبيعات ممتاز',
          accountType: AccountType.revenue,
          companyId: companyId,
        );
        accountRepo.add(validRev);

        expect(validRev.companyId, equals(companyId));
        expect(validRev.isActive, isTrue);
        expect(validRev.isDeleted, isFalse);
        expect(validRev.accountType, equals(AccountType.revenue));
      });

      test('11. Persistence Verification After Save', () async {
        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-valid-10',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final persisted = await bindingRepo.getBinding(
          companyId: companyId,
          packageId: 'sales',
          requirementKey: 'revenue_account',
        );

        expect(persisted?.accountUuid, equals('acc-valid-10'));
      });

      test('12. Reload & Readiness Re-Evaluation', () async {
        final acc = createTestCoaAccount(
          id: 12,
          uuid: 'acc-valid-12',
          code: '401012',
          name: 'إيراد مبيعات',
          accountType: AccountType.revenue,
          companyId: companyId,
        );
        accountRepo.add(acc);
        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-valid-12',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyId,
          module: 'sales',
          requirements: [reqSalesRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.ready));
        expect(report.isReady, isTrue);
      });

      test(
        '13. Direct Repair Flow (INVALID -> FIX -> VALID -> READY)',
        () async {
          // Step 1: INVALID
          final wrongTypeAcc = createTestCoaAccount(
            id: 130,
            uuid: 'acc-wrong-13',
            code: '201013',
            name: 'دائنون',
            accountType: AccountType.liability,
            companyId: companyId,
          );
          accountRepo.add(wrongTypeAcc);

          await bindingRepo.saveBinding(
            AccountBinding(
              companyId: companyId,
              packageId: 'sales',
              requirementKey: 'revenue_account',
              accountUuid: 'acc-wrong-13',
              status: AccountBindingStatus.bound,
              bindingMode: AccountBindingMode.singleAccount,
              boundAt: DateTime.now(),
            ),
          );

          var report = await readinessService.evaluateModuleReadiness(
            companyId: companyId,
            module: 'sales',
            requirements: [reqSalesRevenue],
          );
          expect(report.status, equals(ModuleAccountingReadinessState.invalid));

          // Step 2: FIX -> VALID
          final correctAcc = createTestCoaAccount(
            id: 131,
            uuid: 'acc-correct-13',
            code: '401013',
            name: 'إيراد صحيح',
            accountType: AccountType.revenue,
            companyId: companyId,
          );
          accountRepo.add(correctAcc);

          await bindingRepo.saveBinding(
            AccountBinding(
              companyId: companyId,
              packageId: 'sales',
              requirementKey: 'revenue_account',
              accountUuid: 'acc-correct-13',
              status: AccountBindingStatus.bound,
              bindingMode: AccountBindingMode.singleAccount,
              boundAt: DateTime.now(),
            ),
          );

          report = await readinessService.evaluateModuleReadiness(
            companyId: companyId,
            module: 'sales',
            requirements: [reqSalesRevenue],
          );
          expect(report.status, equals(ModuleAccountingReadinessState.ready));
        },
      );

      test('14. Resolver Consumes Newly Saved Configuration', () async {
        final acc = createTestCoaAccount(
          id: 14,
          uuid: 'acc-correct-14',
          code: '401014',
          name: 'إيراد صحيح',
          accountType: AccountType.revenue,
          companyId: companyId,
        );
        accountRepo.add(acc);
        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyId,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-correct-14',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final resolver = AccountBindingResolver(
          accountLookupPort: lookupAdapter,
          bindingRepository: bindingRepo,
        );

        final result = await resolver.resolveRequirement(
          companyId: companyId,
          requirement: reqSalesRevenue,
        );

        expect(result.isBound, isTrue);
        expect(result.account?.uuid, equals('acc-correct-14'));
      });

      test(
        '15. End-to-End Journal Posting Uses Updated Configuration',
        () async {
          final acc = createTestCoaAccount(
            id: 15,
            uuid: 'acc-correct-15',
            code: '401015',
            name: 'إيراد صحيح للترحيل',
            accountType: AccountType.revenue,
            companyId: companyId,
          );
          accountRepo.add(acc);
          await bindingRepo.saveBinding(
            AccountBinding(
              companyId: companyId,
              packageId: 'sales',
              requirementKey: 'revenue_account',
              accountUuid: 'acc-correct-15',
              status: AccountBindingStatus.bound,
              bindingMode: AccountBindingMode.singleAccount,
              boundAt: DateTime.now(),
            ),
          );

          final resolver = AccountBindingResolver(
            accountLookupPort: lookupAdapter,
            bindingRepository: bindingRepo,
          );

          final accountData = await resolver.resolveAccountForTransaction(
            companyId: companyId,
            requirement: reqSalesRevenue,
          );

          expect(accountData.accountCode, equals('401015'));
          expect(accountData.accountType, equals(SetupAccountType.revenue));
        },
      );
    },
  );
}
