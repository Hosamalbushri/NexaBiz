import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/errors/currency_exception.dart';
import 'package:stock_count/core/utils/decimal_money.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_balance_validator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_base_amount_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/exchange_rate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/exchange_rate_engine.dart';

void main() {
  group('CURRENCY-06 — Multi-Currency Journal Engine', () {
    late ExchangeRateEngine exchangeEngine;

    setUp(() {
      exchangeEngine = ExchangeRateEngine();
      // Seed standard test exchange rates
      exchangeEngine.registerRates([
        ExchangeRate(
          id: 'sar_yer_jan',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(140.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
        ),
        ExchangeRate(
          id: 'usd_yer_jan',
          fromCurrency: 'USD',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(375.0),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
        ),
      ]);
    });

    test('1. Single-currency journal (balancing transaction & base amounts)', () async {
      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_cash',
          debit: 1000.0,
          credit: 0.0,
          currencyCode: 'YER',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_capital',
          debit: 0.0,
          credit: 1000.0,
          currencyCode: 'YER',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.utc(2026, 1, 15),
        baseCurrencyCode: 'YER',
        lines: rawLines,
      );

      // Validate base resolution
      expect(resolved[0].baseDebit, equals(1000.0));
      expect(resolved[0].exchangeRateToBase, equals(1.0));
      expect(resolved[1].baseCredit, equals(1000.0));
      expect(resolved[1].exchangeRateToBase, equals(1.0));

      // Assert journal balancing
      expect(
        () => JournalBalanceValidator.validateAndAssert(lines: resolved),
        returnsNormally,
      );
    });

    test('2. Mixed-currency journal (debit YER, credit SAR balancing in YER)', () async {
      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      // Dr Inventory: 14,000 YER
      // Cr Supplier: 100 SAR (Rate 140 YER/SAR -> 14,000 YER base)
      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_inventory',
          debit: 14000.0,
          credit: 0.0,
          currencyCode: 'YER',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_supplier_sar',
          debit: 0.0,
          credit: 100.0,
          currencyCode: 'SAR',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.utc(2026, 1, 15),
        baseCurrencyCode: 'YER',
        lines: rawLines,
      );

      expect(resolved[0].currencyCode, equals('YER'));
      expect(resolved[0].baseDebit, equals(14000.0));

      expect(resolved[1].currencyCode, equals('SAR'));
      expect(resolved[1].credit, equals(100.0));
      expect(resolved[1].exchangeRateToBase, equals(140.0));
      expect(resolved[1].baseCredit, equals(14000.0));

      // Raw amounts differ (14,000 vs 100), but functional equivalents balance (14,000 == 14,000)
      expect(
        () => JournalBalanceValidator.validateAndAssert(
          lines: resolved,
          allowUnbalancedMultiCurrency: true,
        ),
        returnsNormally,
      );
    });

    test('3. Foreign supplier purchase scenario', () async {
      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      // Purchase from Saudi supplier for 500 SAR @ 140 YER/SAR = 70,000 YER
      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_inventory',
          debit: 70000.0,
          credit: 0.0,
          currencyCode: 'YER',
          lineDescription: 'Inbound inventory valuation in base YER',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_saudi_supplier',
          debit: 0.0,
          credit: 500.0,
          currencyCode: 'SAR',
          lineDescription: 'AP Saudi Supplier in SAR',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.utc(2026, 2, 1),
        baseCurrencyCode: 'YER',
        lines: rawLines,
      );

      // Verify line details preserved
      expect(resolved[1].credit, equals(500.0));
      expect(resolved[1].currencyCode, equals('SAR'));
      expect(resolved[1].exchangeRateToBase, equals(140.0));
      expect(resolved[1].baseCredit, equals(70000.0));

      JournalBalanceValidator.validateAndAssert(lines: resolved);
    });

    test('4. Foreign customer sale scenario', () async {
      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      // Sale to US customer for 200 USD @ 375 YER/USD = 75,000 YER
      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_us_customer',
          debit: 200.0,
          credit: 0.0,
          currencyCode: 'USD',
          lineDescription: 'AR US Customer in USD',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_sales_revenue',
          debit: 0.0,
          credit: 75000.0,
          currencyCode: 'YER',
          lineDescription: 'Sales revenue in functional currency YER',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.utc(2026, 2, 10),
        baseCurrencyCode: 'YER',
        lines: rawLines,
      );

      expect(resolved[0].debit, equals(200.0));
      expect(resolved[0].currencyCode, equals('USD'));
      expect(resolved[0].exchangeRateToBase, equals(375.0));
      expect(resolved[0].baseDebit, equals(75000.0));

      expect(resolved[1].baseCredit, equals(75000.0));

      JournalBalanceValidator.validateAndAssert(lines: resolved);
    });

    test('5. Exchange-rate conversion using ExchangeRateEngine', () async {
      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_sar_box',
          debit: 250.0,
          credit: 0.0,
          currencyCode: 'SAR',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_equity',
          debit: 0.0,
          credit: 35000.0,
          currencyCode: 'YER',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.utc(2026, 1, 20),
        baseCurrencyCode: 'YER',
        lines: rawLines,
      );

      // 250 SAR * 140 = 35,000 YER
      expect(resolved[0].baseDebit, equals(35000.0));
      expect(resolved[1].baseCredit, equals(35000.0));
    });

    test('6. Rounding and penny balancing on multi-line conversion', () async {
      exchangeEngine.registerRate(
        ExchangeRate(
          id: 'rate_fractional',
          fromCurrency: 'AED',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(142.333333),
          effectiveDate: DateTime.utc(2026, 1, 1),
          precision: 2,
        ),
      );

      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_aed_box',
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'AED',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_revenue',
          debit: 0.0,
          credit: 14233.33,
          currencyCode: 'YER',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.utc(2026, 1, 25),
        baseCurrencyCode: 'YER',
        lines: rawLines,
      );

      // Penny balancing guarantees base Debit == base Credit exact match
      expect(resolved[0].baseDebit, equals(resolved[1].baseCredit));
      JournalBalanceValidator.validateAndAssert(lines: resolved);
    });

    test('7. Imbalance rejection (functional base debits != base credits)', () async {
      // Line 1: Dr Inventory 14,000 YER
      // Line 2: Cr Supplier 100 SAR with explicit wrong base credit 15,000 YER
      final lines = [
        const JournalLineDraft(
          accountUuid: 'acc_inventory',
          debit: 14000.0,
          credit: 0.0,
          currencyCode: 'YER',
          baseDebit: 14000.0,
        ),
        const JournalLineDraft(
          accountUuid: 'acc_supplier',
          debit: 0.0,
          credit: 100.0,
          currencyCode: 'SAR',
          baseCredit: 15000.0, // Imbalanced!
        ),
      ];

      expect(
        () => JournalBalanceValidator.validateAndAssert(
          lines: lines,
          allowUnbalancedMultiCurrency: true,
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            equals(JournalException.unbalanced),
          ),
        ),
      );
    });

    test('8. Missing exchange rate rejection (throws ExchangeRateNotFoundException)', () async {
      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      // Line with EUR currency (not registered)
      final rawLines = [
        const JournalLineDraft(
          accountUuid: 'acc_eur_box',
          debit: 100.0,
          credit: 0.0,
          currencyCode: 'EUR',
        ),
        const JournalLineDraft(
          accountUuid: 'acc_revenue',
          debit: 0.0,
          credit: 40000.0,
          currencyCode: 'YER',
        ),
      ];

      expect(
        () async => await resolver.resolve(
          entryDate: DateTime.utc(2026, 1, 20),
          baseCurrencyCode: 'YER',
          lines: rawLines,
        ),
        throwsA(isA<ExchangeRateNotFoundException>()),
      );
    });

    test('9. Historical rate preservation on entry date', () async {
      // Rate on Jan 1 = 140 YER/SAR
      // Rate on Jun 1 = 145 YER/SAR
      exchangeEngine.registerRate(
        ExchangeRate(
          id: 'sar_yer_jun',
          fromCurrency: 'SAR',
          toCurrency: 'YER',
          rate: DecimalRate.fromDouble(145.0),
          effectiveDate: DateTime.utc(2026, 6, 1),
        ),
      );

      final resolver = JournalBaseAmountResolver.fromEngine(exchangeEngine);

      // Entry dated Feb 1 -> must use Jan 1 rate (140)
      final resolvedFeb = await resolver.resolve(
        entryDate: DateTime.utc(2026, 2, 1),
        baseCurrencyCode: 'YER',
        lines: [
          const JournalLineDraft(
            accountUuid: 'acc_sar_box',
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          const JournalLineDraft(
            accountUuid: 'acc_capital',
            debit: 0.0,
            credit: 14000.0,
            currencyCode: 'YER',
          ),
        ],
      );

      expect(resolvedFeb[0].exchangeRateToBase, equals(140.0));
      expect(resolvedFeb[0].baseDebit, equals(14000.0));

      // Entry dated Jun 10 -> must use Jun 1 rate (145)
      final resolvedJun = await resolver.resolve(
        entryDate: DateTime.utc(2026, 6, 10),
        baseCurrencyCode: 'YER',
        lines: [
          const JournalLineDraft(
            accountUuid: 'acc_sar_box',
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          const JournalLineDraft(
            accountUuid: 'acc_capital',
            debit: 0.0,
            credit: 14500.0,
            currencyCode: 'YER',
          ),
        ],
      );

      expect(resolvedJun[0].exchangeRateToBase, equals(145.0));
      expect(resolvedJun[0].baseDebit, equals(14500.0));
    });
  });
}
