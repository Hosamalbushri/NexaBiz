import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';
import 'package:stock_count/modules/accounting/domain/validation/accounting_validation_engine_impl.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void addAccount(Account acc) {
    _accounts[acc.uuid] = acc;
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _accounts[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async => null;

  @override
  Future<Account?> getById(int id) async => null;

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      includeInactive
          ? _accounts.values.toList()
          : _accounts.values.where((a) => a.isActive).toList();


  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountingPolicy implements AccountingPolicyPort {
  bool periodOpen = true;
  bool validCurrency = true;

  @override
  Future<AccountingLifecycleState> getLifecycleState(String companyId) async =>
      AccountingLifecycleState.active;

  @override
  Future<bool> isConfigured(String companyId) async => true;

  @override
  Future<bool> isActive(String companyId) async => true;

  @override
  Future<bool> areAccountMappingsConfigured(String companyId) async => true;

  @override
  bool isValidTransactionDate(DateTime date) =>
      date.year >= 2000 && date.year <= 2100;

  @override
  Future<bool> isValidCurrency({
    required String companyId,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async =>
      validCurrency;

  @override
  Future<bool> isPeriodOpen({
    required String companyId,
    required DateTime transactionDate,
  }) async =>
      periodOpen;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async =>
      AccountingPolicyDecision.allowed(
        lifecycleState: AccountingLifecycleState.active,
      );
}

void main() {
  late FakeAccountRepository fakeAccountRepo;
  late FakeAccountingPolicy fakePolicy;
  late AccountingValidationEngine engine;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);
  final accCashUuid = 'acc-cash-001';
  final accArUuid = 'acc-ar-001';
  final accGroupUuid = 'acc-group-001';
  final accInactiveUuid = 'acc-inactive-001';

  final accCash = Account(
    id: accCashUuid,
    accountCode: '1101',
    name: 'Cash Account',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: validDate,
    updatedAt: validDate,
  );

  final accAr = Account(
    id: accArUuid,
    accountCode: '1102',
    name: 'AR Account',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: validDate,
    updatedAt: validDate,
  );

  final accGroup = Account(
    id: accGroupUuid,
    accountCode: '1100',
    name: 'Assets Group',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 0,
    isGroup: true,
    isActive: true,
    isSystemAccount: true,
    companyId: companyId,
    createdAt: validDate,
    updatedAt: validDate,
  );

  final accInactive = Account(
    id: accInactiveUuid,
    accountCode: '1103',
    name: 'Inactive Cash',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: false,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: validDate,
    updatedAt: validDate,
  );

  setUp(() {
    fakeAccountRepo = FakeAccountRepository();
    fakePolicy = FakeAccountingPolicy();
    engine = AccountingValidationEngine(
      accountRepository: fakeAccountRepo,
      policyPort: fakePolicy,
    );

    fakeAccountRepo.addAccount(accCash);
    fakeAccountRepo.addAccount(accAr);
    fakeAccountRepo.addAccount(accGroup);
    fakeAccountRepo.addAccount(accInactive);
  });

  group('AccountingValidationEngine Behavioral Tests', () {
    test('approves valid balanced effect', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-100',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accCashUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: accArUuid,
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await engine.validateEffect(effect);
      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty);
    });

    test('rejects unbalanced journal effect', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-101',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accCashUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: accArUuid,
            debit: 0.0,
            credit: 80.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await engine.validateEffect(effect);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'UNBALANCED_JOURNAL'), isTrue);
    });

    test('rejects non-existent account UUID', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-102',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accCashUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: 'non-existent-acc-uuid',
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await engine.validateEffect(effect);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'ACCOUNT_NOT_FOUND'), isTrue);
    });

    test('rejects group header account (non-postable)', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-103',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accGroupUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: accArUuid,
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await engine.validateEffect(effect);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'ACCOUNT_NON_POSTABLE'), isTrue);
    });

    test('rejects inactive account', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-104',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accInactiveUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: accArUuid,
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await engine.validateEffect(effect);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'ACCOUNT_INACTIVE'), isTrue);
    });

    test('rejects posting when period is closed', () async {
      fakePolicy.periodOpen = false;

      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-105',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accCashUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: accArUuid,
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await engine.validateEffect(effect);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'CLOSED_PERIOD'), isTrue);
    });

    test('detects duplicate posting by source identity', () async {
      final sourceRef = AccountingSourceReference(
        sourceType: 'sale',
        sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
      );
      final tracker = <String>{'$companyId:${sourceRef.canonicalKey}'};
      final trackingEngine = AccountingValidationEngine(
        accountRepository: fakeAccountRepo,
        policyPort: fakePolicy,
        postedSourceTracker: tracker,
      );

      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: sourceRef,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-106',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: accCashUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: accArUuid,
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final report = await trackingEngine.validateEffect(effect);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'DUPLICATE_POSTING'), isTrue);
    });
  });
}
