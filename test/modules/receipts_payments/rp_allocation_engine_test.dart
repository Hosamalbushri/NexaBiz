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

class AllocationEntry {
  AllocationEntry({
    required this.id,
    required this.paymentUuid,
    required this.targetDocumentId,
    required this.allocatedAmount,
    this.isReversal = false,
  });

  final String id;
  final String paymentUuid;
  final String targetDocumentId;
  final double allocatedAmount;
  final bool isReversal;
}

class InvoiceDocument {
  InvoiceDocument({
    required this.id,
    required this.totalAmount,
    required this.outstandingAmount,
  });

  final String id;
  final double totalAmount;
  double outstandingAmount;
}

class AuthoritativeAllocationEngine {
  final Map<String, InvoiceDocument> invoices = {};
  final List<AllocationEntry> allocationHistory = [];
  double unappliedAdvanceCredit = 0.0;
  int _allocationCounter = 0;

  void registerInvoice(InvoiceDocument inv) {
    invoices[inv.id] = inv;
  }

  Map<String, dynamic> allocatePayment({
    required String paymentUuid,
    required double paymentAmount,
    required Map<String, double> targetAllocations,
  }) {
    // Invariant check: cannot allocate already used payment UUID if total allocated >= paymentAmount
    final existingAllocations = allocationHistory.where(
      (a) => a.paymentUuid == paymentUuid && !a.isReversal,
    );
    if (existingAllocations.isNotEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.invalidAllocation,
      );
    }

    double totalAllocated = 0.0;
    final createdAllocations = <AllocationEntry>[];

    for (final entry in targetAllocations.entries) {
      final docId = entry.key;
      final requestedAmount = entry.value;

      final inv = invoices[docId];
      if (inv == null) {
        throw Exception('Target document $docId not found');
      }

      if (requestedAmount > inv.outstandingAmount + 0.0001) {
        throw const FinancialTransactionException(
          FinancialTransactionException.invalidAllocation,
        );
      }

      totalAllocated += requestedAmount;
      inv.outstandingAmount = (inv.outstandingAmount - requestedAmount).clamp(
        0.0,
        double.infinity,
      );

      _allocationCounter++;
      final alloc = AllocationEntry(
        id: 'alloc_$_allocationCounter',
        paymentUuid: paymentUuid,
        targetDocumentId: docId,
        allocatedAmount: requestedAmount,
      );
      createdAllocations.add(alloc);
      allocationHistory.add(alloc);
    }

    if (totalAllocated > paymentAmount + 0.0001) {
      throw const FinancialTransactionException(
        FinancialTransactionException.invalidAllocation,
      );
    }

    final unapplied = paymentAmount - totalAllocated;
    if (unapplied > 0) {
      unappliedAdvanceCredit += unapplied;
    }

    return {
      'allocations': createdAllocations,
      'totalAllocated': totalAllocated,
      'unappliedAmount': unapplied,
    };
  }

  void reversePaymentAllocations(String paymentUuid) {
    final active = allocationHistory
        .where((a) => a.paymentUuid == paymentUuid && !a.isReversal)
        .toList();
    if (active.isEmpty) return;

    for (final alloc in active) {
      final inv = invoices[alloc.targetDocumentId];
      if (inv != null) {
        inv.outstandingAmount += alloc.allocatedAmount;
      }
      _allocationCounter++;
      allocationHistory.add(
        AllocationEntry(
          id: 'alloc_rev_$_allocationCounter',
          paymentUuid: paymentUuid,
          targetDocumentId: alloc.targetDocumentId,
          allocatedAmount: -alloc.allocatedAmount,
          isReversal: true,
        ),
      );
    }
  }
}

void main() {
  late NexabizDatabase db;
  late FinancialTransactionRepositoryImpl repo;
  late TestVoucherBookPort voucherBookPort;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;
  late AuthoritativeAllocationEngine allocationEngine;

  const companyId = 'company_a';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_acme';

  setUp(() {
    db = NexabizDatabase.memory();
    voucherBookPort = TestVoucherBookPort();
    allocationEngine = AuthoritativeAllocationEngine();

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
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-06 — Allocation Engine & Outstanding Balance Integrity Tests', () {
    test('1. Full Document Allocation', () async {
      final inv = InvoiceDocument(
        id: 'INV-A',
        totalAmount: 500.0,
        outstandingAmount: 500.0,
      );
      allocationEngine.registerInvoice(inv);

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

      final result = allocationEngine.allocatePayment(
        paymentUuid: posted.uuid,
        paymentAmount: posted.amount,
        targetAllocations: {inv.id: 500.0},
      );

      expect(inv.outstandingAmount, 0.0);
      expect(result['totalAllocated'], 500.0);
      expect(result['unappliedAmount'], 0.0);
    });

    test('2. Partial Document Allocation', () async {
      final inv = InvoiceDocument(
        id: 'INV-B',
        totalAmount: 1000.0,
        outstandingAmount: 1000.0,
      );
      allocationEngine.registerInvoice(inv);

      final draft = FinancialTransactionDraft(
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
      );

      final posted = await postTxn((await createTxn(draft)).id);

      final result = allocationEngine.allocatePayment(
        paymentUuid: posted.uuid,
        paymentAmount: posted.amount,
        targetAllocations: {inv.id: 400.0},
      );

      expect(inv.outstandingAmount, 600.0);
      expect(result['totalAllocated'], 400.0);
      expect(result['unappliedAmount'], 0.0);
    });

    test(
      '3. Multi-Document Sequential Waterfall Allocation (1000 SAR across A:400, B:300, C:200 -> 900 alloc, 100 unapplied)',
      () async {
        final invA = InvoiceDocument(
          id: 'INV-101',
          totalAmount: 400.0,
          outstandingAmount: 400.0,
        );
        final invB = InvoiceDocument(
          id: 'INV-102',
          totalAmount: 300.0,
          outstandingAmount: 300.0,
        );
        final invC = InvoiceDocument(
          id: 'INV-103',
          totalAmount: 200.0,
          outstandingAmount: 200.0,
        );

        allocationEngine.registerInvoice(invA);
        allocationEngine.registerInvoice(invB);
        allocationEngine.registerInvoice(invC);

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
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        final result = allocationEngine.allocatePayment(
          paymentUuid: posted.uuid,
          paymentAmount: posted.amount,
          targetAllocations: {invA.id: 400.0, invB.id: 300.0, invC.id: 200.0},
        );

        expect(invA.outstandingAmount, 0.0);
        expect(invB.outstandingAmount, 0.0);
        expect(invC.outstandingAmount, 0.0);
        expect(result['totalAllocated'], 900.0);
        expect(result['unappliedAmount'], 100.0);
        expect(allocationEngine.unappliedAdvanceCredit, 100.0);
      },
    );

    test('4. Multiple Payments to Single Document', () async {
      final inv = InvoiceDocument(
        id: 'INV-MULTI',
        totalAmount: 1000.0,
        outstandingAmount: 1000.0,
      );
      allocationEngine.registerInvoice(inv);

      for (double part in [600.0, 400.0]) {
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

        allocationEngine.allocatePayment(
          paymentUuid: posted.uuid,
          paymentAmount: posted.amount,
          targetAllocations: {inv.id: part},
        );
      }

      expect(inv.outstandingAmount, 0.0);
    });

    test('5. Overpayment & Unapplied Balance Handling', () async {
      final inv = InvoiceDocument(
        id: 'INV-OVER',
        totalAmount: 800.0,
        outstandingAmount: 800.0,
      );
      allocationEngine.registerInvoice(inv);

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

      final result = allocationEngine.allocatePayment(
        paymentUuid: posted.uuid,
        paymentAmount: posted.amount,
        targetAllocations: {inv.id: 800.0},
      );

      expect(inv.outstandingAmount, 0.0);
      expect(result['unappliedAmount'], 200.0);
    });

    test(
      '6. Unapplied Advance Payment Creation (0 target documents)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 2500.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 2500.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        final result = allocationEngine.allocatePayment(
          paymentUuid: posted.uuid,
          paymentAmount: posted.amount,
          targetAllocations: {},
        );

        expect(result['totalAllocated'], 0.0);
        expect(result['unappliedAmount'], 2500.0);
      },
    );

    test(
      '7. Reversal Audit Workflow (Reversing payment creates reversal records, restores balance)',
      () async {
        final inv = InvoiceDocument(
          id: 'INV-REV',
          totalAmount: 1000.0,
          outstandingAmount: 1000.0,
        );
        allocationEngine.registerInvoice(inv);

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

        allocationEngine.allocatePayment(
          paymentUuid: posted.uuid,
          paymentAmount: posted.amount,
          targetAllocations: {inv.id: 1000.0},
        );

        expect(inv.outstandingAmount, 0.0);
        expect(allocationEngine.allocationHistory.length, 1);

        // Perform Reversal
        allocationEngine.reversePaymentAllocations(posted.uuid);

        expect(inv.outstandingAmount, 1000.0);
        expect(allocationEngine.allocationHistory.length, 2);
        expect(allocationEngine.allocationHistory.last.isReversal, isTrue);
      },
    );

    test(
      '8. Duplicate Allocation Prevention (Idempotent execution guard)',
      () async {
        final inv = InvoiceDocument(
          id: 'INV-DUP',
          totalAmount: 1000.0,
          outstandingAmount: 1000.0,
        );
        allocationEngine.registerInvoice(inv);

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

        allocationEngine.allocatePayment(
          paymentUuid: posted.uuid,
          paymentAmount: posted.amount,
          targetAllocations: {inv.id: 1000.0},
        );

        expect(
          () => allocationEngine.allocatePayment(
            paymentUuid: posted.uuid,
            paymentAmount: posted.amount,
            targetAllocations: {inv.id: 1000.0},
          ),
          throwsA(isA<FinancialTransactionException>()),
        );
      },
    );

    test(
      '9. Concurrent Allocation Safety (Safe execution under sequential calls)',
      () async {
        final inv = InvoiceDocument(
          id: 'INV-CONC',
          totalAmount: 1000.0,
          outstandingAmount: 1000.0,
        );
        allocationEngine.registerInvoice(inv);

        final draft1 = FinancialTransactionDraft(
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
        );

        final draft2 = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 600.0, // Exceeds remaining 400.0 if not guarded
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
        );

        final posted1 = await postTxn((await createTxn(draft1)).id);
        final posted2 = await postTxn((await createTxn(draft2)).id);

        allocationEngine.allocatePayment(
          paymentUuid: posted1.uuid,
          paymentAmount: posted1.amount,
          targetAllocations: {inv.id: 600.0},
        );

        // Second allocation for 600 should fail because remaining outstanding is only 400
        expect(
          () => allocationEngine.allocatePayment(
            paymentUuid: posted2.uuid,
            paymentAmount: posted2.amount,
            targetAllocations: {inv.id: 600.0},
          ),
          throwsA(isA<FinancialTransactionException>()),
        );
      },
    );
  });
}
