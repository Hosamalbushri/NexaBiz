import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Canonical Financial Rounding Policy Tests', () {
    test('1. Enforces mandatory rounding modes per operation type', () {
      expect(
        CanonicalRoundingPolicy.getRoundingMode(FinancialOperationType.currencyConversion),
        equals(FinancialRoundingMode.halfUp),
      );
      expect(
        CanonicalRoundingPolicy.getRoundingMode(FinancialOperationType.journalAllocation),
        equals(FinancialRoundingMode.halfEven),
      );
      expect(
        CanonicalRoundingPolicy.getRoundingMode(FinancialOperationType.financialCalculation),
        equals(FinancialRoundingMode.halfUp),
      );
      expect(
        CanonicalRoundingPolicy.getRoundingMode(FinancialOperationType.reportingDisplay),
        equals(FinancialRoundingMode.truncate),
      );
    });

    test('2. Deterministic execution: same input + same operation = same result across callers', () {
      final input = DecimalMoney.fromString('125.12500000', 'YER'); // .125

      // Half-Up for Currency Conversion to 2 decimals -> 125.13
      final convResult = CanonicalRoundingPolicy.round(
        money: input,
        decimalPlaces: 2,
        operationType: FinancialOperationType.currencyConversion,
      );
      expect(convResult.toFormattedString(2), equals('125.13'));

      // Half-Even for Journal Allocation to 2 decimals: .125 (odd integer 12 -> 2 is even, base is 12512)
      final allocResult = CanonicalRoundingPolicy.round(
        money: input,
        decimalPlaces: 2,
        operationType: FinancialOperationType.journalAllocation,
      );
      expect(allocResult.toFormattedString(2), equals('125.12'));

      // Truncate for Reporting Display to 2 decimals -> 125.12
      final displayResult = CanonicalRoundingPolicy.round(
        money: input,
        decimalPlaces: 2,
        operationType: FinancialOperationType.reportingDisplay,
      );
      expect(displayResult.toFormattedString(2), equals('125.12'));
    });
  });
}
