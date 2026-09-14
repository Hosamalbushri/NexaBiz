import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/models/financial_transaction_exception.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/usecases/financial_transaction_usecases.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';

class TestVoucherBookPort implements RpVoucherBookPort {
  int _counter = 100;

  @override
  Future<List<RpVoucherBookRef>> listActiveBooks(TransactionType type) async =>
      const [];

  @override
  Future<RpVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<String> allocateNumber({
    required String bookId,
    required TransactionType type,
  }) async {
    _counter++;
    final prefix = type == TransactionType.receipt ? 'REC' : 'PAY';
    return '$prefix-$_counter';
  }
}

class TestJournalEntry {
  TestJournalEntry({
    required this.journalId,
    required this.sourceTransactionUuid,
    required this.debitAccount,
    required this.creditAccount,
    required this.amount,
    required this.baseAmount,
    required this.currencyCode,
  });

  final String journalId;
  final String sourceTransactionUuid;
  final String debitAccount;
  final String creditAccount;
  final double amount;
  final double baseAmount;
  final String currencyCode;
}

class IdempotentPostingAdapter implements RpLedgerPostingPort {
  final List<TestJournalEntry> postedJournals = [];
  bool shouldSimulateFailure = false;
  int postingCallCount = 0;

  Future<String> postTransaction(FinancialTransaction txn) async {
    postingCallCount++;

    if (shouldSimulateFailure) {
      throw Exception('GL Posting Service Connection Timeout');
    }

    final existing = postedJournals
        .where((j) => j.sourceTransactionUuid == txn.uuid)
        .toList();
    if (existing.isNotEmpty) {
      // Idempotent retry returns existing journal ID without creating duplicate
      return existing.first.journalId;
    }

    final baseAmount = txn.amount * txn.exchangeRate;
    final journalId = 'journal_gl_${postedJournals.length + 1}';

    final isReceipt = txn.transactionType == TransactionType.receipt;
    final debitAccount = isReceipt ? txn.cashAccountId : txn.counterAccountId;
    final creditAccount = isReceipt ? txn.counterAccountId : txn.cashAccountId;

    postedJournals.add(
      TestJournalEntry(
        journalId: journalId,
        sourceTransactionUuid: txn.uuid,
        debitAccount: debitAccount,
        creditAccount: creditAccount,
        amount: txn.amount,
        baseAmount: baseAmount,
        currencyCode: txn.currencyCode,
      ),
    );

    return journalId;
  }

  Future<void> unpostTransaction(FinancialTransaction txn) async {
    postedJournals.removeWhere((j) => j.sourceTransactionUuid == txn.uuid);
  }

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    if (txn.documentStatus == TransactionStatus.posted) {
      await postTransaction(txn);
    } else if (txn.documentStatus == TransactionStatus.unposted) {
      await unpostTransaction(txn);
    }
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    postedJournals.removeWhere((j) => j.sourceTransactionUuid == txn.uuid);
  }
}

void main() {
  late NexabizDatabase db;
  late FinancialTransactionRepositoryImpl repo;
  late TestVoucherBookPort voucherBookPort;
  late IdempotentPostingAdapter postingAdapter;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;
  late UnpostFinancialTransaction unpostTxn;

  const companyId = 'company_a';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_acme';

  setUp(() {
    db = NexabizDatabase.memory();
    voucherBookPort = TestVoucherBookPort();
    postingAdapter = IdempotentPostingAdapter();

    repo = FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );

    createTxn = CreateFinancialTransaction(
      repository: repo,
      permissionGuard: const AllowAllPermissionGuard(),
      voucherBookPort: voucherBookPort,
      ledgerPosting: postingAdapter,
    );

    postTxn = PostFinancialTransaction(
      repository: repo,
      permissionGuard: const AllowAllPermissionGuard(),
      ledgerPosting: postingAdapter,
    );

    unpostTxn = UnpostFinancialTransaction(
      repository: repo,
      ledgerPosting: postingAdapter,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-08 — Accounting Posting & Idempotency Integrity Tests', () {
    test('1. Normal Accounting Posting Traceability', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 1000.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 1000.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      expect(posted.documentStatus, TransactionStatus.posted);
      expect(postingAdapter.postedJournals.length, 1);

      final journal = postingAdapter.postedJournals.first;
      expect(journal.sourceTransactionUuid, posted.uuid);
      expect(journal.debitAccount, cashAccount);
      expect(journal.creditAccount, customerAccount);
      expect(journal.baseAmount, 1000.0);
    });

    test(
      '2. Idempotent Retry Execution (Timeout retry -> 1 journal entry)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 500.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 500.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final created = await createTxn(draft);
        await postTxn(created.id);

        expect(postingAdapter.postedJournals.length, 1);

        // Simulating a network retry call on the GL adapter directly
        final txn = (await repo.getById(created.id))!;
        final retriedJournalId = await postingAdapter.postTransaction(txn);

        expect(retriedJournalId, postingAdapter.postedJournals.first.journalId);
        expect(
          postingAdapter.postedJournals.length,
          1,
        ); // Exactly 1 journal entry retained
        expect(
          postingAdapter.postingCallCount,
          2,
        ); // Adapter called twice, but journal creation was idempotent
      },
    );

    test('3. Duplicate Posting Prevention', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 750.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 750.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      await postTxn(created.id);

      // Re-posting an already posted transaction is rejected by domain workflow
      expect(
        () => postTxn(created.id),
        throwsA(isA<FinancialTransactionException>()),
      );
    });

    test('4. Multi-Currency GL Base Balance Enforcement', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 200.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: 3.75,
        counterAmount: 200.0,
        counterCurrencyCode: 'USD',
        counterExchangeRate: 3.75,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.bankTransfer,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      final journal = postingAdapter.postedJournals.firstWhere(
        (j) => j.sourceTransactionUuid == posted.uuid,
      );
      expect(journal.amount, 200.0);
      expect(journal.baseAmount, 750.0); // 200 USD * 3.75 = 750 SAR base
    });

    test('5. Partial Failure Atomic Rollback', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 300.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 300.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);

      // Instruct adapter to fail
      postingAdapter.shouldSimulateFailure = true;

      expect(() => postTxn(created.id), throwsA(isA<Exception>()));

      // Transaction remains unposted in repo
      final reFetched = await repo.getById(created.id);
      expect(reFetched?.documentStatus, TransactionStatus.unposted);
      expect(postingAdapter.postedJournals.isEmpty, isTrue);
    });

    test(
      '6. 4-Way Divergence Protection (Transaction + GL in lockstep)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 1200.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 1200.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final created = await createTxn(draft);
        final posted = await postTxn(created.id);

        expect(posted.documentStatus, TransactionStatus.posted);
        expect(
          postingAdapter.postedJournals.any(
            (j) => j.sourceTransactionUuid == posted.uuid,
          ),
          isTrue,
        );

        final unposted = await unpostTxn(posted.id);
        expect(unposted.documentStatus, TransactionStatus.unposted);
        expect(
          postingAdapter.postedJournals.any(
            (j) => j.sourceTransactionUuid == posted.uuid,
          ),
          isFalse,
        );
      },
    );

    test('7. Reversal Accounting Posting Integrity', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.payment,
        source: TransactionSource.manualPayment,
        transactionDate: DateTime.now().toUtc(),
        amount: 400.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 400.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      final journal = postingAdapter.postedJournals.firstWhere(
        (j) => j.sourceTransactionUuid == posted.uuid,
      );
      // Payment: DEBIT counterAccount, CREDIT cashAccount
      expect(journal.debitAccount, customerAccount);
      expect(journal.creditAccount, cashAccount);
      expect(journal.baseAmount, 400.0);
    });

    test('8. Sync Retry Idempotency Invariance', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 900.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 900.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      final journalId1 = postingAdapter.postedJournals.first.journalId;

      // Simulate multi-sync retry
      final txn = (await repo.getById(posted.id))!;
      final journalId2 = await postingAdapter.postTransaction(txn);
      final journalId3 = await postingAdapter.postTransaction(txn);

      expect(journalId1, journalId2);
      expect(journalId2, journalId3);
      expect(postingAdapter.postedJournals.length, 1);
    });
  });
}
