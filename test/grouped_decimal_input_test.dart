import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/grouped_decimal_input.dart';

void main() {
  group('parseGroupedDecimal', () {
    test('parses plain and grouped values', () {
      expect(parseGroupedDecimal('1234.5'), 1234.5);
      expect(parseGroupedDecimal('1,234.56'), 1234.56);
      expect(parseGroupedDecimal('1,234,567'), 1234567);
      expect(parseGroupedDecimal('١٢٣٤.٥'), 1234.5);
    });

    test('treats trailing comma as decimal when short fraction', () {
      expect(parseGroupedDecimal('12,5'), 12.5);
    });
  });

  group('formatGroupedDecimal', () {
    test('inserts thousand separators', () {
      expect(
        formatGroupedDecimal(1234.5, trimTrailingZeros: true),
        '1,234.5',
      );
      expect(formatGroupedDecimal(1000000, decimalPlaces: 2), '1,000,000.00');
    });
  });

  group('GroupedDecimalInputFormatter', () {
    test('groups while typing', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 2);
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '12345.6',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(result.text, '12,345.6');
    });
  });
}
