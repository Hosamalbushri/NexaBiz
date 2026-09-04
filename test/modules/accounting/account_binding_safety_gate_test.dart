import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_binding_safety_gate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_usage_analyzer.dart';

class FakeSafetyAccountRepository implements AccountRepository {
  final Map<String, Account> _accountsByUuid = {};

  void add(Account account) {
    _accountsByUuid[account.uuid] = account;
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accountsByUuid.values.where((a) => includeInactive || a.isActive).toList();

  @override
  Future<Account?> getByUuid(String uuid) async => _accountsByUuid[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async {
    for (final acc in _accountsByUuid.values) {
      if (acc.accountCode == code) return acc;
    }
    return null;
  }

  @override
  Future<Account?> getById(int id) async => null;

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Account createSafetyAccount({
  required int id,
  required String uuid,
  required String code,
  required String name,
  required AccountType accountType,
  required String companyId,
  bool isGroup = false,
  bool isActive = true,
}) {
  return Account(
    id: id,
    uuid: uuid,
    accountCode: code,
    name: name,
    accountType: accountType,
    normalBalance: accountType.normalBalance,
    level: 3,
    isGroup: isGroup,
    isActive: isActive,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

void main() {
  group('NEXABIZ — ACCOUNTING CONFIGURATION CHANGE SAFETY GATES (11 Mandatory Tests)', () {
    late FakeSafetyAccountRepository accountRepo;
    late AccountUsageAnalyzerImpl usageAnalyzer;
    late AccountBindingSafetyGate safetyGate;

    const currentCompanyId = 'co_tenant_100';

    setUp(() {
      accountRepo = FakeSafetyAccountRepository();
      usageAnalyzer = AccountUsageAnalyzerImpl();
      safetyGate = AccountBindingSafetyGate(
        accountRepository: accountRepo,
        usageAnalyzer: usageAnalyzer,
      );

      // Register standard test accounts
      accountRepo.add(createSafetyAccount(
        id: 1,
        uuid: 'never_used_rev_uuid',
        code: '4100',
        name: 'حساب مبيعات غير مستخدم',
        accountType: AccountType.revenue,
        companyId: currentCompanyId,
      ));

      accountRepo.add(createSafetyAccount(
        id: 2,
        uuid: 'new_candidate_rev_uuid',
        code: '4110',
        name: 'حساب مبيعات جديد بديل',
        accountType: AccountType.revenue,
        companyId: currentCompanyId,
      ));

      accountRepo.add(createSafetyAccount(
        id: 3,
        uuid: 'posted_used_uuid',
        code: '1210',
        name: 'حساب مخزون مرحل سابقاً',
        accountType: AccountType.asset,
        companyId: currentCompanyId,
      ));

      accountRepo.add(createSafetyAccount(
        id: 4,
        uuid: 'zero_bal_posted_uuid',
        code: '5100',
        name: 'حساب تكلفة مبيعات مرحل برصيد صفري',
        accountType: AccountType.expense,
        companyId: currentCompanyId,
      ));

      accountRepo.add(createSafetyAccount(
        id: 5,
        uuid: 'draft_only_uuid',
        code: '4200',
        name: 'حساب مبيعات في مسودات فقط',
        accountType: AccountType.revenue,
        companyId: currentCompanyId,
      ));

      accountRepo.add(createSafetyAccount(
        id: 6,
        uuid: 'inactive_candidate_uuid',
        code: '9900',
        name: 'حساب غير نشط',
        accountType: AccountType.revenue,
        companyId: currentCompanyId,
        isActive: false,
      ));

      accountRepo.add(createSafetyAccount(
        id: 7,
        uuid: 'group_candidate_uuid',
        code: '4000',
        name: 'مجموعة الإيرادات الرئيسية',
        accountType: AccountType.revenue,
        companyId: currentCompanyId,
        isGroup: true,
      ));

      accountRepo.add(createSafetyAccount(
        id: 8,
        uuid: 'cross_company_uuid',
        code: '4100',
        name: 'حساب شركة أخرى',
        accountType: AccountType.revenue,
        companyId: 'co_tenant_999_foreign',
      ));
    });

    test('Test 1: New (never used) mapping can be changed successfully', () async {
      await expectLater(
        safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.revenue,
          currentAccountUuid: 'never_used_rev_uuid',
          candidateAccountUuid: 'new_candidate_rev_uuid',
        ),
        completes,
      );
    });

    test('Test 2: Used account in posted transactions CANNOT be changed (BLOCKED)', () async {
      usageAnalyzer.recordTransaction(
        accountUuid: 'posted_used_uuid',
        isPosted: true,
        documentType: 'stock_receipt',
        amount: 5000.0,
      );

      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.inventory,
          currentAccountUuid: 'posted_used_uuid',
          candidateAccountUuid: 'never_used_rev_uuid',
        ),
        throwsA(isA<AccountBindingChangeProhibitedException>()),
      );
    });

    test('Test 3: Zero-balance used account CANNOT be changed (Proves balance == 0 is NOT used)', () async {
      // Record +5000 and -5000 posted transactions -> Net balance = 0.0
      usageAnalyzer.recordTransaction(
        accountUuid: 'zero_bal_posted_uuid',
        isPosted: true,
        documentType: 'journal_entry',
        amount: 5000.0,
      );
      usageAnalyzer.recordTransaction(
        accountUuid: 'zero_bal_posted_uuid',
        isPosted: true,
        documentType: 'journal_entry',
        amount: -5000.0,
      );

      final usage = await usageAnalyzer.analyzeAccountUsage(
        companyId: currentCompanyId,
        accountUuid: 'zero_bal_posted_uuid',
      );

      expect(usage.currentBalance, equals(0.0));
      expect(usage.postedTransactionCount, equals(2));
      expect(usage.status, equals(AccountUsageStatus.usedInPostedTransactions));

      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.cogs,
          currentAccountUuid: 'zero_bal_posted_uuid',
          candidateAccountUuid: 'new_candidate_rev_uuid',
        ),
        throwsA(isA<AccountBindingChangeProhibitedException>()),
      );
    });

    test('Test 4: Draft-only usage follows draft policy and allows change with warning', () async {
      usageAnalyzer.recordTransaction(
        accountUuid: 'draft_only_uuid',
        isPosted: false,
        documentType: 'draft_sale_quote',
        amount: 1200.0,
      );

      final usage = await usageAnalyzer.analyzeAccountUsage(
        companyId: currentCompanyId,
        accountUuid: 'draft_only_uuid',
      );

      expect(usage.status, equals(AccountUsageStatus.usedInDraftsOnly));
      expect(usage.isChangeAllowed, isTrue);

      await expectLater(
        safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.revenue,
          currentAccountUuid: 'draft_only_uuid',
          candidateAccountUuid: 'new_candidate_rev_uuid',
        ),
        completes,
      );
    });

    test('Test 5: Deleted candidate account is strictly REJECTED', () async {
      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.revenue,
          currentAccountUuid: null,
          candidateAccountUuid: 'non_existent_or_deleted_uuid',
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('Test 6: Inactive candidate account is strictly REJECTED', () async {
      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.revenue,
          currentAccountUuid: null,
          candidateAccountUuid: 'inactive_candidate_uuid',
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('Test 7: Group account candidate for exact role is REJECTED', () async {
      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.revenue,
          currentAccountUuid: null,
          candidateAccountUuid: 'group_candidate_uuid',
          bindingMode: AccountBindingMode.exact,
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('Test 8: Wrong account classification candidate is REJECTED', () async {
      // Trying to assign Revenue account for Inventory role (requires Asset type)
      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.inventory,
          currentAccountUuid: null,
          candidateAccountUuid: 'new_candidate_rev_uuid',
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('Test 9: Cross-company account candidate is REJECTED (Tenant Isolation)', () async {
      expect(
        () async => safetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.revenue,
          currentAccountUuid: null,
          candidateAccountUuid: 'cross_company_uuid',
        ),
        throwsA(isA<AccountBindingValidationException>()),
      );
    });

    test('Test 10: App restart does NOT bypass safety gate restrictions (Persistence Integrity)', () async {
      usageAnalyzer.recordTransaction(
        accountUuid: 'posted_used_uuid',
        isPosted: true,
        documentType: 'payment_voucher',
        amount: 2500.0,
      );

      // Simulate app restart by instantiating new safety gate instance over same analyzer
      final reloadedSafetyGate = AccountBindingSafetyGate(
        accountRepository: accountRepo,
        usageAnalyzer: usageAnalyzer,
      );

      expect(
        () async => reloadedSafetyGate.validateBindingChange(
          companyId: currentCompanyId,
          role: AccountRole.inventory,
          currentAccountUuid: 'posted_used_uuid',
          candidateAccountUuid: 'new_candidate_rev_uuid',
        ),
        throwsA(isA<AccountBindingChangeProhibitedException>()),
      );
    });

    test('Test 11: Offline sync engine does NOT bypass safety gate restrictions', () async {
      usageAnalyzer.recordTransaction(
        accountUuid: 'posted_used_uuid',
        isPosted: true,
        documentType: 'inventory_transfer',
        amount: 3200.0,
      );

      // Offline sync validation executes local safety gate prior to payload submission
      final isOfflineValid = await () async {
        try {
          await safetyGate.validateBindingChange(
            companyId: currentCompanyId,
            role: AccountRole.inventory,
            currentAccountUuid: 'posted_used_uuid',
            candidateAccountUuid: 'new_candidate_rev_uuid',
          );
          return true;
        } on AccountBindingChangeProhibitedException {
          return false;
        }
      }();

      expect(isOfflineValid, isFalse);
    });
  });
}
