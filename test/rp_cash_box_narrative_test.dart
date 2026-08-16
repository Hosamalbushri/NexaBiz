import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_ledger_adapter.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/domain/entities/transaction_type.dart';

void main() {
  FinancialTransaction txn({
    String? description,
    String? counterAccountName,
    String? partyName,
    List<FinancialTransactionLine> lines = const [],
  }) {
    return FinancialTransaction(
      id: 1,
      uuid: 'txn-1',
      transactionNumber: 'R-1',
      transactionType: TransactionType.receipt,
      source: TransactionSource.manualReceipt,
      transactionDate: DateTime.utc(2024, 1, 1),
      amount: 100,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      counterAmount: 100,
      counterCurrencyCode: 'SAR',
      counterExchangeRate: 1,
      cashAccountId: 'cash-1',
      counterAccountId: 'counter-1',
      counterAccountName: counterAccountName,
      partyName: partyName,
      description: description,
      paymentMethod: RpPaymentMethod.cash,
      createdAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 1, 1),
      lines: lines,
    );
  }

  test('cash box narrative is account name - statement', () {
    final result = AccountingRpLedgerAdapter.cashBoxLineDescription(
      txn: txn(description: 'تحصيل إيجار'),
      allocations: const [
        FinancialTransactionLine(
          accountId: 'a1',
          accountName: 'إيرادات الإيجار',
          amount: 100,
          currencyCode: 'SAR',
          exchangeRate: 1,
          lineOrder: 0,
        ),
      ],
      fallbackNarrative: 'قبض R-1',
    );
    expect(result, 'إيرادات الإيجار - تحصيل إيجار');
  });

  test('falls back to party when account name missing', () {
    final result = AccountingRpLedgerAdapter.cashBoxLineDescription(
      txn: txn(description: 'دفعة', partyName: 'أحمد'),
      allocations: const [
        FinancialTransactionLine(
          accountId: 'a1',
          amount: 100,
          currencyCode: 'SAR',
          exchangeRate: 1,
          lineOrder: 0,
        ),
      ],
      fallbackNarrative: 'قبض R-1',
    );
    expect(result, 'أحمد - دفعة');
  });
}
