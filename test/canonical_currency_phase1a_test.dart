import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_currency_converter.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/services/financial_transaction_validator.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_currency_adapter.dart';
import 'package:stock_count/app/sales/accounting_sale_currency_adapter.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency_rate.dart';

class _FakeCurrencyRateRepo implements CurrencyRateRepository {
  @override
  Future<CurrencyRate?> getByCode(String code) async => null;

  @override
  Future<List<CurrencyRate>> getAll() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 1A Canonical Currency Enforcement Tests', () {
    test('1. Base currency identity returns 1.0 without requiring lookup', () {
      final rate = ExchangeRateValidator.validate(
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 0.0,
      );
      expect(rate, equals(1.0));
    });

    test('2. Valid foreign exchange rate passes validation', () {
      final rate = ExchangeRateValidator.validate(
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: 3.75,
      );
      expect(rate, equals(3.75));
    });

    test('3. Missing exchange rate for foreign currency throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: null,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('4. Zero exchange rate for foreign currency throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: 0.0,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('5. Negative exchange rate for foreign currency throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'EUR',
          baseCurrencyCode: 'SAR',
          exchangeRate: -1.2,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('6. NaN or Infinite exchange rate throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'EUR',
          baseCurrencyCode: 'SAR',
          exchangeRate: double.nan,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );

      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'EUR',
          baseCurrencyCode: 'SAR',
          exchangeRate: double.infinity,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('7. SaleCurrencyConverter converts accurately using canonical validator', () {
      const converter = SaleCurrencyConverter();
      final baseAmount = converter.saleToBase(100.0, 3.75);
      expect(baseAmount, equals(375.0));

      expect(
        () => converter.saleToBase(100.0, 0.0),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('8. FinancialTransactionValidator.normalizeFinancialTransactionDraft fails closed on zero foreign FX rate', () {
      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now(),
        amount: 100.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: 0.0, // Invalid!
        counterAmount: 100.0,
        counterCurrencyCode: 'USD',
        counterExchangeRate: 0.0,
        cashAccountId: 'acc1',
        counterAccountId: 'acc2',
        paymentMethod: RpPaymentMethod.cash,
        lines: [
          const FinancialTransactionLine(
            accountId: 'acc2',
            amount: 100.0,
            currencyCode: 'USD',
            exchangeRate: 0.0,
            lineOrder: 0,
          ),
        ],
      );

      expect(
        () => normalizeFinancialTransactionDraft(draft),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('9. AccountingRpCurrencyAdapter returns null when master currency has no active rate', () async {
      final adapter = AccountingRpCurrencyAdapter(
        baseCurrencyReader: () async => 'SAR',
        rates: _FakeCurrencyRateRepo(),
      );

      final result = await adapter.findByCode('EUR');
      expect(result, isNull);
    });

    test('10. AccountingSaleCurrencyAdapter returns null when master currency has no active rate', () async {
      final adapter = AccountingSaleCurrencyAdapter(
        baseCurrencyReader: () async => 'SAR',
        rates: _FakeCurrencyRateRepo(),
      );

      final result = await adapter.findByCode('GBP');
      expect(result, isNull);
    });
  });
}
