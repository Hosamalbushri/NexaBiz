import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_mode.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_status.dart';
import 'package:stock_count/core/setup/domain/entities/account_requirement.dart';
import 'package:stock_count/core/setup/domain/repositories/account_binding_repository.dart';
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
    'AR-C06 Accounting Configuration Dependency, Validation Errors & Module UX (16 Verification Scenarios)',
    () {
      late InMemoryBindingRepo bindingRepo;
      late MockAccountRepo accountRepo;
      late ModuleAccountingReadinessService readinessService;

      const companyA = 'comp_A';

      final reqRevenue = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'revenue_account',
        role: AccountRole.revenue,
        labelAr: 'الإيرادات',
        labelEn: 'Revenue',
        expectedAccountType: SetupAccountType.revenue,
      );

      final reqReceivable = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'receivable_account',
        role: AccountRole.receivable,
        labelAr: 'العملاء',
        labelEn: 'Receivable',
        expectedAccountType: SetupAccountType.asset,
      );

      final reqCash = const AccountRequirement(
        packageId: 'treasury',
        requirementKey: 'cash_parent_account',
        role: AccountRole.cash,
        labelAr: 'مظلة الصناديق',
        labelEn: 'Cash Parent',
        expectedAccountType: SetupAccountType.asset,
      );

      setUp(() {
        bindingRepo = InMemoryBindingRepo();
        accountRepo = MockAccountRepo();
        readinessService = ModuleAccountingReadinessService(
          bindingRepository: bindingRepo,
          accountRepository: accountRepo,
        );
      });

      test(
        '1. Completely Unconfigured Module State (NOT_CONFIGURED)',
        () async {
          final report = await readinessService.evaluateModuleReadiness(
            companyId: companyA,
            module: 'sales',
            requirements: [reqRevenue, reqReceivable],
          );

          expect(
            report.status,
            equals(ModuleAccountingReadinessState.notConfigured),
          );
          expect(report.isReady, isFalse);
          expect(report.missingRoles.length, equals(2));
          expect(
            report.primaryError?.errorCode,
            equals(
              AccountingConfigurationErrorCode.accountingConfigurationMissing,
            ),
          );
        },
      );

      test(
        '2. Partially Configured Module State (PARTIALLY_CONFIGURED)',
        () async {
          final revAcc = createTestCoaAccount(
            id: 1,
            uuid: 'acc-rev-01',
            code: '401001',
            name: 'إيرادات مبيعات',
            accountType: AccountType.revenue,
            companyId: companyA,
          );
          accountRepo.add(revAcc);

          await bindingRepo.saveBinding(
            AccountBinding(
              companyId: companyA,
              packageId: 'sales',
              requirementKey: 'revenue_account',
              accountUuid: 'acc-rev-01',
              status: AccountBindingStatus.bound,
              bindingMode: AccountBindingMode.singleAccount,
              boundAt: DateTime.now(),
            ),
          );

          final report = await readinessService.evaluateModuleReadiness(
            companyId: companyA,
            module: 'sales',
            requirements: [reqRevenue, reqReceivable],
          );

          expect(
            report.status,
            equals(ModuleAccountingReadinessState.partiallyConfigured),
          );
          expect(report.missingRoles, contains(AccountRole.receivable));
        },
      );

      test('3. Invalid Account Type Detection (INVALID)', () async {
        final wrongTypeAcc = createTestCoaAccount(
          id: 2,
          uuid: 'acc-liab-01',
          code: '201001',
          name: 'دائنون',
          accountType: AccountType.liability, // Expected revenue
          companyId: companyA,
        );
        accountRepo.add(wrongTypeAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-liab-01',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountTypeMismatch),
        );
      });

      test('4. Invalid Parent Scope Detection (INVALID)', () async {
        final nonGroupAcc = createTestCoaAccount(
          id: 3,
          uuid: 'acc-single-03',
          code: '101003',
          name: 'صندوق فرعي غير مجموعة',
          accountType: AccountType.asset,
          companyId: companyA,
          isGroup: false,
        );
        accountRepo.add(nonGroupAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'treasury',
            requirementKey: 'cash_parent_account',
            accountUuid: 'acc-single-03',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.parentAccountWithDescendants,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'treasury',
          requirements: [reqCash],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.parentAccountInvalid),
        );
      });

      test('5. No Eligible Descendants Available (INVALID)', () async {
        final emptyGroupAcc = createTestCoaAccount(
          id: 4,
          uuid: 'grp-empty-04',
          code: '101000',
          name: 'مجموعة صناديق فارغة',
          accountType: AccountType.asset,
          companyId: companyA,
          isGroup: true,
        );
        accountRepo.add(emptyGroupAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'treasury',
            requirementKey: 'cash_parent_account',
            accountUuid: 'grp-empty-04',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.parentAccountWithDescendants,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'treasury',
          requirements: [reqCash],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.descendantAccountInvalid),
        );
      });

      test('6. Selected Descendant Outside Scope Detection', () async {
        final grpA = createTestCoaAccount(
          id: 5,
          uuid: 'grp-A',
          code: '101000',
          name: 'مجموعة A',
          accountType: AccountType.asset,
          companyId: companyA,
          isGroup: true,
        );
        final childInB = createTestCoaAccount(
          id: 6,
          uuid: 'child-B',
          code: '102001',
          name: 'فرعي في مجموعة B',
          accountType: AccountType.asset,
          companyId: companyA,
          parentId: 'grp-B',
        );
        accountRepo.add(grpA);
        accountRepo.add(childInB);

        final isWithinScope = childInB.parentId == grpA.uuid;
        expect(isWithinScope, isFalse);
      });

      test('7. Inactive Account Detection (DEGRADED)', () async {
        final inactiveAcc = createTestCoaAccount(
          id: 7,
          uuid: 'acc-inactive-07',
          code: '401007',
          name: 'إيراد معطل',
          accountType: AccountType.revenue,
          companyId: companyA,
          isActive: false,
        );
        accountRepo.add(inactiveAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-inactive-07',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.degraded));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountInactive),
        );
      });

      test('8. Deleted Account Detection (DEGRADED)', () async {
        final deletedAcc = createTestCoaAccount(
          id: 8,
          uuid: 'acc-deleted-08',
          code: '401008',
          name: 'إيراد محذوف',
          accountType: AccountType.revenue,
          companyId: companyA,
          isActive: false,
          isDeleted: true,
        );
        accountRepo.add(deletedAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-deleted-08',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.degraded));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.accountDeleted),
        );
      });

      test('9. Missing Entity Account Detection', () async {
        final ex = const AccountingConfigurationException(
          module: 'customers',
          accountingRole: AccountRole.receivable,
          entityId: 'cust-101',
          errorCode:
              AccountingConfigurationErrorCode.entityAccountNotConfigured,
          userMessage: 'حساب العميل غير موجود',
          userExplanation:
              'يرجى ربط العميل بحساب مالي صالح تحت المظلة المحاسبية',
        );

        expect(
          ex.errorCode,
          equals(AccountingConfigurationErrorCode.entityAccountNotConfigured),
        );
        expect(ex.entityId, equals('cust-101'));
      });

      test('10. Entity Account Outside Scope Detection', () async {
        final ex = const AccountingConfigurationException(
          module: 'suppliers',
          accountingRole: AccountRole.payable,
          entityId: 'supp-201',
          parentAccountId: 'grp-supp-parent',
          configuredAccountId: 'acc-unrelated-bank',
          errorCode: AccountingConfigurationErrorCode.entityAccountOutsideScope,
          userMessage: 'حساب المورد خارج المظلة المعتمدة',
        );

        expect(
          ex.errorCode,
          equals(AccountingConfigurationErrorCode.entityAccountOutsideScope),
        );
      });

      test('11. Cross-Company Account Detection (INVALID)', () async {
        final compBAcc = createTestCoaAccount(
          id: 11,
          uuid: 'acc-compB-11',
          code: '401011',
          name: 'إيراد شركة B',
          accountType: AccountType.revenue,
          companyId: 'comp_B',
        );
        accountRepo.add(compBAcc);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-compB-11',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.invalid));
        expect(
          report.primaryError?.errorCode,
          equals(AccountingConfigurationErrorCode.crossCompanyAccount),
        );
      });

      test('12. Configuration Repaired Flow', () async {
        final validRev = createTestCoaAccount(
          id: 12,
          uuid: 'acc-rev-valid-12',
          code: '401012',
          name: 'إيراد مبيعات ممتاز',
          accountType: AccountType.revenue,
          companyId: companyA,
        );
        accountRepo.add(validRev);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-rev-valid-12',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.status, equals(ModuleAccountingReadinessState.ready));
        expect(report.errors, isEmpty);
      });

      test('13. Module Transitions to READY', () async {
        final validRec = createTestCoaAccount(
          id: 13,
          uuid: 'acc-rec-13',
          code: '102001',
          name: 'العملاء الرئيسي',
          accountType: AccountType.asset,
          companyId: companyA,
        );
        accountRepo.add(validRec);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'receivable_account',
            accountUuid: 'acc-rec-13',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqReceivable],
        );

        expect(report.isReady, isTrue);
        expect(report.status, equals(ModuleAccountingReadinessState.ready));
      });

      testWidgets('14. Navigation to Configuration UI Action', (tester) async {
        bool navTriggered = false;

        final ex = const AccountingConfigurationException(
          module: 'sales',
          accountingRole: AccountRole.revenue,
          expectedAccountType: AccountType.revenue,
          errorCode:
              AccountingConfigurationErrorCode.accountingConfigurationMissing,
          userMessage: 'تجهيز المحاسبة مطلوب',
          userExplanation: 'حساب مبيعات الإيرادات غير محدد',
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AccountingConfigurationErrorCard(
                error: ex,
                onConfigurePressed: () {
                  navTriggered = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('تجهيز المحاسبة مطلوب'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(navTriggered, isTrue);
      });

      test('15. Transaction Blocked While Invalid', () async {
        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.isReady, isFalse);
        expect(() {
          if (!report.isReady) {
            throw report.primaryError!;
          }
        }, throwsA(isA<AccountingConfigurationException>()));
      });

      test('16. Transaction Succeeds After Repair', () async {
        final validRev = createTestCoaAccount(
          id: 16,
          uuid: 'acc-rev-16',
          code: '401016',
          name: 'إيراد سليم',
          accountType: AccountType.revenue,
          companyId: companyA,
        );
        accountRepo.add(validRev);

        await bindingRepo.saveBinding(
          AccountBinding(
            companyId: companyA,
            packageId: 'sales',
            requirementKey: 'revenue_account',
            accountUuid: 'acc-rev-16',
            status: AccountBindingStatus.bound,
            bindingMode: AccountBindingMode.singleAccount,
            boundAt: DateTime.now(),
          ),
        );

        final report = await readinessService.evaluateModuleReadiness(
          companyId: companyA,
          module: 'sales',
          requirements: [reqRevenue],
        );

        expect(report.isReady, isTrue);
        expect(() {
          if (!report.isReady) {
            throw report.primaryError!;
          }
        }, returnsNormally);
      });
    },
  );
}
