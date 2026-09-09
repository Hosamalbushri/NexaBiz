import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
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

class FailingLedgerPostingPort implements RpLedgerPostingPort {
  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    throw const JournalException('GL posting simulated failure');
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {}
}

void main() {
  late ReceiptsPaymentsDatabase db;
  late FinancialTransactionRepositoryImpl repoCompanyA;
  late FinancialTransactionRepositoryImpl repoCompanyB;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;
  late UnpostFinancialTransaction unpostTxn;
  late CancelFinancialTransaction cancelTxn;
  late TestVoucherBookPort voucherBookPort;

  setUp(() {
    db = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    voucherBookPort = TestVoucherBookPort();

    repoCompanyA = FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => 'company_a',
    );

    repoCompanyB = FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => 'company_b',
    );

    createTxn = CreateFinancialTransaction(
      repository: repoCompanyA,
      permissionGuard: const AllowAllPermissionGuard(),
      voucherBookPort: voucherBookPort,
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );

    postTxn = PostFinancialTransaction(
      repository: repoCompanyA,
      permissionGuard: const AllowAllPermissionGuard(),
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );

    unpostTxn = UnpostFinancialTransaction(
      repository: repoCompanyA,
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );

    cancelTxn = CancelFinancialTransaction(
      repository: repoCompanyA,
      permissionGuard: const AllowAllPermissionGuard(),
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-02 — Receipt & Payment Domain Lifecycle Tests', () {
    test(
      '1. Receipt vs Payment type distinction and mandatory identity',
      () async {
        final receiptDraft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.manualReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 1000.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 1000.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: 'cash_account_uuid_1',
          counterAccountId: 'customer_account_uuid_1',
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
          description: 'Customer payment receipt',
        );

        final receipt = await createTxn(receiptDraft);

        expect(receipt.transactionType, TransactionType.receipt);
        expect(receipt.uuid.length, 36);
        expect(receipt.transactionNumber, startsWith('REC-'));
        expect(receipt.amount, 1000.0);
        expect(receipt.documentStatus, TransactionStatus.unposted);

        final paymentDraft = FinancialTransactionDraft(
          transactionType: TransactionType.payment,
          source: TransactionSource.manualPayment,
          transactionDate: DateTime.now().toUtc(),
          amount: 500.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 500.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: 'cash_account_uuid_1',
          counterAccountId: 'supplier_account_uuid_1',
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
          description: 'Supplier payment',
        );

        final payment = await createTxn(paymentDraft);

        expect(payment.transactionType, TransactionType.payment);
        expect(payment.transactionNumber, startsWith('PAY-'));
        expect(payment.amount, 500.0);
        expect(payment.documentStatus, TransactionStatus.unposted);
      },
    );

    test(
      '2. State Lifecycle Transitions: unposted -> posted -> unposted -> cancelled',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.manualReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 1500.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 1500.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: 'cash_account_uuid_1',
          counterAccountId: 'revenue_account_uuid_1',
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final created = await createTxn(draft);
        expect(created.documentStatus, TransactionStatus.unposted);

        // Post
        final posted = await postTxn(created.id);
        expect(posted.documentStatus, TransactionStatus.posted);

        // Verify Immutability of Posted transaction
        expect(
          () => repoCompanyA.update(
            posted.id,
            FinancialTransactionDraft(
              transactionType: TransactionType.receipt,
              source: TransactionSource.manualReceipt,
              transactionDate: DateTime.now().toUtc(),
              amount: 2000.0,
              currencyCode: 'SAR',
              baseCurrencyCode: 'SAR',
              exchangeRate: 1.0,
              counterAmount: 2000.0,
              counterCurrencyCode: 'SAR',
              counterExchangeRate: 1.0,
              cashAccountId: 'cash_account_uuid_1',
              counterAccountId: 'revenue_account_uuid_1',
              paymentMethod: RpPaymentMethod.cash,
            ),
          ),
          throwsA(isA<JournalException>()),
        );

        // Unpost
        final unposted = await unpostTxn(posted.id);
        expect(unposted.documentStatus, TransactionStatus.unposted);

        // Cancel
        final cancelled = await cancelTxn(unposted.id);
        expect(cancelled.isCancelled, isTrue);

        // Cannot re-post cancelled transaction
        expect(
          () => postTxn(cancelled.id),
          throwsA(isA<FinancialTransactionException>()),
        );
      },
    );

    test('3. Atomic posting rollback on ledger failure', () async {
      final failingPostTxn = PostFinancialTransaction(
        repository: repoCompanyA,
        permissionGuard: const AllowAllPermissionGuard(),
        ledgerPosting: FailingLedgerPostingPort(),
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 800.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 800.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: 'cash_account_uuid_1',
        counterAccountId: 'revenue_account_uuid_1',
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);

      expect(
        () => failingPostTxn(created.id),
        throwsA(isA<JournalException>()),
      );

      // Document status must remain unposted
      final fetched = await repoCompanyA.getById(created.id);
      expect(fetched?.documentStatus, TransactionStatus.unposted);
    });

    test('4. Idempotency guard on duplicate posting', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.payment,
        source: TransactionSource.manualPayment,
        transactionDate: DateTime.now().toUtc(),
        amount: 300.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 300.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: 'cash_account_uuid_1',
        counterAccountId: 'expense_account_uuid_1',
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final posted1 = await postTxn(created.id);

      // Attempt posting already posted transaction
      expect(
        () => postTxn(posted1.id),
        throwsA(isA<FinancialTransactionException>()),
      );
    });

    test('5. Multi-tenant company isolation', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 2500.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 2500.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: 'cash_account_uuid_company_a',
        counterAccountId: 'customer_account_uuid_company_a',
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final createdCompanyA = await createTxn(draft);

      // Company A can access its document
      final fetchedByCompanyA = await repoCompanyA.getById(createdCompanyA.id);
      expect(fetchedByCompanyA, isNotNull);
      expect(fetchedByCompanyA?.uuid, createdCompanyA.uuid);

      // Company B cannot see Company A transaction
      final fetchedByCompanyB = await repoCompanyB.getById(createdCompanyA.id);
      expect(fetchedByCompanyB, isNull);

      final fetchedByUuidCompanyB = await repoCompanyB.getByUuid(
        createdCompanyA.uuid,
      );
      expect(fetchedByUuidCompanyB, isNull);
    });
  });
}
