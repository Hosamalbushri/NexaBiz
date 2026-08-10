import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';

void main() {
  group('normalizeDigitsToWestern', () {
    test('converts Eastern Arabic digits', () {
      expect(normalizeDigitsToWestern('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('converts Persian digits', () {
      expect(normalizeDigitsToWestern('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('leaves Western digits and letters unchanged', () {
      expect(normalizeDigitsToWestern('P0001 منتج'), 'P0001 منتج');
    });

    test('mixes scripts in one string', () {
      expect(normalizeDigitsToWestern('كود ١٢٣ و ۴۵'), 'كود 123 و 45');
    });
  });

  group('WesternDigitsInputFormatter', () {
    test('rewrites Arabic digits while keeping selection', () {
      const formatter = WesternDigitsInputFormatter();
      final next = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '١٢٣',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );

      expect(next.text, '123');
      expect(next.selection.baseOffset, 3);
    });
  });
}
