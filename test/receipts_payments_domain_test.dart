import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/domain/models/financial_transaction_exception.dart';
import 'package:stock_count/modules/receipts_payments/domain/services/financial_transaction_validator.dart';
import 'package:stock_count/modules/receipts_payments/domain/services/financial_transaction_workflow.dart';

void main() {
  const validator = FinancialTransactionValidator();
  const workflow = FinancialTransactionWorkflow();

  FinancialTransactionDraft draft({
    TransactionSource source = TransactionSource.manualReceipt,
    double amount = 100,
    String cash = 'cash-1',
    String counter = 'counter-1',
    String? customerId,
  }) {
    return FinancialTransactionDraft(
      transactionType: source.defaultTransactionType,
      source: source,
      transactionDate: DateTime.utc(2026, 8, 1),
      amount: amount,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: amount,
      counterCurrencyCode: 'SAR',
      counterExchangeRate: 1,
      cashAccountId: cash,
      counterAccountId: counter,
      paymentMethod: RpPaymentMethod.cash,
      customerId: customerId,
      voucherBookId: 'book-1',
    );
  }

  group('FinancialTransactionValidator', () {
    test('accepts valid manual receipt', () {
      expect(() => validator.validate(draft()), returnsNormally);
    });

    test('rejects non-positive amount', () {
      expect(
        () => validator.validate(draft(amount: 0)),
        throwsA(
          isA<FinancialTransactionException>().having(
            (e) => e.code,
            'code',
            FinancialTransactionException.amountMustBePositive,
          ),
        ),
      );
    });

    test('rejects same cash and counter accounts', () {
      expect(
        () => validator.validate(draft(cash: 'a', counter: 'a')),
        throwsA(
          isA<FinancialTransactionException>().having(
            (e) => e.code,
            'code',
            FinancialTransactionException.sameAccounts,
          ),
        ),
      );
    });

    test('requires customer for customerReceipt source', () {
      expect(
        () => validator.validate(
          draft(source: TransactionSource.customerReceipt),
        ),
        throwsA(
          isA<FinancialTransactionException>().having(
            (e) => e.code,
            'code',
            FinancialTransactionException.customerRequired,
          ),
        ),
      );
      expect(
        () => validator.validate(
          draft(
            source: TransactionSource.customerReceipt,
            customerId: 'cust-1',
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('FinancialTransactionWorkflow', () {
    FinancialTransaction txn({
      TransactionStatus status = TransactionStatus.unposted,
      DateTime? cancelledAt,
    }) {
      return FinancialTransaction(
        id: 1,
        uuid: '00000000-0000-4000-8000-000000000001',
        transactionNumber: '1',
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2026, 8, 1),
        amount: 50,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1,
        counterAmount: 50,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1,
        cashAccountId: 'cash',
        counterAccountId: 'counter',
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: status,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 1),
        cancelledAt: cancelledAt,
      );
    }

    test('allows edit/post on unposted', () {
      expect(() => workflow.assertCanEdit(txn()), returnsNormally);
      expect(() => workflow.assertCanPost(txn()), returnsNormally);
    });

    test('blocks edit/post on posted', () {
      final posted = txn(status: TransactionStatus.posted);
      expect(
        () => workflow.assertCanEdit(posted),
        throwsA(isA<FinancialTransactionException>()),
      );
      expect(
        () => workflow.assertCanPost(posted),
        throwsA(isA<FinancialTransactionException>()),
      );
      expect(() => workflow.assertCanCancel(posted), returnsNormally);
    });

    test('blocks cancel when already cancelled', () {
      expect(
        () => workflow.assertCanCancel(
          txn(cancelledAt: DateTime.utc(2026, 8, 2)),
        ),
        throwsA(
          isA<FinancialTransactionException>().having(
            (e) => e.code,
            'code',
            FinancialTransactionException.alreadyCancelled,
          ),
        ),
      );
    });
  });
}
