import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/core/utils/journal_money.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_base_amount_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency_rate.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_currency_converter.dart';

class _FakeCurrencyRateRepository implements CurrencyRateRepository {
  final Map<String, double> rates = {};

  @override
  Future<CurrencyRate?> getByCode(String code) async {
    final r = rates[code.trim().toUpperCase()];
    if (r == null) return null;
    return CurrencyRate(
      id: 1,
      uuid: 'rate-$code',
      currencyCode: code,
      rateToBase: r,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<double?> getRateOn(String code, DateTime date) async {
    return rates[code.trim().toUpperCase()];
  }

  @override
  Future<void> deleteByCode(String code) async {
    rates.remove(code.trim().toUpperCase());
  }

  @override
  Future<List<CurrencyRate>> getAll() async => [];

  @override
  Stream<List<CurrencyRate>> watchAll() => Stream.value([]);

  @override
  Future<List<CurrencyRateHistoryEntry>> listHistory(
    String currencyCode, {
    int limit = 30,
  }) async =>
      [];

  @override
  Future<CurrencyRate> upsert(CurrencyRateDraft draft) async {
    rates[draft.currencyCode.trim().toUpperCase()] = draft.rateToBase;
    return CurrencyRate(
      id: 1,
      uuid: 'rate-${draft.currencyCode}',
      currencyCode: draft.currencyCode,
      rateToBase: draft.rateToBase,
      updatedAt: DateTime.now(),
    );
  }

  void setRate(String code, double rate) {
    rates[code.trim().toUpperCase()] = rate;
  }
}

void main() {
  group('Task 5 — Hardening Money, Currency, and Exchange-Rate Accounting', () {
    late _FakeCurrencyRateRepository rateRepo;
    late JournalBaseAmountResolver baseAmountResolver;

    setUp(() {
      rateRepo = _FakeCurrencyRateRepository();
      baseAmountResolver = JournalBaseAmountResolver(rateRepo);
    });

    test('1. Zero exchange rate foreign currency transaction throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: 0.0,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('2. Negative exchange rate foreign currency transaction throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: -3.75,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('3. NaN exchange rate foreign currency transaction throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: double.nan,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('4. Infinity exchange rate foreign currency transaction throws InvalidExchangeRateException', () {
      expect(
        () => ExchangeRateValidator.validate(
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: double.infinity,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('5. Valid foreign currency exchange rate processes correctly', () {
      final rate = ExchangeRateValidator.validate(
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: 3.75,
      );
      expect(rate, 3.75);
    });

    test('6. Base currency transaction normalizes exchange rate to 1.0', () {
      final rate = ExchangeRateValidator.validate(
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 0.0, // base currency normalized to 1.0 regardless of exchangeRate input
      );
      expect(rate, 1.0);
    });

    test('7. High precision FX rate rounding preserves 6-decimal precision', () {
      const highPrecisionRate = 3.750123;
      final rounded = JournalMoney.roundFxRate(highPrecisionRate);
      expect(rounded, 3.750123);

      expect(
        () => JournalMoney.roundFxRate(0.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('8. Tax rounding determinism ensures exact cent rounding', () {
      const subtotal = 100.333;
      const taxRate = 15.0; // 15%
      final rawTax = subtotal * (taxRate / 100); // 15.04995
      final roundedTax = JournalMoney.round(rawTax);
      expect(roundedTax, 15.05);
    });

    test('9. Discount rounding determinism ensures exact cent rounding', () {
      const originalAmount = 250.777;
      const discountPercentage = 10.0;
      final rawDiscount = originalAmount * (discountPercentage / 100); // 25.0777
      final roundedDiscount = JournalMoney.round(rawDiscount);
      expect(roundedDiscount, 25.08);
    });

    test('10. Debit/Credit equality invariant: balancing minor unit disparity in multi-line foreign journal', () async {
      final lines = [
        JournalLineDraft(
          accountUuid: 'acc-debit-1',
          debit: 33.33,
          credit: 0,
          currencyCode: 'USD',
          exchangeRateToBase: 3.75,
        ),
        JournalLineDraft(
          accountUuid: 'acc-debit-2',
          debit: 33.33,
          credit: 0,
          currencyCode: 'USD',
          exchangeRateToBase: 3.75,
        ),
        JournalLineDraft(
          accountUuid: 'acc-credit-1',
          debit: 0,
          credit: 66.66,
          currencyCode: 'USD',
          exchangeRateToBase: 3.75,
        ),
      ];

      final resolved = await baseAmountResolver.resolve(
        entryDate: DateTime.now(),
        baseCurrencyCode: 'SAR',
        lines: lines,
      );

      var totalBaseDebit = 0.0;
      var totalBaseCredit = 0.0;
      for (final line in resolved) {
        totalBaseDebit += line.baseDebit ?? 0;
        totalBaseCredit += line.baseCredit ?? 0;
      }

      expect(
        JournalMoney.toCents(totalBaseDebit),
        JournalMoney.toCents(totalBaseCredit),
        reason: 'Base Debit sum must equal Base Credit sum exactly',
      );
    });

    test('11. Foreign currency journal resolution fails closed when exchange rate unavailable', () async {
      final lines = [
        JournalLineDraft(
          accountUuid: 'acc-1',
          debit: 100,
          credit: 0,
          currencyCode: 'EUR', // Unmapped currency, no rate provided
          exchangeRateToBase: 0.0,
        ),
      ];

      expect(
        () => baseAmountResolver.resolve(
          entryDate: DateTime.now(),
          baseCurrencyCode: 'SAR',
          lines: lines,
        ),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });

    test('12. SaleCurrencyConverter rejects non-positive or invalid exchange rate', () {
      const converter = SaleCurrencyConverter();
      expect(
        () => converter.baseToSale(100.0, 0.0),
        throwsA(isA<InvalidExchangeRateException>()),
      );
      expect(
        () => converter.saleToBase(100.0, -1.0),
        throwsA(isA<InvalidExchangeRateException>()),
      );
    });
  });
}
