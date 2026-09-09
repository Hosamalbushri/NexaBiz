import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/core/utils/decimal_money.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/exchange_rate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/exchange_rate_engine.dart';

void main() {
  group('CURRENCY-05 — Exchange Rate Engine', () {
    late ExchangeRateEngine engine;

    setUp(() {
      engine = ExchangeRateEngine();
    });

    test('1. Direct rate calculation (100 SAR x 140 YER/SAR = 14,000 YER)', () async {
      final rateDate = DateTime.utc(2026, 1, 1);
      engine.registerRate(
        ExchangeRate(
          id: 'rate_sar_yer_1',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: rateDate,
          precision: 2,
          source: 'manual',
          isActive: true,
        ),
      );

      final result = await engine.convert(
        amount: DecimalMoney.fromDouble(100.0),
        fromCurrency: 'SAR',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 1, 15),
      );

      expect(result.convertedAmount.toDouble(), equals(14000.0));
      expect(result.rate.toDouble(), equals(140.0));
      expect(result.fromCurrency, equals('SAR'));
      expect(result.toCurrency, equals('YER'));
    });

    test('2. Rate updates and historical rate preservation (140 vs 145)', () async {
      // Historical rate as of Jan 1
      engine.registerRate(
        ExchangeRate(
          id: 'rate_jan',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
          isActive: true,
        ),
      );

      // New rate as of Jun 1
      engine.registerRate(
        ExchangeRate(
          id: 'rate_jun',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(145.0),
          effectiveDate: DateTime.utc(2026, 6, 1),
          precision: 2,
          isActive: true,
        ),
      );

      // Query historical date (May 1) -> must use 140 YER/SAR -> 14,000 YER
      final resMay = await engine.convert(
        amount: DecimalMoney.fromDouble(100.0),
        fromCurrency: 'SAR',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 5, 1),
      );
      expect(resMay.convertedAmount.toDouble(), equals(14000.0));

      // Query current date (Jun 15) -> must use 145 YER/SAR -> 14,500 YER
      final resJun = await engine.convert(
        amount: DecimalMoney.fromDouble(100.0),
        fromCurrency: 'SAR',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 6, 15),
      );
      expect(resJun.convertedAmount.toDouble(), equals(14500.0));
    });

    test('3. Deterministic inverse rate calculation (14,000 YER -> SAR)', () async {
      engine.registerRate(
        ExchangeRate(
          id: 'rate_sar_yer',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
          isActive: true,
        ),
      );

      // Converting YER -> SAR using inverse of SAR -> YER (1/140)
      final result = await engine.convert(
        amount: DecimalMoney.fromDouble(14000.0),
        fromCurrency: 'YER',
        toCurrency: 'SAR',
        effectiveDate: DateTime.utc(2026, 2, 1),
        targetPrecision: 2,
      );

      expect(result.convertedAmount.toDouble(), equals(100.0));
    });

    test('4. Triangulated cross-rate conversion (USD -> SAR -> YER)', () async {
      // 1 USD = 3.75 SAR
      engine.registerRate(
        ExchangeRate(
          id: 'rate_usd_sar',
          fromCurrency: 'USD',
          toCurrency: 'SAR',
          rate: DecimalRate.fromDouble(3.75),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
          isActive: true,
        ),
      );

      // 1 SAR = 140 YER
      engine.registerRate(
        ExchangeRate(
          id: 'rate_sar_yer',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
          isActive: true,
        ),
      );

      // 100 USD -> YER via SAR = 100 * 3.75 * 140 = 52,500 YER
      final result = await engine.convert(
        amount: DecimalMoney.fromDouble(100.0),
        fromCurrency: 'USD',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 3, 1),
      );

      expect(result.convertedAmount.toDouble(), equals(52500.0));
    });

    test('5. Missing rate protection (throws ExchangeRateNotFoundException, ZERO fallback)', () async {
      // No rate registered for EUR -> YER
      expect(
        () async => await engine.getRate(
          fromCurrency: 'EUR',
          toCurrency: 'YER',
          effectiveDate: DateTime.utc(2026, 5, 1),
        ),
        throwsA(isA<ExchangeRateNotFoundException>()),
      );
    });

    test('6. Expired and inactive rate handling', () async {
      // Inactive rate
      engine.registerRate(
        ExchangeRate(
          id: 'inactive_rate',
          fromCurrency: 'EUR',
          toCurrency: 'SAR',
          rate: DecimalRate.fromDouble(4.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          isActive: false,
        ),
      );

      expect(
        () async => await engine.getRate(
          fromCurrency: 'EUR',
          toCurrency: 'SAR',
          effectiveDate: DateTime.utc(2026, 2, 1),
        ),
        throwsA(isA<ExchangeRateExpiredException>()),
      );

      // Active rate but expired maxAge
      engine.registerRate(
        ExchangeRate(
          id: 'old_rate',
          fromCurrency: 'GBP',
          toCurrency: 'SAR',
          rate: DecimalRate.fromDouble(4.8),
          effectiveDate: DateTime.utc(2025, 1, 1),
          isActive: true,
        ),
      );

      expect(
        () async => await engine.getRate(
          fromCurrency: 'GBP',
          toCurrency: 'SAR',
          effectiveDate: DateTime.utc(2026, 6, 1),
          maxAge: const Duration(days: 90),
        ),
        throwsA(isA<ExchangeRateExpiredException>()),
      );
    });

    test('7. Effective date lookup precision', () async {
      engine.registerRates([
        ExchangeRate(
          id: 'r_jan',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(135.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
        ),
        ExchangeRate(
          id: 'r_mar',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: DateTime.utc(2026, 3, 1),
        ),
        ExchangeRate(
          id: 'r_jun',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(145.0),
          effectiveDate: DateTime.utc(2026, 6, 1),
        ),
      ]);

      // Feb 15 should pick Jan 1 rate (135)
      final rateFeb = await engine.getRate(
        fromCurrency: 'SAR',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 2, 15),
      );
      expect(rateFeb.rateValue, equals(135.0));

      // Apr 10 should pick Mar 1 rate (140)
      final rateApr = await engine.getRate(
        fromCurrency: 'SAR',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 4, 10),
      );
      expect(rateApr.rateValue, equals(140.0));
    });

    test('8. Precision and fixed rounding modes', () async {
      engine.registerRate(
        ExchangeRate(
          id: 'rate_round',
          fromCurrency: 'USD',
          toCurrency: 'SAR',
          rate: DecimalRate.fromDouble(3.754),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
        ),
      );

      final result = await engine.convert(
        amount: DecimalMoney.fromDouble(100.0),
        fromCurrency: 'USD',
        toCurrency: 'SAR',
        effectiveDate: DateTime.utc(2026, 1, 2),
        targetPrecision: 2,
        roundingMode: FixedRoundingMode.halfUp,
      );

      // 100 * 3.754 = 375.40
      expect(result.convertedAmount.toDouble(), equals(375.40));
    });

    test('9. Transaction reproducibility via ExchangeRateSnapshot', () async {
      engine.registerRate(
        ExchangeRate(
          id: 'rate_v1',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          version: 1,
        ),
      );

      final res1 = await engine.convert(
        amount: DecimalMoney.fromDouble(100.0),
        fromCurrency: 'SAR',
        toCurrency: 'YER',
        effectiveDate: DateTime.utc(2026, 1, 10),
      );

      final snapshot = res1.snapshot;
      expect(snapshot.rateValue, equals(140.0));

      // System rate updates to 150 later
      engine.registerRate(
        ExchangeRate(
          id: 'rate_v2',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(150.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          version: 2,
        ),
      );

      // Re-running transaction calculation using the historical snapshot MUST yield 14,000 YER
      final replayedAmount = snapshot.convert(DecimalMoney.fromDouble(100.0));
      expect(replayedAmount.toDouble(), equals(14000.0));
    });

    test('10. Zero floating-point accounting (DecimalMoney exactness)', () {
      final m1 = DecimalMoney.fromDouble(0.1);
      final m2 = DecimalMoney.fromDouble(0.2);
      final sum = m1.add(m2);

      expect(sum.toDouble(), equals(0.3));
      expect(sum.toString(), equals('0.3000'));
    });
  });
}
