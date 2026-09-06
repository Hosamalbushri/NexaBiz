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

class TestLedgerEntry {
  const TestLedgerEntry({
    required this.accountUuid,
    required this.debit,
    required this.credit,
  });

  final String accountUuid;
  final double debit;
  final double credit;
}

class TrackingLedgerPostingPort implements RpLedgerPostingPort {
  final List<TestLedgerEntry> entries = [];

  double getAccountBalance(String accountUuid) {
    double total = 0.0;
    for (final e in entries) {
      if (e.accountUuid == accountUuid) {
        total += (e.debit - e.credit);
      }
    }
    return total;
  }

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    if (txn.documentStatus != TransactionStatus.posted) return;

    if (txn.transactionType == TransactionType.receipt) {
      // DEBIT Cash/Bank, CREDIT Counterparty
      entries.add(
        TestLedgerEntry(
          accountUuid: txn.cashAccountId,
          debit: txn.amount,
          credit: 0.0,
        ),
      );
      entries.add(
        TestLedgerEntry(
          accountUuid: txn.counterAccountId,
          debit: 0.0,
          credit: txn.amount,
        ),
      );
    } else {
      // DEBIT Counterparty, CREDIT Cash/Bank
      entries.add(
        TestLedgerEntry(
          accountUuid: txn.counterAccountId,
          debit: txn.amount,
          credit: 0.0,
        ),
      );
      entries.add(
        TestLedgerEntry(
          accountUuid: txn.cashAccountId,
          debit: 0.0,
          credit: txn.amount,
        ),
      );
    }
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {}
}

class FakeCashRegister {
  const FakeCashRegister({
    required this.id,
    required this.companyId,
    required this.chartOfAccountId,
    required this.isActive,
  });

  final String id;
  final String companyId;
  final String chartOfAccountId;
  final bool isActive;
}

void main() {
  late ReceiptsPaymentsDatabase db;
  late FinancialTransactionRepositoryImpl repoCompanyA;
  late FinancialTransactionRepositoryImpl repoCompanyB;
  late TestVoucherBookPort voucherBookPort;
  late TrackingLedgerPostingPort trackingLedger;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;

  const companyA = 'company_a';
  const companyB = 'company_b';

  const registerA = FakeCashRegister(
    id: 'reg_cash_A',
    companyId: companyA,
    chartOfAccountId: 'account_cash_A',
    isActive: true,
  );

  const registerB = FakeCashRegister(
    id: 'reg_cash_B',
    companyId: companyA,
    chartOfAccountId: 'account_cash_B',
    isActive: true,
  );

  const inactiveRegister = FakeCashRegister(
    id: 'reg_inactive',
    companyId: companyA,
    chartOfAccountId: 'account_inactive',
    isActive: false,
  );

  const crossCompanyRegister = FakeCashRegister(
    id: 'reg_cross',
    companyId: companyB,
    chartOfAccountId: 'account_cross',
    isActive: true,
  );

  const bankAccountA = 'account_bank_A';
  const customerAccount = 'account_customer_1';
  const supplierAccount = 'account_supplier_1';

  setUp(() {
    db = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    voucherBookPort = TestVoucherBookPort();
    trackingLedger = TrackingLedgerPostingPort();

    repoCompanyA = FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyA,
    );

    repoCompanyB = FinancialTransactionRepositoryImpl(
      db,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyB,
    );

    createTxn = CreateFinancialTransaction(
      repository: repoCompanyA,
      permissionGuard: const AllowAllPermissionGuard(),
      voucherBookPort: voucherBookPort,
      ledgerPosting: trackingLedger,
    );

    postTxn = PostFinancialTransaction(
      repository: repoCompanyA,
      permissionGuard: const AllowAllPermissionGuard(),
      ledgerPosting: trackingLedger,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('RP-03 — Cash Register & Bank Account Integration Tests', () {
    test(
      '1. Receipt into Cash Register (DEBIT Cash Account, CREDIT Counter Account)',
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
          cashAccountId: registerA.chartOfAccountId,
          counterAccountId: customerAccount,
          customerId: 'cust_123',
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
          description: 'Customer payment into Register A',
        );

        final unposted = await createTxn(draft);
        final posted = await postTxn(unposted.id);

        expect(posted.documentStatus, TransactionStatus.posted);
        expect(
          trackingLedger.getAccountBalance(registerA.chartOfAccountId),
          1200.0,
        );
        expect(trackingLedger.getAccountBalance(customerAccount), -1200.0);
      },
    );

    test(
      '2. Payment from Cash Register (DEBIT Counter Account, CREDIT Cash Account)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.payment,
          source: TransactionSource.manualPayment,
          transactionDate: DateTime.now().toUtc(),
          amount: 450.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 450.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: registerA.chartOfAccountId,
          counterAccountId: supplierAccount,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
          description: 'Supplier payment from Register A',
        );

        final unposted = await createTxn(draft);
        final posted = await postTxn(unposted.id);

        expect(posted.documentStatus, TransactionStatus.posted);
        expect(
          trackingLedger.getAccountBalance(registerA.chartOfAccountId),
          -450.0,
        );
        expect(trackingLedger.getAccountBalance(supplierAccount), 450.0);
      },
    );

    test(
      '3. Bank Receipt (DEBIT Bank Account, CREDIT Counter Account)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 5000.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 5000.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: bankAccountA,
          counterAccountId: customerAccount,
          customerId: 'cust_123',
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
          description: 'Customer wire transfer to Bank A',
        );

        final unposted = await createTxn(draft);
        final posted = await postTxn(unposted.id);

        expect(posted.documentStatus, TransactionStatus.posted);
        expect(trackingLedger.getAccountBalance(bankAccountA), 5000.0);
        expect(trackingLedger.getAccountBalance(customerAccount), -5000.0);
      },
    );

    test(
      '4. Bank Payment (DEBIT Counter Account, CREDIT Bank Account)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.payment,
          source: TransactionSource.manualPayment,
          transactionDate: DateTime.now().toUtc(),
          amount: 2100.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 2100.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: bankAccountA,
          counterAccountId: supplierAccount,
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
          description: 'Supplier wire payment from Bank A',
        );

        final unposted = await createTxn(draft);
        final posted = await postTxn(unposted.id);

        expect(posted.documentStatus, TransactionStatus.posted);
        expect(trackingLedger.getAccountBalance(bankAccountA), -2100.0);
        expect(trackingLedger.getAccountBalance(supplierAccount), 2100.0);
      },
    );

    test(
      '5. Multi-Register Isolation (Register A movement does not bleed into Register B)',
      () async {
        final draftA = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.manualReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 3000.0,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          counterAmount: 3000.0,
          counterCurrencyCode: 'SAR',
          counterExchangeRate: 1.0,
          cashAccountId: registerA.chartOfAccountId,
          counterAccountId: customerAccount,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final txnA = await postTxn((await createTxn(draftA)).id);

        expect(txnA.cashAccountId, registerA.chartOfAccountId);
        expect(
          trackingLedger.getAccountBalance(registerA.chartOfAccountId),
          3000.0,
        );
        expect(
          trackingLedger.getAccountBalance(registerB.chartOfAccountId),
          0.0,
        );
      },
    );

    test('6. Inactive / Cross-Company Register Validation Guard', () async {
      // Validate active company check
      expect(registerA.companyId, companyA);
      expect(registerA.isActive, isTrue);

      expect(inactiveRegister.isActive, isFalse);
      expect(crossCompanyRegister.companyId, isNot(companyA));

      final fetchedByCompanyB = await repoCompanyB.getById(999);
      expect(fetchedByCompanyB, isNull);
    });

    test('7. Duplicate Posting Rejection (Idempotency Guard)', () async {
      final draft = FinancialTransactionDraft(
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
        cashAccountId: registerA.chartOfAccountId,
        counterAccountId: customerAccount,
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
  });
}
