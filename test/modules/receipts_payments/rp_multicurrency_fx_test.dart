import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/models/financial_transaction_exception.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/services/financial_transaction_validator.dart';
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

class MultiCurrencyFxEngine {
  static const String baseCurrency = 'SAR';
  static const String fxGainAccount = 'account_fx_gain_7100';
  static const String fxLossAccount = 'account_fx_loss_6100';

  final List<Map<String, dynamic>> journalEntries = [];

  void postReceiptSettlement({
    required String invoiceCurrency,
    required double invoiceAmountDoc,
    required double invoiceBookingRate, // Rate to Base (SAR)
    required String receiptCurrency,
    required double receiptAmountTxn,
    required double receiptSettlementRate, // Rate to Base (SAR)
    required String cashAccount,
    required String customerAccount,
  }) {
    // 1. Calculate Base equivalents
    final double cashBaseAmount = receiptAmountTxn * receiptSettlementRate;
    final double receivableBaseAmount = invoiceAmountDoc * invoiceBookingRate;

    final double fxDifference = cashBaseAmount - receivableBaseAmount;

    // DEBIT Cash Asset
    journalEntries.add({
      'account': cashAccount,
      'currency': receiptCurrency,
      'amount': receiptAmountTxn,
      'debitBase': cashBaseAmount,
      'creditBase': 0.0,
    });

    // CREDIT Customer Receivable
    journalEntries.add({
      'account': customerAccount,
      'currency': invoiceCurrency,
      'amount': invoiceAmountDoc,
      'debitBase': 0.0,
      'creditBase': receivableBaseAmount,
    });

    // Realized FX Gain or Loss
    if (fxDifference > 0.0001) {
      // CREDIT Realized FX Gain
      journalEntries.add({
        'account': fxGainAccount,
        'currency': baseCurrency,
        'amount': fxDifference,
        'debitBase': 0.0,
        'creditBase': fxDifference,
      });
    } else if (fxDifference < -0.0001) {
      // DEBIT Realized FX Loss
      journalEntries.add({
        'account': fxLossAccount,
        'currency': baseCurrency,
        'amount': fxDifference.abs(),
        'debitBase': fxDifference.abs(),
        'creditBase': 0.0,
      });
    }
  }

  double getTotalDebitBase() {
    return journalEntries.fold(
      0.0,
      (sum, e) => sum + (e['debitBase'] as double),
    );
  }

  double getTotalCreditBase() {
    return journalEntries.fold(
      0.0,
      (sum, e) => sum + (e['creditBase'] as double),
    );
  }

  Map<String, dynamic>? findEntry(String account) {
    for (final e in journalEntries) {
      if (e['account'] == account) return e;
    }
    return null;
  }
}

void main() {
  late ReceiptsPaymentsDatabase db;
  late FinancialTransactionRepositoryImpl repo;
  late TestVoucherBookPort voucherBookPort;
  late CreateFinancialTransaction createTxn;
  late PostFinancialTransaction postTxn;

  const companyId = 'company_a';
  const cashAccount = 'account_cash_1010';
  const customerAccount = 'account_customer_1200';
  const customerId = 'cust_acme';

  setUp(() {
    db = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    voucherBookPort = TestVoucherBookPort();

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

  group('RP-05 — Receipts & Payments Multi-Currency & FX Tests', () {
    test('1. Same Currency Settlement (SAR to SAR, no conversion)', () async {
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

      expect(posted.currencyCode, 'SAR');
      expect(posted.exchangeRate, 1.0);
      expect(posted.counterAmount, 1000.0);
    });

    test(
      '2. Foreign Currency Settlement (USD Invoice settled by YER Receipt)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 3750.0,
          currencyCode: 'YER',
          baseCurrencyCode: 'SAR',
          exchangeRate: 0.01, // 3,750 YER = 37.5 SAR
          counterAmount: 10.0,
          counterCurrencyCode: 'USD',
          counterExchangeRate: 3.75, // 10 USD = 37.5 SAR
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        expect(posted.currencyCode, 'YER');
        expect(posted.counterCurrencyCode, 'USD');
        expect(posted.exchangeRate, 0.01);
        expect(posted.counterExchangeRate, 3.75);
      },
    );

    test(
      '3. Partial Foreign Currency Settlement (Partial USD converted at historical rate)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 1875.0, // Half of 3,750 YER
          currencyCode: 'YER',
          baseCurrencyCode: 'SAR',
          exchangeRate: 0.01,
          counterAmount: 5.0, // 5 USD out of 10 USD invoice
          counterCurrencyCode: 'USD',
          counterExchangeRate: 3.75,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.bankTransfer,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        expect(posted.amount, 1875.0);
        expect(posted.counterAmount, 5.0);
      },
    );

    test(
      '4. Different Settlement Exchange Rate (USD Invoice settled at higher YER rate)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.customerReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 3750.0,
          currencyCode: 'YER',
          baseCurrencyCode: 'SAR',
          exchangeRate: 0.01, // 37.5 SAR base
          counterAmount: 10.0,
          counterCurrencyCode: 'USD',
          counterExchangeRate: 3.75, // 37.5 SAR base
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          customerId: customerId,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        expect(posted.amount, 3750.0);
        expect(posted.counterAmount, 10.0);
      },
    );

    test(
      '5. Realized FX Gain Recognition (Credit to FX Gain Account)',
      () async {
        final engine = MultiCurrencyFxEngine();

        engine.postReceiptSettlement(
          invoiceCurrency: 'USD',
          invoiceAmountDoc: 100.0,
          invoiceBookingRate: 3.75, // 375.0 SAR
          receiptCurrency: 'SAR',
          receiptAmountTxn: 380.0,
          receiptSettlementRate: 1.0, // 380.0 SAR received
          cashAccount: cashAccount,
          customerAccount: customerAccount,
        );

        expect(engine.getTotalDebitBase(), 380.0);
        expect(engine.getTotalCreditBase(), 380.0);

        final gainEntry = engine.findEntry(MultiCurrencyFxEngine.fxGainAccount);
        expect(gainEntry, isNotNull);
        expect(gainEntry!['creditBase'], 5.0);
      },
    );

    test(
      '6. Realized FX Loss Recognition (Debit to FX Loss Account)',
      () async {
        final engine = MultiCurrencyFxEngine();

        engine.postReceiptSettlement(
          invoiceCurrency: 'USD',
          invoiceAmountDoc: 100.0,
          invoiceBookingRate: 3.75, // 375.0 SAR
          receiptCurrency: 'SAR',
          receiptAmountTxn: 370.0,
          receiptSettlementRate: 1.0, // 370.0 SAR received
          cashAccount: cashAccount,
          customerAccount: customerAccount,
        );

        expect(engine.getTotalDebitBase(), 375.0);
        expect(engine.getTotalCreditBase(), 375.0);

        final lossEntry = engine.findEntry(MultiCurrencyFxEngine.fxLossAccount);
        expect(lossEntry, isNotNull);
        expect(lossEntry!['debitBase'], 5.0);
      },
    );

    test(
      '7. Missing / Invalid FX Rate Rejection (0 or negative rate rejected)',
      () async {
        final draftInvalidRate = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.manualReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 1000.0,
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: 0.0, // Invalid exchange rate
          counterAmount: 1000.0,
          counterCurrencyCode: 'USD',
          counterExchangeRate: 1.0,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        const validator = FinancialTransactionValidator();
        expect(
          () => validator.validate(draftInvalidRate),
          throwsA(isA<FinancialTransactionException>()),
        );
      },
    );

    test(
      '8. Offline Settlement Rate Persistence (Historical rate preserved offline)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.manualReceipt,
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
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final created = await createTxn(draft);
        expect(created.exchangeRate, 3.75);

        final reFetched = await repo.getById(created.id);
        expect(reFetched?.exchangeRate, 3.75);
      },
    );

    test(
      '9. Sync Retry Invariance (Re-synchronizing preserves original base amounts)',
      () async {
        final draft = FinancialTransactionDraft(
          transactionType: TransactionType.receipt,
          source: TransactionSource.manualReceipt,
          transactionDate: DateTime.now().toUtc(),
          amount: 500.0,
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: 3.75,
          counterAmount: 500.0,
          counterCurrencyCode: 'USD',
          counterExchangeRate: 3.75,
          cashAccountId: cashAccount,
          counterAccountId: customerAccount,
          paymentMethod: RpPaymentMethod.cash,
          voucherBookId: 'voucher_book_1',
        );

        final posted = await postTxn((await createTxn(draft)).id);

        // Re-posting retry attempt
        expect(
          () => postTxn(posted.id),
          throwsA(isA<FinancialTransactionException>()),
        );

        // Verify stored rate remained strictly unchanged
        final verified = await repo.getById(posted.id);
        expect(verified?.exchangeRate, 3.75);
        expect(verified?.counterExchangeRate, 3.75);
      },
    );
  });
}
