import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_ledger_adapter.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
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

  FinancialTransactionDraft transferDraft({
    String fromId = 'from-box',
    String toId = 'to-box',
    double amount = 100,
  }) {
    return FinancialTransactionDraft(
      transactionType: TransactionType.transfer,
      source: TransactionSource.cashBoxTransfer,
      transactionDate: DateTime.utc(2026, 8, 17),
      amount: amount,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: amount,
      counterCurrencyCode: 'SAR',
      counterExchangeRate: 1,
      voucherBookId: 'book',
      cashAccountId: fromId,
      cashAccountName: 'Cash A',
      counterAccountId: toId,
      counterAccountName: 'Cash B',
      paymentMethod: RpPaymentMethod.cash,
      description: 'نقل--17/8/2026',
      lines: [
        FinancialTransactionLine(
          accountId: toId,
          accountName: 'Cash B',
          amount: amount,
          currencyCode: 'SAR',
          exchangeRate: 1,
          lineOrder: 0,
        ),
      ],
    );
  }

  test('rejects transfer when from and to are the same cash box', () {
    expect(
      () => validator.validate(transferDraft(fromId: 'same', toId: 'same')),
      throwsA(
        isA<FinancialTransactionException>().having(
          (e) => e.code,
          'code',
          FinancialTransactionException.sameAccounts,
        ),
      ),
    );
  });

  test('accepts balanced same-currency cash box transfer', () {
    expect(() => validator.validate(transferDraft()), returnsNormally);
  });

  test('ledger posts Dr destination and Cr source for transfer', () async {
    final journals = _RecordingJournals();
    final adapter = AccountingRpLedgerAdapter(
      posting: journalPostingWithLegacyPolicy(journals: journals),
      accounts: FakeAccountRepository.withSystemFx(),
    );

    final txn = FinancialTransaction(
      id: 1,
      uuid: 'txn-transfer-1',
      transactionNumber: '161000001',
      transactionType: TransactionType.transfer,
      source: TransactionSource.cashBoxTransfer,
      transactionDate: DateTime.utc(2026, 8, 17),
      amount: 250,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: 250,
      counterCurrencyCode: 'SAR',
      counterExchangeRate: 1,
      cashAccountId: 'from-uuid',
      cashAccountName: 'Main cash',
      counterAccountId: 'to-uuid',
      counterAccountName: 'Petty cash',
      paymentMethod: RpPaymentMethod.cash,
      description: 'نقل يومي',
      createdAt: DateTime.utc(2026, 8, 17),
      updatedAt: DateTime.utc(2026, 8, 17),
      lines: const [
        FinancialTransactionLine(
          accountId: 'to-uuid',
          accountName: 'Petty cash',
          amount: 250,
          currencyCode: 'SAR',
          exchangeRate: 1,
          lineOrder: 0,
        ),
      ],
    );

    await adapter.syncTransaction(txn);

    final draft = journals.lastDraft!;
    expect(draft.sourceType, 'transfer');
    expect(draft.voucherType, 'نقل');
    expect(draft.lines, hasLength(2));
    expect(draft.lines[0].accountUuid, 'to-uuid');
    expect(draft.lines[0].debit, 250);
    expect(draft.lines[0].credit, 0);
    expect(draft.lines[1].accountUuid, 'from-uuid');
    expect(draft.lines[1].debit, 0);
    expect(draft.lines[1].credit, 250);
  });

  test('TransactionSource.forType returns cashBoxTransfer for transfer', () {
    final sources = TransactionSourceX.forType(TransactionType.transfer);
    expect(sources, [TransactionSource.cashBoxTransfer]);
  });

  test('sourceTypeFor maps transfer', () {
    expect(
      AccountingRpLedgerAdapter.sourceTypeFor(TransactionType.transfer),
      'transfer',
    );
    expect(
      AccountingRpLedgerAdapter.voucherTypeLabel(TransactionType.transfer),
      'نقل',
    );
  });
}
