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

class InvoiceRecord {
  InvoiceRecord({
    required this.id,
    required this.totalAmount,
    required this.outstandingAmount,
  });

  final String id;
  final double totalAmount;
  double outstandingAmount;
}

class CustomerSettlementEngine {
  final Map<String, InvoiceRecord> invoices = {};
  double customerAdvanceCredit = 0.0;

  void addInvoice(InvoiceRecord invoice) {
    invoices[invoice.id] = invoice;
  }

  void allocateReceipt({
    required String receiptUuid,
    required double receiptAmount,
    required Map<String, double> targetAllocations,
  }) {
    double totalAllocated = 0.0;

    for (final entry in targetAllocations.entries) {
      final invoiceId = entry.key;
      final requestedAmount = entry.value;

      final invoice = invoices[invoiceId];
      if (invoice == null) {
        throw Exception('Target invoice $invoiceId not found');
      }

      if (requestedAmount > invoice.outstandingAmount + 0.0001) {
        throw const FinancialTransactionException(
          FinancialTransactionException.invalidAllocation,
        );
      }

      totalAllocated += requestedAmount;
      invoice.outstandingAmount = (invoice.outstandingAmount - requestedAmount)
          .clamp(0.0, double.infinity);
    }

    if (totalAllocated > receiptAmount + 0.0001) {
      throw const FinancialTransactionException(
        FinancialTransactionException.invalidAllocation,
      );
    }

    // Overpayment / Unapplied amount goes to customer advance credit
    final unapplied = receiptAmount - totalAllocated;
    if (unapplied > 0) {
      customerAdvanceCredit += unapplied;
    }
  }

  void cancelReceiptAllocation({
    required double receiptAmount,
    required Map<String, double> targetAllocations,
  }) {
    double totalAllocated = 0.0;
    for (final entry in targetAllocations.entries) {
      final invoice = invoices[entry.key];
      if (invoice != null) {
        invoice.outstandingAmount += entry.value;
        totalAllocated += entry.value;
      }
    }
    final unapplied = receiptAmount - totalAllocated;
    if (unapplied > 0) {
      customerAdvanceCredit = (customerAdvanceCredit - unapplied).clamp(
        0.0,
        double.infinity,
      );
    }
  }
}

void main() {
  late ReceiptsPaymentsDatabase db;
  late FinancialTransactionRepositoryImpl repo;
  late TestVoucherBookPort voucherBookPort;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;
  late CancelFinancialTransaction cancelTxn;
  late CustomerSettlementEngine settlementEngine;

  const companyId = 'company_a';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_acme_corp';

  setUp(() {
    db = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    voucherBookPort = TestVoucherBookPort();
    settlementEngine = CustomerSettlementEngine();

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
      ledgerPosting: const NoOpRpLedgerPostingPort(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-04 — Customer & Supplier Settlement Tests', () {
    test('1. Full Settlement against single invoice', () async {
      final invoice = InvoiceRecord(
        id: 'INV-1001',
        totalAmount: 1000.0,
        outstandingAmount: 1000.0,
      );
      settlementEngine.addInvoice(invoice);

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
        relatedDocumentId: invoice.id,
        relatedDocumentType: 'sales_invoice',
      );

      final created = await createTxn(draft);
      final posted = await postTxn(created.id);

      expect(posted.documentStatus, TransactionStatus.posted);

      settlementEngine.allocateReceipt(
        receiptUuid: posted.uuid,
        receiptAmount: posted.amount,
        targetAllocations: {invoice.id: 1000.0},
      );

      expect(invoice.outstandingAmount, 0.0);
      expect(settlementEngine.customerAdvanceCredit, 0.0);
    });

    test(
      '2. Partial Settlement (Sequential receipts reduce outstanding to 0 without drift)',
      () async {
        final invoice = InvoiceRecord(
          id: 'INV-1002',
          totalAmount: 1000.0,
          outstandingAmount: 1000.0,
        );
        settlementEngine.addInvoice(invoice);

        // First partial receipt: 400 SAR
        final draft1 = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
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
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
          relatedDocumentId: invoice.id,
          relatedDocumentType: 'sales_invoice',
        );

        final posted1 = await postTxn((await createTxn(draft1)).id);
        settlementEngine.allocateReceipt(
          receiptUuid: posted1.uuid,
          receiptAmount: posted1.amount,
          targetAllocations: {invoice.id: 400.0},
        );

        expect(invoice.outstandingAmount, 600.0);

        // Second partial receipt: 600 SAR
        final draft2 = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 600.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 600.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
          relatedDocumentId: invoice.id,
          relatedDocumentType: 'sales_invoice',
        );

        final posted2 = await postTxn((await createTxn(draft2)).id);
        settlementEngine.allocateReceipt(
          receiptUuid: posted2.uuid,
          receiptAmount: posted2.amount,
          targetAllocations: {invoice.id: 600.0},
        );

        expect(invoice.outstandingAmount, 0.0);
      },
    );

    test(
      '3. Multiple Invoices Settlement (Single receipt split across 2 invoices)',
      () async {
        final invA = InvoiceRecord(
          id: 'INV-2001',
          totalAmount: 700.0,
          outstandingAmount: 700.0,
        );
        final invB = InvoiceRecord(
          id: 'INV-2002',
          totalAmount: 800.0,
          outstandingAmount: 800.0,
        );
        settlementEngine.addInvoice(invA);
        settlementEngine.addInvoice(invB);

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
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        settlementEngine.allocateReceipt(
          receiptUuid: posted.uuid,
          receiptAmount: posted.amount,
          targetAllocations: {invA.id: 700.0, invB.id: 800.0},
        );

        expect(invA.outstandingAmount, 0.0);
        expect(invB.outstandingAmount, 0.0);
      },
    );

    test(
      '4. Multiple Payments Settlement (Multiple receipts applied to single invoice)',
      () async {
        final invoice = InvoiceRecord(
          id: 'INV-3001',
          totalAmount: 2000.0,
          outstandingAmount: 2000.0,
        );
        settlementEngine.addInvoice(invoice);

        for (double part in [500.0, 700.0, 800.0]) {
          final draft = FinancialTransactionDraft(
            transactionType: TransactionType.receipt,
            source: TransactionSource.customerReceipt,
            transactionDate: DateTime.now().toUtc(),
            amount: part,
            currencyCode: 'SAR',
            baseCurrencyCode: 'SAR',
            exchangeRate: 1.0,
            counterAmount: part,
            counterCurrencyCode: 'SAR',
            counterExchangeRate: 1.0,
            cashAccountId: cashAccount,
            counterAccountId: customerAccount,
            customerId: customerId,
            paymentMethod: RpPaymentMethod.cash,
            voucherBookId: 'voucher_book_1',
          );

          final posted = await postTxn((await createTxn(draft)).id);
          settlementEngine.allocateReceipt(
            receiptUuid: posted.uuid,
            receiptAmount: posted.amount,
            targetAllocations: {invoice.id: part},
          );
        }

        expect(invoice.outstandingAmount, 0.0);
      },
    );

    test(
      '5. Overpayment & Advance (Receipt exceeding invoice creates customer advance credit)',
      () async {
        final invoice = InvoiceRecord(
          id: 'INV-4001',
          totalAmount: 1000.0,
          outstandingAmount: 1000.0,
        );
        settlementEngine.addInvoice(invoice);

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

        final posted = await postTxn((await createTxn(draft)).id);

        settlementEngine.allocateReceipt(
          receiptUuid: posted.uuid,
          receiptAmount: posted.amount,
          targetAllocations: {invoice.id: 1000.0},
        );

        expect(invoice.outstandingAmount, 0.0);
        expect(settlementEngine.customerAdvanceCredit, 200.0);
      },
    );

    test(
      '6. Customer Advance Payment (Receipt without target invoice creating advance credit)',
      () async {
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
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        settlementEngine.allocateReceipt(
          receiptUuid: posted.uuid,
          receiptAmount: posted.amount,
          targetAllocations: {},
        );

        expect(settlementEngine.customerAdvanceCredit, 1500.0);
      },
    );

    test(
      '7. Invalid Allocation Rejection (Allocation > remaining outstanding is rejected)',
      () async {
        final invoice = InvoiceRecord(
          id: 'INV-5001',
          totalAmount: 500.0,
          outstandingAmount: 500.0,
        );
        settlementEngine.addInvoice(invoice);

        expect(
          () => settlementEngine.allocateReceipt(
            receiptUuid: 'rec_invalid',
            receiptAmount: 1000.0,
            targetAllocations: {invoice.id: 800.0},
          ),
          throwsA(isA<FinancialTransactionException>()),
        );
      },
    );

    test('8. Duplicate Allocation Rejection (Idempotency Guard)', () async {
      final invoice = InvoiceRecord(
        id: 'INV-6001',
        totalAmount: 1000.0,
        outstandingAmount: 1000.0,
      );
      settlementEngine.addInvoice(invoice);

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

      final unposted = await createTxn(draft);
      final posted = await postTxn(unposted.id);

      expect(
        () => postTxn(posted.id),
        throwsA(isA<FinancialTransactionException>()),
      );
    });

    test(
      '9. Cancellation & Settlement Reversal (Cancelling receipt restores invoice outstanding)',
      () async {
        final invoice = InvoiceRecord(
          id: 'INV-7001',
          totalAmount: 1000.0,
          outstandingAmount: 1000.0,
        );
        settlementEngine.addInvoice(invoice);

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

        settlementEngine.allocateReceipt(
          receiptUuid: posted.uuid,
          receiptAmount: posted.amount,
          targetAllocations: {invoice.id: 1000.0},
        );
        expect(invoice.outstandingAmount, 0.0);

        // Unpost & Cancel
        final unposted = await repo.markUnposted(posted.id);
        await cancelTxn(unposted.id);

        settlementEngine.cancelReceiptAllocation(
          receiptAmount: posted.amount,
          targetAllocations: {invoice.id: 1000.0},
        );

        expect(invoice.outstandingAmount, 1000.0);
      },
    );
  });
}
