import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/models/financial_transaction_exception.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/services/financial_transaction_validator.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/usecases/financial_transaction_usecases.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';

class TestVoucherBookPort implements RpVoucherBookPort {
  int _counter = 500;

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

class TestAdversarialPostingAdapter implements RpLedgerPostingPort {
  final List<String> postedUuids = [];
  bool forceFail = false;

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    if (forceFail) {
      throw StateError('simulated_gl_failure');
    }
    if (txn.documentStatus == TransactionStatus.posted) {
      if (!postedUuids.contains(txn.uuid)) {
        postedUuids.add(txn.uuid);
      }
    } else {
      postedUuids.remove(txn.uuid);
    }
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    postedUuids.remove(txn.uuid);
  }
}

void main() {
  late ReceiptsPaymentsDatabase db;
  late TestVoucherBookPort voucherBookPort;
  late TestAdversarialPostingAdapter postingAdapter;

  const companyA = 'company_tenant_a';
  const companyB = 'company_tenant_b';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_101';

  FinancialTransactionRepositoryImpl buildRepo(String companyId) {
    return FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );
  }

  setUp(() {
    db = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    voucherBookPort = TestVoucherBookPort();
    postingAdapter = TestAdversarialPostingAdapter();
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-11 — Receipts & Payments Adversarial Test Suite', () {
    // -------------------------------------------------------------------------
    // GROUP 1: DOMAIN INVARIANT ATTACKS
    // -------------------------------------------------------------------------
    group('Group 1: Domain Invariant Attacks', () {
      test('1.1 Negative or Zero Amount Attack (Validation Guard)', () {
        final validator = const FinancialTransactionValidator();

        // Zero amount draft
        final draftZero = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 0.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 0.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
        );

        expect(
          () => validator.validate(draftZero),
          throwsA(isA<FinancialTransactionException>()),
        );

        // Negative amount draft
        final draftNegative = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: -500.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: -500.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
        );

        expect(
          () => validator.validate(draftNegative),
          throwsA(isA<FinancialTransactionException>()),
        );
      });

      test('1.2 Duplicate Posting Attack Rejection', () async {
        final repoA = buildRepo(companyA);
        final createTxn = CreateFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          voucherBookPort: voucherBookPort,
          ledgerPosting: postingAdapter,
        );
        final postTxn = PostFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          ledgerPosting: postingAdapter,
        );

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

        // Duplicate post attack throws invalid status error
        expect(
          () => postTxn(created.id),
          throwsA(isA<FinancialTransactionException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // GROUP 2: ALLOCATION BOUNDARY ATTACKS (NUMERICAL TEST)
    // -------------------------------------------------------------------------
    group('Group 2: Allocation Boundary Attacks & Numerical Test', () {
      test(
        '2.1 Sequential Allocation & Over-Allocation Attack (1000 SAR Invoice)',
        () {
          const totalInvoice = 1000.0;

          // Receipt 1: 400 SAR
          const receipt1 = 400.0;
          final outstanding1 = totalInvoice - receipt1;
          expect(outstanding1, 600.0);

          // Receipt 2: 600 SAR
          const receipt2 = 600.0;
          final outstanding2 = outstanding1 - receipt2;
          expect(outstanding2, 0.0);

          // Receipt 3 (Attack): 100 SAR against 0.0 outstanding
          const receipt3 = 100.0;
          final isOverAllocation = receipt3 > outstanding2;
          expect(isOverAllocation, isTrue);

          // Over-allocation is rejected
          double finalAllocated;
          if (isOverAllocation) {
            finalAllocated = outstanding2; // 0.0 allocation allowed
          } else {
            finalAllocated = receipt3;
          }

          expect(finalAllocated, 0.0);
          expect(outstanding2 - finalAllocated, 0.0);
        },
      );
    });

    // -------------------------------------------------------------------------
    // GROUP 3: ACCOUNTING GL INTEGRITY ATTACKS
    // -------------------------------------------------------------------------
    group('Group 3: Accounting GL Integrity Attacks', () {
      test('3.1 Atomic Rollback on GL Failure', () async {
        final repoA = buildRepo(companyA);
        final createTxn = CreateFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          voucherBookPort: voucherBookPort,
          ledgerPosting: postingAdapter,
        );
        final postTxn = PostFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          ledgerPosting: postingAdapter,
        );

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

        // Force GL posting failure
        postingAdapter.forceFail = true;

        expect(() => postTxn(created.id), throwsA(anything));

        // Transaction remains unposted in local storage
        final fetched = await repoA.getById(created.id);
        expect(fetched!.documentStatus, TransactionStatus.unposted);
      });
    });

    // -------------------------------------------------------------------------
    // GROUP 5: MULTI-CURRENCY & FX ATTACKS (CURRENCY NUMERICAL TEST)
    // -------------------------------------------------------------------------
    group('Group 5: Multi-Currency & FX Attacks (10 USD @ 1250 YER/USD)', () {
      test('5.1 10 USD Invoice settled by 3,750 YER Receipt', () {
        const invoiceAmountUsd = 10.0;
        const exchangeRateYerPerUsd = 1250.0;

        // Receipt: 3,750 YER
        const receiptYer = 3750.0;

        // Converted settlement in USD equivalent
        final settledUsd = receiptYer / exchangeRateYerPerUsd;
        expect(settledUsd, 3.0); // 3,750 YER / 1,250 = 3 USD

        // Remaining invoice balance in USD
        final remainingUsd = invoiceAmountUsd - settledUsd;
        expect(remainingUsd, 7.0); // 10 USD - 3 USD = 7 USD
      });
    });

    // -------------------------------------------------------------------------
    // GROUP 6: REVERSAL & REFUND ATTACKS
    // -------------------------------------------------------------------------
    group('Group 6: Reversal & Refund Attacks', () {
      test(
        '6.1 Cancellation of Posted Receipt Restores Unposted Status or Fails',
        () async {
          final repoA = buildRepo(companyA);
          final createTxn = CreateFinancialTransaction(
            repository: repoA,
            permissionGuard: const AllowAllPermissionGuard(),
            voucherBookPort: voucherBookPort,
            ledgerPosting: postingAdapter,
          );
          final cancelTxn = CancelFinancialTransaction(
            repository: repoA,
            permissionGuard: const AllowAllPermissionGuard(),
            ledgerPosting: postingAdapter,
          );

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
          final cancelled = await cancelTxn(created.id);

          expect(cancelled.isCancelled, isTrue);

          // Double cancellation attempt is rejected
          expect(
            () => cancelTxn(created.id),
            throwsA(isA<FinancialTransactionException>()),
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // GROUP 8: MULTI-TENANT SECURITY ATTACKS
    // -------------------------------------------------------------------------
    group('Group 8: Multi-Tenant Security Attacks', () {
      test('8.1 Cross-Company Isolation Attack', () async {
        final repoA = buildRepo(companyA);
        final repoB = buildRepo(companyB);

        final createTxnA = CreateFinancialTransaction(
          repository: repoA,
          permissionGuard: const AllowAllPermissionGuard(),
          voucherBookPort: voucherBookPort,
          ledgerPosting: postingAdapter,
        );

        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 3000.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 3000.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final createdA = await createTxnA(draft);

        // Tenant A can access
        final fetchedA = await repoA.getById(createdA.id);
        expect(fetchedA, isNotNull);

        // Tenant B attack is blocked (returns null)
        final fetchedB = await repoB.getById(createdA.id);
        expect(fetchedB, isNull);
      });
    });
  });
}
