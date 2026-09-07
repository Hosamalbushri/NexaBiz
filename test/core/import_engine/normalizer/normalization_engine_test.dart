import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 06 — Universal Import Engine Normalization Engine Tests', () {
    const engine = NormalizationEngine();

    test('1. NullNormalizer detects English and Arabic null placeholders', () {
      final res1 = NullNormalizer.normalize(null);
      expect(res1.isNull, isTrue);
      expect(res1.originalValue, isNull);

      final res2 = NullNormalizer.normalize('  N/A  ');
      expect(res2.isNull, isTrue);
      expect(res2.originalValue, equals('  N/A  '));

      final res3 = NullNormalizer.normalize('لا يوجد');
      expect(res3.isNull, isTrue);
      expect(res3.originalValue, equals('لا يوجد'));
    });

    test(
      '2. StringNormalizer strips BOM and zero-width spaces while preserving text & casing',
      () {
        const raw = '\uFEFF\u200B  شاشة حاسوب 4K  ';
        final res = StringNormalizer.normalize(raw);

        expect(res.originalValue, equals(raw));
        expect(res.normalizedValue, equals('شاشة حاسوب 4K'));
        expect(res.isNormalized, isTrue);
        expect(res.isNull, isFalse);
      },
    );

    test(
      '3. DecimalNormalizer handles multiple decimal & Eastern Arabic formats (1,250.50, 1250.50, 1250,50, ١٢٥٠٫٥٠)',
      () {
        // 1,250.50 (comma thousands, dot decimal)
        final res1 = DecimalNormalizer.normalize('1,250.50');
        expect(res1.originalValue, equals('1,250.50'));
        expect(res1.normalizedValue, equals(1250.50));

        // 1250,50 (comma decimal)
        final res2 = DecimalNormalizer.normalize('1250,50');
        expect(res2.originalValue, equals('1250,50'));
        expect(res2.normalizedValue, equals(1250.50));

        // ١٢٥٠٫٥٠ (Eastern Arabic digits & Arabic decimal separator)
        final res3 = DecimalNormalizer.normalize('١٢٥٠٫٥٠');
        expect(res3.originalValue, equals('١٢٥٠٫٥٠'));
        expect(res3.normalizedValue, equals(1250.50));
        expect(
          res3.normalizationMetadata['easternArabicDigitsConverted'],
          isTrue,
        );
      },
    );

    test(
      '4. NumberNormalizer converts Eastern Arabic digits and parses integers',
      () {
        final res = NumberNormalizer.normalize('١٢٥٠');
        expect(res.originalValue, equals('١٢٥٠'));
        expect(res.normalizedValue, equals(1250));
        expect(
          res.normalizationMetadata['easternArabicDigitsConverted'],
          isTrue,
        );
      },
    );

    test(
      '5. BooleanNormalizer parses English and Arabic truthy/falsy representations',
      () {
        // Truthy
        expect(
          BooleanNormalizer.normalize('yes').normalizedValue,
          equals(true),
        );
        expect(
          BooleanNormalizer.normalize('نعم').normalizedValue,
          equals(true),
        );
        expect(
          BooleanNormalizer.normalize('مفعل').normalizedValue,
          equals(true),
        );

        // Falsy
        expect(
          BooleanNormalizer.normalize('no').normalizedValue,
          equals(false),
        );
        expect(
          BooleanNormalizer.normalize('لا').normalizedValue,
          equals(false),
        );
        expect(
          BooleanNormalizer.normalize('غير مفعل').normalizedValue,
          equals(false),
        );
      },
    );

    test(
      '6. DateNormalizer parses ISO-8601, YYYY/MM/DD, and DD/MM/YYYY dates',
      () {
        final d1 = DateNormalizer.normalize('2026-09-03');
        expect(d1.normalizedValue, equals(DateTime(2026, 9, 3)));

        final d2 = DateNormalizer.normalize('03/09/2026');
        expect(d2.normalizedValue, equals(DateTime(2026, 9, 3)));

        final d3 = DateNormalizer.normalize('٢٠٢٦-٠٩-٠٣');
        expect(d3.normalizedValue, equals(DateTime(2026, 9, 3)));
      },
    );

    test(
      '7. CodeNormalizer standardizes SKUs and codes (trims, converts digits, uppercases)',
      () {
        final res = CodeNormalizer.normalize('\uFEFF p-٠٠١ ');
        expect(res.originalValue, equals('\uFEFF p-٠٠١ '));
        expect(res.normalizedValue, equals('P-001'));
        expect(res.isNormalized, isTrue);
      },
    );

    test(
      '8. Malformed inputs preserve originalValue and report isMalformed without throwing',
      () {
        final res = DecimalNormalizer.normalize('invalid_decimal_abc');
        expect(res.originalValue, equals('invalid_decimal_abc'));
        expect(res.normalizedValue, isNull);
        expect(res.isMalformed, isTrue);
        expect(
          res.normalizationMetadata['error'],
          equals('unparsable_decimal'),
        );
      },
    );

    test('9. NormalizationEngine routes data types correctly', () {
      final res = engine.normalizeForDataType('1250,50', ImportDataType.number);
      expect(res.normalizedValue, equals(1250.50));
    });
  });
}
