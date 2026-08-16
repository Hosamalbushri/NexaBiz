import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/grouped_decimal_input.dart';

void main() {
  group('parseGroupedDecimal', () {
    test('parses plain and grouped values', () {
      expect(parseGroupedDecimal('1234.5'), 1234.5);
      expect(parseGroupedDecimal('1,234.56'), 1234.56);
      expect(parseGroupedDecimal('1,234,567'), 1234567);
      expect(parseGroupedDecimal('10,000'), 10000);
      expect(parseGroupedDecimal('١,٢٥٠,٠٠٠.٧٥'), 1250000.75);
      expect(parseGroupedDecimal(''), isNull);
      expect(parseGroupedDecimal('-'), isNull);
      expect(parseGroupedDecimal('.'), isNull);
    });

    test('never treats comma as a fractional decimal', () {
      expect(parseGroupedDecimal('12,5'), 125);
      expect(parseGroupedDecimal('12,50'), 1250);
    });

    test('parses negatives when present in text', () {
      expect(parseGroupedDecimal('-1,250.5'), -1250.5);
    });
  });

  group('formatGroupedDecimal', () {
    test('inserts thousand separators for whole amounts', () {
      expect(formatGroupedDecimal(1000, decimalPlaces: 0), '1,000');
      expect(formatGroupedDecimal(10000, decimalPlaces: 0), '10,000');
      expect(formatGroupedDecimal(100000, decimalPlaces: 0), '100,000');
      expect(formatGroupedDecimal(1000000, decimalPlaces: 0), '1,000,000');
      expect(formatGroupedDecimal(1250000, decimalPlaces: 0), '1,250,000');
    });

    test('keeps fractional format when decimalPlaces > 0', () {
      expect(
        formatGroupedDecimal(1234.5, trimTrailingZeros: true),
        '1,234.5',
      );
      expect(formatGroupedDecimal(1000000, decimalPlaces: 2), '1,000,000.00');
      expect(formatGroupedDecimal(1250000.75, decimalPlaces: 2), '1,250,000.75');
      expect(formatGroupedDecimal(1250000, decimalPlaces: 3), '1,250,000.000');
    });

    test('emptyWhenZero', () {
      expect(formatGroupedDecimal(0, emptyWhenZero: true), '');
    });
  });

  group('GroupedDecimalInputFormatter caret', () {
    TextEditingValue apply(
      GroupedDecimalInputFormatter formatter, {
      required String oldText,
      required int oldOffset,
      required String newText,
      required int newOffset,
    }) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldOffset),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
        ),
      );
    }

    test('groups while typing at end', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 0);
      var value = TextEditingValue.empty;
      for (final digit in ['1', '0', '0', '0']) {
        final next = '${value.text}$digit';
        value = formatter.formatEditUpdate(
          value,
          TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          ),
        );
      }
      expect(value.text, '1,000');
      expect(value.selection.baseOffset, value.text.length);
    });

    test('backspace from end: 1,000 → 100', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 0);
      final result = apply(
        formatter,
        oldText: '1,000',
        oldOffset: 5,
        newText: '1,00',
        newOffset: 4,
      );
      expect(result.text, '100');
      expect(result.selection.baseOffset, 3);
    });

    test('backspace from end: 1,250,000 → 125,000', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 0);
      final result = apply(
        formatter,
        oldText: '1,250,000',
        oldOffset: 9,
        newText: '1,250,00',
        newOffset: 8,
      );
      expect(result.text, '125,000');
      expect(result.selection.baseOffset, 7);
    });

    test('insert in middle preserves logical caret', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 0);
      // "1,250,000" insert '9' after "1,2" → "1,295,000"
      final result = apply(
        formatter,
        oldText: '1,250,000',
        oldOffset: 3,
        newText: '1,2950,000',
        newOffset: 4,
      );
      expect(result.text, '12,950,000');
      expect(result.selection.baseOffset, 4);
    });

    test('groups while typing decimals when allowed', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 2);
      final result = apply(
        formatter,
        oldText: '',
        oldOffset: 0,
        newText: '12345.6',
        newOffset: 7,
      );
      expect(result.text, '12,345.6');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('rejects excess fraction digits', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 2);
      final result = apply(
        formatter,
        oldText: '1.23',
        oldOffset: 4,
        newText: '1.234',
        newOffset: 5,
      );
      expect(result.text, '1.23');
    });

    test('allows negative when configured', () {
      const formatter = GroupedDecimalInputFormatter(
        decimalPlaces: 2,
        allowNegative: true,
      );
      final result = apply(
        formatter,
        oldText: '',
        oldOffset: 0,
        newText: '-1250.5',
        newOffset: 7,
      );
      expect(result.text, '-1,250.5');
    });

    test('paste of grouped value', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 2);
      final result = apply(
        formatter,
        oldText: '',
        oldOffset: 0,
        newText: '1,250,000.75',
        newOffset: 12,
      );
      expect(result.text, '1,250,000.75');
      expect(parseGroupedDecimal(result.text), 1250000.75);
    });

    test('selection replace', () {
      const formatter = GroupedDecimalInputFormatter(decimalPlaces: 0);
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1,000',
          selection: TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        const TextEditingValue(
          text: '25',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '25');
    });
  });
}
