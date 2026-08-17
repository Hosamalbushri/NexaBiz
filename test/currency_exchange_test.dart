import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_ledger_adapter.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/domain/models/financial_transaction_exception.dart';
import 'package:stock_count/modules/receipts_payments/domain/services/financial_transaction_validator.dart';
import 'helpers/fake_account_repository.dart';
import 'helpers/journal_posting_test_helper.dart';

class _RecordingJournals implements JournalRepository {
  JournalEntryDraft? lastDraft;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft) async {
    lastDraft = draft;
    return JournalEntry(
      id: 1,
      uuid: 'entry-1',
      entryDate: draft.entryDate,
      voucherNumber: draft.voucherNumber,
      voucherType: draft.voucherType,
      currencyCode: draft.currencyCode,
      isPosted: draft.isPosted,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      description: draft.description,
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
      lines: [
        for (var i = 0; i < draft.lines.length; i++)
          JournalLine(
            id: i + 1,
            uuid: 'line-$i',
            entryUuid: 'entry-1',
            accountUuid: draft.lines[i].accountUuid,
            debit: draft.lines[i].debit,
            credit: draft.lines[i].credit,
            currencyCode: draft.lines[i].currencyCode,
            lineDescription: draft.lines[i].lineDescription,
            sortOrder: draft.lines[i].sortOrder,
          ),
      ],
    );
  }

  @override
  Future<JournalEntry?> getByUuid(String uuid) async => null;

  @override
  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) async =>
      null;

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {}

  @override
  Future<void> softDeleteByUuid(String uuid) async {}

  @override
  Future<List<JournalEntryHeader>> listHeaders({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? query,
    int? limit,
    int? afterId,
  }) async =>
      const [];

  @override
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
    int? limit,
    AccountLedgerCursor? after,
  }) async =>
      const [];

  @override
  Future<List<String>> listCurrencyCodesForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async =>
      const [];

  @override
  Future<double> sumNetBefore({
    required String accountUuid,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  }) async =>
      0;

  @override
  Future<List<MonetaryFxPositionRow>> listMonetaryFxPositions({
    required DateTime asOfInclusive,
    required String baseCurrencyCode,
  }) async =>
      const [];
}

void main() {
  const validator = FinancialTransactionValidator();

  FinancialTransactionDraft exchangeDraft({
    double fromAmount = 375,
    double toAmount = 100,
    String fromCurrency = 'SAR',
    String toCurrency = 'USD',
    double fromRate = 1,
    double toRate = 3.75,
    String cashId = 'cash-1',
  }) {
    return FinancialTransactionDraft(
      transactionType: TransactionType.currencyExchange,
      source: TransactionSource.currencyExchange,
      transactionDate: DateTime.utc(2026, 3, 1),
      amount: fromAmount,
      currencyCode: fromCurrency,
      baseCurrencyCode: 'SAR',
      exchangeRate: fromRate,
      counterAmount: toAmount,
      counterCurrencyCode: toCurrency,
      counterExchangeRate: toRate,
      cashAccountId: cashId,
      cashAccountName: 'Main cash',
      counterAccountId: cashId,
      counterAccountName: 'Main cash',
      paymentMethod: RpPaymentMethod.cash,
      lines: [
        FinancialTransactionLine(
          accountId: cashId,
          accountName: 'Main cash',
          amount: toAmount,
          currencyCode: toCurrency,
          exchangeRate: toRate,
          lineOrder: 0,
        ),
      ],
    );
  }

  test('rejects same from/to currency', () {
    expect(
      () => validator.validate(
        exchangeDraft(fromCurrency: 'SAR', toCurrency: 'SAR', toAmount: 100),
      ),
      throwsA(
        isA<FinancialTransactionException>().having(
          (e) => e.code,
          'code',
          FinancialTransactionException.currenciesMustDiffer,
        ),
      ),
    );
  });

  test('allows base difference for realized FX on exchange', () {
    expect(
      () => validator.validate(
        exchangeDraft(fromAmount: 100, toAmount: 50, toRate: 3.75),
      ),
      returnsNormally,
    );
  });

  test('accepts balanced currency exchange', () {
    expect(() => validator.validate(exchangeDraft()), returnsNormally);
  });

  test('ledger posts debit to-currency and credit from-currency on same box',
      () async {
    final journals = _RecordingJournals();
    final adapter = AccountingRpLedgerAdapter(
      posting: journalPostingWithLegacyPolicy(journals: journals),
      accounts: FakeAccountRepository.withSystemFx(),
    );

    final now = DateTime.utc(2026, 3, 1);
    final txn = FinancialTransaction(
      id: 1,
      uuid: 'fx-1',
      transactionType: TransactionType.currencyExchange,
      source: TransactionSource.currencyExchange,
      transactionNumber: '1',
      transactionDate: now,
      amount: 375,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: 100,
      counterCurrencyCode: 'USD',
      counterExchangeRate: 3.75,
      cashAccountId: 'cash-1',
      cashAccountName: 'Main cash',
      counterAccountId: 'cash-1',
      counterAccountName: 'Main cash',
      paymentMethod: RpPaymentMethod.cash,
      documentStatus: TransactionStatus.posted,
      createdAt: now,
      updatedAt: now,
      lines: [
        FinancialTransactionLine(
          accountId: 'cash-1',
          accountName: 'Main cash',
          amount: 100,
          currencyCode: 'USD',
          exchangeRate: 3.75,
          lineOrder: 0,
        ),
      ],
    );

    await adapter.syncTransaction(txn);

    final draft = journals.lastDraft!;
    expect(draft.sourceType, 'currency_exchange');
    expect(draft.allowUnbalancedMultiCurrency, isTrue);
    expect(draft.lines, hasLength(2));
    expect(draft.lines[0].accountUuid, 'cash-1');
    expect(draft.lines[0].debit, 100);
    expect(draft.lines[0].currencyCode, 'USD');
    expect(draft.lines[1].accountUuid, 'cash-1');
    expect(draft.lines[1].credit, 375);
    expect(draft.lines[1].currencyCode, 'SAR');
  });

  test('ledger posts FX gain when to-base exceeds from-base', () async {
    final journals = _RecordingJournals();
    final accounts = FakeAccountRepository.withSystemFx();
    final adapter = AccountingRpLedgerAdapter(
      posting: journalPostingWithLegacyPolicy(journals: journals),
      accounts: accounts,
    );

    final now = DateTime.utc(2026, 3, 1);
    final txn = FinancialTransaction(
      id: 2,
      uuid: 'fx-2',
      transactionType: TransactionType.currencyExchange,
      source: TransactionSource.currencyExchange,
      transactionNumber: '2',
      transactionDate: now,
      amount: 100,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: 30,
      counterCurrencyCode: 'USD',
      counterExchangeRate: 3.75,
      cashAccountId: 'cash-1',
      cashAccountName: 'Main cash',
      counterAccountId: 'cash-1',
      counterAccountName: 'Main cash',
      paymentMethod: RpPaymentMethod.cash,
      documentStatus: TransactionStatus.posted,
      createdAt: now,
      updatedAt: now,
      lines: const [
        FinancialTransactionLine(
          accountId: 'cash-1',
          accountName: 'Main cash',
          amount: 30,
          currencyCode: 'USD',
          exchangeRate: 3.75,
          lineOrder: 0,
        ),
      ],
    );

    await adapter.syncTransaction(txn);

    final draft = journals.lastDraft!;
    expect(draft.lines, hasLength(3));
    final fxLine = draft.lines[2];
    expect(fxLine.accountUuid, systemAccountUuid('fx_gain'));
    expect(fxLine.credit, 12.5);
    expect(fxLine.currencyCode, 'SAR');
  });
}
