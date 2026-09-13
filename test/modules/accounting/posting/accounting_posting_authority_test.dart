import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/domain/builder/authoritative_journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_journal_contracts.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';
import 'package:stock_count/modules/accounting/domain/integrity/journal_integrity_engine_impl.dart';
import 'package:stock_count/modules/accounting/domain/posting/accounting_posting_authority_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';
import 'package:stock_count/modules/accounting/domain/validation/accounting_validation_engine_port.dart';
import 'package:stock_count/modules/accounting/domain/validation/accounting_validation_report.dart';

class FakeJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _entries = {};
  bool shouldFailOnPost = false;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft) async {
    if (shouldFailOnPost) {
      throw Exception('Database write failed (Transaction Rollback simulated)');
    }

    final entryUuid = draft.uuid ?? 'jnl-fake-uuid';
    final lines = draft.lines.map((l) => JournalLine(
      id: 1,
      uuid: l.uuid ?? 'line-uuid',
      entryUuid: entryUuid,
      accountUuid: l.accountUuid,
      debit: l.debit,
      credit: l.credit,
      currencyCode: l.currencyCode,
      sortOrder: l.sortOrder,
      exchangeRateToBase: l.exchangeRateToBase ?? 1.0,
      baseDebit: l.baseDebit ?? l.debit,
      baseCredit: l.baseCredit ?? l.credit,
      lineDescription: l.lineDescription,
    )).toList();

    final entry = JournalEntry(
      id: _entries.length + 1,
      uuid: entryUuid,
      entryDate: draft.entryDate,
      voucherNumber: draft.voucherNumber,
      voucherType: draft.voucherType,
      currencyCode: draft.currencyCode,
      isPosted: draft.isPosted,
      lines: lines,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      description: draft.description,
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
    );

    _entries[entryUuid] = entry;
    return entry;
  }

  @override
  Future<JournalEntry?> getByUuid(String uuid) async => _entries[uuid];

  @override
  Future<JournalEntry?> findBySource({required String sourceType, required String sourceId}) async {
    for (final e in _entries.values) {
      if (e.sourceType == sourceType && e.sourceId == sourceId && e.deletedAt == null) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<void> softDeletePostedAfterReverse(String uuid) async {
    final existing = _entries[uuid];
    if (existing != null) {
      _entries[uuid] = JournalEntry(
        id: existing.id,
        uuid: existing.uuid,
        entryDate: existing.entryDate,
        voucherNumber: existing.voucherNumber,
        voucherType: existing.voucherType,
        currencyCode: existing.currencyCode,
        isPosted: false,
        lines: existing.lines,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now().toUtc(),
        description: existing.description,
        sourceType: existing.sourceType,
        sourceId: existing.sourceId,
        deletedAt: DateTime.now().toUtc(),
      );
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void addAccount(Account acc) {
    _accounts[acc.uuid] = acc;
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _accounts[uuid];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountingPolicy implements AccountingPolicyPort {
  bool periodOpen = true;

  @override
  Future<AccountingLifecycleState> getLifecycleState(String companyId) async => AccountingLifecycleState.active;

  @override
  Future<bool> isConfigured(String companyId) async => true;

  @override
  Future<bool> isActive(String companyId) async => true;

  @override
  Future<bool> areAccountMappingsConfigured(String companyId) async => true;

  @override
  bool isValidTransactionDate(DateTime date) => true;

  @override
  Future<bool> isValidCurrency({required String companyId, required String currencyCode, required String baseCurrencyCode}) async => true;

  @override
  Future<bool> isPeriodOpen({required String companyId, required DateTime transactionDate}) async => periodOpen;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({required String companyId, required DateTime transactionDate, required String currencyCode, required String baseCurrencyCode}) async => AccountingPolicyDecision.allowed(lifecycleState: AccountingLifecycleState.active);
}

class FakeValidationEngine implements AccountingValidationEnginePort {
  bool isValid = true;
  String? errorMessage;

  @override
  Future<AccountingValidationReport> validateEffect(AccountingEffect effect) async {
    final results = <AccountingValidationRuleResult>[];
    if (!isValid) {
      results.add(
        AccountingValidationRuleResult(
          rule: 'VALIDATION_FAILED',
          severity: AccountingRuleSeverity.error,
          reason: errorMessage ?? 'Effect validation error',
          actionableMessage: errorMessage ?? 'Effect validation error',
        ),
      );
    }
    return AccountingValidationReport.evaluate(results);
  }

}

void main() {
  late FakeJournalRepository fakeJournalRepo;
  late FakeAccountRepository fakeAccountRepo;
  late FakeAccountingPolicy fakePolicy;
  late FakeValidationEngine fakeValidationEngine;
  late AuthoritativeJournalBuilder builder;
  late JournalIntegrityEngine integrityEngine;
  late AccountingPostingAuthority postingAuthority;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);
  final accCashUuid = 'acc-cash-001';
  final accRevUuid = 'acc-rev-001';

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

  setUp(() {
    fakeJournalRepo = FakeJournalRepository();
    fakeAccountRepo = FakeAccountRepository();
    fakePolicy = FakeAccountingPolicy();
    fakeValidationEngine = FakeValidationEngine();

    fakeAccountRepo.addAccount(accCash);
    fakeAccountRepo.addAccount(accRev);

    builder = AuthoritativeJournalBuilder(validationEngine: fakeValidationEngine);
    integrityEngine = JournalIntegrityEngine(
      accountRepository: fakeAccountRepo,
      policyPort: fakePolicy,
    );

    postingAuthority = AccountingPostingAuthority(
      validationEngine: fakeValidationEngine,
      journalBuilder: builder,
      integrityEngine: integrityEngine,
      journalRepository: fakeJournalRepo,
    );
  });

  AccountingEffect createValidEffect({String? sourceId}) {
    return AccountingEffect(
      context: AccountingTransactionContext(
        companyId: companyId,
        sourceReference: AccountingSourceReference(
          sourceType: 'sale',
          sourceId: sourceId ?? 'doc-sale-100',
        ),
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      ),
      voucherNumber: 'INV-100',
      voucherType: 'Sale',
      lines: [
        AccountingEffectLine(
          accountUuid: accCashUuid,
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'USD',
        ),
        AccountingEffectLine(
          accountUuid: accRevUuid,
          debit: 0.0,
          credit: 100.0,
          currencyCode: 'USD',
        ),
      ],
    );
  }

  group('AccountingPostingAuthority Mandatory Tests', () {
    test('1. Valid Posting: end-to-end pipeline succeeds', () async {
      final effect = createValidEffect();
      final result = await postingAuthority.postEffect(effect);

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);
      expect(result.journal!.isPosted, isTrue);
      expect(result.journal!.context.companyId, companyId);
    });

    test('2. Invalid Posting: Validation Engine rejection prevents posting', () async {
      fakeValidationEngine.isValid = false;
      fakeValidationEngine.errorMessage = 'Period closed in validation';

      final effect = createValidEffect();
      final result = await postingAuthority.postEffect(effect);

      expect(result.isSuccess, isFalse);
      expect(result.journal, isNull);
      expect(result.failureReason, contains('Period closed in validation'));
    });

    test('3. Database Rollback: DB failure returns failed result cleanly', () async {
      fakeJournalRepo.shouldFailOnPost = true;

      final effect = createValidEffect();
      final result = await postingAuthority.postEffect(effect);

      expect(result.isSuccess, isFalse);
      expect(result.journal, isNull);
      expect(result.failureReason, contains('Transaction Rollback simulated'));
    });

    test('4. Closed Period: period closed in policy rejects posting', () async {
      fakePolicy.periodOpen = false;

      final effect = createValidEffect();
      final result = await postingAuthority.postEffect(effect);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, contains('Journal Integrity Engine Rejected Journal'));
    });

    test('5. Reversal Mechanism: posts reversing entry and tombstones original', () async {
      final effect = createValidEffect();
      final postResult = await postingAuthority.postEffect(effect);
      expect(postResult.isSuccess, isTrue);

      final originalUuid = postResult.journal!.uuid;
      final reverseResult = await postingAuthority.reverseJournal(
        journalUuid: originalUuid,
        reason: 'Customer return',
      );

      expect(reverseResult.isSuccess, isTrue);
      final tombstoned = await fakeJournalRepo.getByUuid(originalUuid);
      expect(tombstoned!.deletedAt, isNotNull);
    });
  });
}
