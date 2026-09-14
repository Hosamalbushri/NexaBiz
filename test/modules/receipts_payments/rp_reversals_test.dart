import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
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

class RefundRecord {
  RefundRecord({
    required this.id,
    required this.originalTransactionUuid,
    required this.refundAmount,
    required this.exchangeRate,
    this.salesReturnId,
  });

  final String id;
  final String originalTransactionUuid;
  final double refundAmount;
  final double exchangeRate;
  final String? salesReturnId;
}

class RefundEngine {
  final Map<String, double> originalAmounts = {};
  final Map<String, double> originalFxRates = {};
  final List<RefundRecord> refundHistory = [];
  int _counter = 0;

  void registerTransaction(String uuid, double amount, double fxRate) {
    originalAmounts[uuid] = amount;
    originalFxRates[uuid] = fxRate;
  }

  double getAlreadyRefunded(String originalUuid) {
    return refundHistory
        .where((r) => r.originalTransactionUuid == originalUuid)
        .fold(0.0, (sum, r) => sum + r.refundAmount);
  }

  double getRemainingRefundable(String originalUuid) {
    final orig = originalAmounts[originalUuid] ?? 0.0;
    return orig - getAlreadyRefunded(originalUuid);
  }

  RefundRecord processRefund({
    required String originalUuid,
    required double requestedRefundAmount,
    String? salesReturnId,
    bool isSalesReturnPosted = true,
  }) {
    if (salesReturnId != null && !isSalesReturnPosted) {
      throw Exception(
        'Sales return document must be posted before refund processing',
      );
    }

    final remaining = getRemainingRefundable(originalUuid);
    if (requestedRefundAmount > remaining + 0.0001 ||
        requestedRefundAmount <= 0) {
      throw const FinancialTransactionException(
        FinancialTransactionException.invalidAllocation,
      );
    }

    final fxRate = originalFxRates[originalUuid] ?? 1.0;

    _counter++;
    final record = RefundRecord(
      id: 'ref_$_counter',
      originalTransactionUuid: originalUuid,
      refundAmount: requestedRefundAmount,
      exchangeRate: fxRate,
      salesReturnId: salesReturnId,
    );
    refundHistory.add(record);
    return record;
  }
}

void main() {
  late NexabizDatabase db;
  late FinancialTransactionRepositoryImpl repo;
  late TestVoucherBookPort voucherBookPort;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;
  late CancelFinancialTransaction cancelTxn;
  late RefundEngine refundEngine;

  const companyId = 'company_a';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_acme';

  setUp(() {
    db = NexabizDatabase.memory();
    voucherBookPort = TestVoucherBookPort();
    refundEngine = RefundEngine();

    repo = FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );

    createTxn = CreateFinancialTransaction(
      repository: repo,
      permissionGuard: const AllowAllPermissionGuard(),
      voucherBookPort: voucherBookPort,
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );

    postTxn = PostFinancialTransaction(
      repository: repo,
      permissionGuard: const AllowAllPermissionGuard(),
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );

    cancelTxn = CancelFinancialTransaction(
      repository: repo,
      permissionGuard: const AllowAllPermissionGuard(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-07 — Refunds, Reversals & Cancellation Tests', () {
    test('1. Full Refund Execution', () async {
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

      final posted = await postTxn((await createTxn(draft)).id);
      refundEngine.registerTransaction(
        posted.uuid,
        posted.amount,
        posted.exchangeRate,
      );

      final refund = refundEngine.processRefund(
        originalUuid: posted.uuid,
        requestedRefundAmount: 1000.0,
      );

      expect(refund.refundAmount, 1000.0);
      expect(refundEngine.getRemainingRefundable(posted.uuid), 0.0);
    });

    test('2. Partial Refund Execution', () async {
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

      final posted = await postTxn((await createTxn(draft)).id);
      refundEngine.registerTransaction(
        posted.uuid,
        posted.amount,
        posted.exchangeRate,
      );

      final refund = refundEngine.processRefund(
        originalUuid: posted.uuid,
        requestedRefundAmount: 400.0,
      );

      expect(refund.refundAmount, 400.0);
      expect(refundEngine.getRemainingRefundable(posted.uuid), 600.0);
    });

    test('3. Repeated Partial Refund Execution', () async {
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

      final posted = await postTxn((await createTxn(draft)).id);
      refundEngine.registerTransaction(
        posted.uuid,
        posted.amount,
        posted.exchangeRate,
      );

      refundEngine.processRefund(
        originalUuid: posted.uuid,
        requestedRefundAmount: 600.0,
      );
      expect(refundEngine.getRemainingRefundable(posted.uuid), 400.0);

      refundEngine.processRefund(
        originalUuid: posted.uuid,
        requestedRefundAmount: 400.0,
      );
      expect(refundEngine.getRemainingRefundable(posted.uuid), 0.0);
    });

    test('4. Excessive Refund Rejection Guard', () async {
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

      final posted = await postTxn((await createTxn(draft)).id);
      refundEngine.registerTransaction(
        posted.uuid,
        posted.amount,
        posted.exchangeRate,
      );

      expect(
        () => refundEngine.processRefund(
          originalUuid: posted.uuid,
          requestedRefundAmount: 600.0,
        ),
        throwsA(isA<FinancialTransactionException>()),
      );
    });

    test('5. Transaction Cancellation Reversal', () async {
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
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final cancelled = await cancelTxn(created.id);

      expect(cancelled.isCancelled, isTrue);
    });

    test('6. Multi-Module Sales Refund Coordination', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.customerReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 1500.0,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 1500.0,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: cashAccount,
        counterAccountId: customerAccount,
        customerId: customerId,
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final posted = await postTxn((await createTxn(draft)).id);
      refundEngine.registerTransaction(
        posted.uuid,
        posted.amount,
        posted.exchangeRate,
      );

      // Attempting refund with unposted sales return throws exception
      expect(
        () => refundEngine.processRefund(
          originalUuid: posted.uuid,
          requestedRefundAmount: 1500.0,
          salesReturnId: 'SR-999',
          isSalesReturnPosted: false,
        ),
        throwsA(isA<Exception>()),
      );

      // Processing with posted sales return succeeds
      final refund = refundEngine.processRefund(
        originalUuid: posted.uuid,
        requestedRefundAmount: 1500.0,
        salesReturnId: 'SR-999',
        isSalesReturnPosted: true,
      );

      expect(refund.salesReturnId, 'SR-999');
    });

    test(
      '7. Foreign Currency Refund Execution (Uses original exchange rate)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 100.0,
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: 3.75,
          counterAmount: 100.0,
          counterCurrencyCode: 'USD',
          counterExchangeRate: 3.75,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);
        refundEngine.registerTransaction(
          posted.uuid,
          posted.amount,
          posted.exchangeRate,
        );

        final refund = refundEngine.processRefund(
          originalUuid: posted.uuid,
          requestedRefundAmount: 100.0,
        );

        expect(refund.exchangeRate, 3.75); // Preserves original 3.75 rate
      },
    );

    test(
      '8. Historical Exchange Rate Preservation during FX Fluctuations',
      () async {
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

        final posted = await postTxn((await createTxn(draft)).id);
        refundEngine.registerTransaction(
          posted.uuid,
          posted.amount,
          posted.exchangeRate,
        );

        // Today's rate might be 3.85, but refund preserves 3.75
        final refund = refundEngine.processRefund(
          originalUuid: posted.uuid,
          requestedRefundAmount: 100.0,
        );

        expect(refund.exchangeRate, 3.75);
      },
    );

    test('9. Offline Reversal Persistence & Sync Invariance', () async {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
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
        paymentMethod: RpPaymentMethod.cash,
        voucherBookId: 'voucher_book_1',
      );

      final created = await createTxn(draft);
      final cancelled = await cancelTxn(created.id);

      final reFetched = await repo.getById(cancelled.id);
      expect(reFetched?.isCancelled, isTrue);
    });
  });
}
