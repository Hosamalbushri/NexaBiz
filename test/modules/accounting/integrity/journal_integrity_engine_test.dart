import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_journal_contracts.dart';

import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';
import 'package:stock_count/modules/accounting/domain/integrity/journal_integrity_engine_impl.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';

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
  Future<List<Account>> getAll({bool includeInactive = false}) async => _accounts.values.toList();


  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountingPolicy implements AccountingPolicyPort {
  bool periodOpen = true;

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
  bool isValidTransactionDate(DateTime date) => true;

  @override
  Future<bool> isValidCurrency({
    required String companyId,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async => true;

  @override
  Future<bool> isPeriodOpen({
    required String companyId,
    required DateTime transactionDate,
  }) async => periodOpen;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async => AccountingPolicyDecision.allowed(
        lifecycleState: AccountingLifecycleState.active,
      );
}

void main() {
  late FakeAccountRepository fakeAccountRepo;
  late FakeAccountingPolicy fakePolicy;
  late JournalIntegrityEngine engine;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);
  final accCashUuid = 'acc-cash-001';
  final accRevUuid = 'acc-rev-001';
  final accWrongCompanyUuid = 'acc-wrong-company';

  final accCash = Account(
    id: 1,
    uuid: accCashUuid,
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

  final accRev = Account(
    id: 2,
    uuid: accRevUuid,
    accountCode: '4101',
    name: 'Revenue Account',
    accountType: AccountType.revenue,
    normalBalance: NormalBalance.credit,
    level: 1,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: validDate,
    updatedAt: validDate,
  );

  final accWrongCompany = Account(
    id: 3,
    uuid: accWrongCompanyUuid,
    accountCode: '1102',
    name: 'Other Company Cash',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: 'OTHER_COMPANY',
    createdAt: validDate,
    updatedAt: validDate,
  );

  setUp(() {
    fakeAccountRepo = FakeAccountRepository();
    fakePolicy = FakeAccountingPolicy();
    engine = JournalIntegrityEngine(
      accountRepository: fakeAccountRepo,
      policyPort: fakePolicy,
    );

    fakeAccountRepo.addAccount(accCash);
    fakeAccountRepo.addAccount(accRev);
    fakeAccountRepo.addAccount(accWrongCompany);
  });

  AccountingJournal createValidJournal({
    String? entryUuid,
    String? compId,
    DateTime? txDate,
    String? sourceType,
    String? sourceId,
    List<AccountingJournalLine>? lines,
  }) {
    final effectiveCompId = compId ?? companyId;
    final effectiveEntryUuid = entryUuid ?? 'jnl-uuid-001';
    final defaultLines = [
      AccountingJournalLine(
        uuid: 'line-001',
        entryUuid: effectiveEntryUuid,
        accountUuid: accCashUuid,
        debit: 100.0,
        credit: 0.0,
        currencyCode: 'USD',
        exchangeRateToBase: 1.0,
        baseDebit: 100.0,
        baseCredit: 0.0,
      ),
      AccountingJournalLine(
        uuid: 'line-002',
        entryUuid: effectiveEntryUuid,
        accountUuid: accRevUuid,
        debit: 0.0,
        credit: 100.0,
        currencyCode: 'USD',
        exchangeRateToBase: 1.0,
        baseDebit: 0.0,
        baseCredit: 100.0,
      ),
    ];

    return AccountingJournal(
      uuid: effectiveEntryUuid,
      context: AccountingTransactionContext(
        companyId: effectiveCompId,
        sourceReference: AccountingSourceReference(
          sourceType: sourceType ?? 'sale',
          sourceId: sourceId ?? 'doc-100',
        ),
        transactionDate: txDate ?? validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      ),
      voucherNumber: 'INV-100',
      voucherType: 'Sale',
      isPosted: false,
      lines: lines ?? defaultLines,
      createdAt: validDate,
      updatedAt: validDate,
    );
  }

  group('JournalIntegrityEngine 14 Mandatory Invariants', () {
    test('approves valid balanced journal satisfying all invariants', () async {
      final journal = createValidJournal();
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty);
    });

    test('1. COMPANY_INVALID: rejects empty companyId', () async {
      expect(
        () => createValidJournal(compId: '  '),
        throwsA(isA<AccountingFailure>()),
      );
    });

    test('2. CLOSED_PERIOD: rejects transaction date in closed period', () async {
      fakePolicy.periodOpen = false;
      final journal = createValidJournal();
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'CLOSED_PERIOD'), isTrue);
    });

    test('3. SOURCE_REFERENCE_MISSING: rejects empty sourceType', () async {
      expect(
        () => createValidJournal(sourceType: ' '),
        throwsA(isA<ArgumentError>()),
      );
    });


    test('4. LINE_COUNT_INVALID: rejects single-line journal', () async {
      final journal = createValidJournal(lines: [
        AccountingJournalLine(
          uuid: 'line-001',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accCashUuid,
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 100.0,
          baseCredit: 0.0,
        ),
      ]);
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'LINE_COUNT_INVALID'), isTrue);
    });

    test('5. ACCOUNT_NOT_FOUND: rejects non-existent account UUID', () async {
      final journal = createValidJournal(lines: [
        AccountingJournalLine(
          uuid: 'line-001',
          entryUuid: 'jnl-uuid-001',
          accountUuid: 'non-existent-uuid',
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 100.0,
          baseCredit: 0.0,
        ),
        AccountingJournalLine(
          uuid: 'line-002',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accRevUuid,
          debit: 0.0,
          credit: 100.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 0.0,
          baseCredit: 100.0,
        ),
      ]);
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'ACCOUNT_NOT_FOUND'), isTrue);
    });

    test('6. ACCOUNT_COMPANY_MISMATCH: rejects account from different company', () async {
      final journal = createValidJournal(lines: [
        AccountingJournalLine(
          uuid: 'line-001',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accWrongCompanyUuid,
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 100.0,
          baseCredit: 0.0,
        ),
        AccountingJournalLine(
          uuid: 'line-002',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accRevUuid,
          debit: 0.0,
          credit: 100.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 0.0,
          baseCredit: 100.0,
        ),
      ]);
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'ACCOUNT_COMPANY_MISMATCH'), isTrue);
    });

    test('8. INVALID_DIRECTION: rejects line having both debit and credit > 0', () async {
      final journal = createValidJournal(lines: [
        AccountingJournalLine(
          uuid: 'line-001',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accCashUuid,
          debit: 100.0,
          credit: 50.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 100.0,
          baseCredit: 50.0,
        ),
        AccountingJournalLine(
          uuid: 'line-002',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accRevUuid,
          debit: 0.0,
          credit: 50.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 0.0,
          baseCredit: 50.0,
        ),
      ]);
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'INVALID_DIRECTION'), isTrue);
    });

    test('9. UNBALANCED_JOURNAL: rejects unbalanced debits and credits', () async {
      final journal = createValidJournal(lines: [
        AccountingJournalLine(
          uuid: 'line-001',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accCashUuid,
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 100.0,
          baseCredit: 0.0,
        ),
        AccountingJournalLine(
          uuid: 'line-002',
          entryUuid: 'jnl-uuid-001',
          accountUuid: accRevUuid,
          debit: 0.0,
          credit: 80.0,
          currencyCode: 'USD',
          exchangeRateToBase: 1.0,
          baseDebit: 0.0,
          baseCredit: 80.0,
        ),
      ]);
      final report = await engine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'UNBALANCED_JOURNAL'), isTrue);
    });

    test('12. DUPLICATE_JOURNAL: rejects duplicate posted journal', () async {
      final tracker = <String>{'$companyId:sale:doc-100'};
      final trackingEngine = JournalIntegrityEngine(
        accountRepository: fakeAccountRepo,
        policyPort: fakePolicy,
        postedTracker: tracker,
      );

      final journal = createValidJournal(sourceId: 'doc-100');
      final report = await trackingEngine.evaluateIntegrity(journal);
      expect(report.isValid, isFalse);
      expect(report.errors.any((e) => e.rule == 'DUPLICATE_JOURNAL'), isTrue);
    });
  });
}
