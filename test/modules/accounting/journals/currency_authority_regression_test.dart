import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_base_amount_resolver.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';

void main() {
  group('Currency Authority Regression Tests', () {
    test('Calculates base currency amount via foreignAmount * rateToBase (SAR -> YER)', () {
      const foreignAmount = 20.0; // 20 SAR
      const rateToBase = 140.0; // 140 YER / SAR

      final baseAmount = JournalBaseAmountResolver.calculateBaseAmount(
        foreignAmount: foreignAmount,
        rateToBase: rateToBase,
      );

      // 20 SAR * 140 YER/SAR = 2800 YER
      expect(baseAmount, equals(2800.0));
      // Prove that no secondary or double conversion (e.g. 2800 * 140 = 392,000) occurred
      expect(baseAmount, isNot(equals(392000.0)));
    });

    test('Ensures penny balance equality on rounded debit and credit base totals', () {
      final line1Base = JournalMoney.round(10.004 * 140.0); // 1400.56
      final line2Base = JournalMoney.round(9.996 * 140.0);  // 1399.44
      final totalBase = line1Base + line2Base;

      expect(totalBase, equals(2800.0));
    });
  });
}
