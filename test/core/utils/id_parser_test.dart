import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_parser.dart';

void main() {
  group('IdParser.extractNumericId', () {
    test('returns int directly when positive', () {
      expect(IdParser.extractNumericId(577), equals(577));
      expect(IdParser.extractNumericId(1), equals(1));
    });

    test('returns null for negative or zero integer', () {
      expect(IdParser.extractNumericId(0), isNull);
      expect(IdParser.extractNumericId(-10), isNull);
    });

    test('parses pure numeric string', () {
      expect(IdParser.extractNumericId('577'), equals(577));
      expect(IdParser.extractNumericId('   42   '), equals(42));
    });

    test('parses IRI paths cleanly', () {
      expect(IdParser.extractNumericId('/api/orders/577'), equals(577));
      expect(IdParser.extractNumericId('/api/v1/customers/1029'), equals(1029));
      expect(IdParser.extractNumericId('/api/v1/orders/577/'), equals(577));
    });

    test('parses full URLs with query parameters and fragments', () {
      expect(
        IdParser.extractNumericId('https://example.com/api/orders/577?tab=items'),
        equals(577),
      );
      expect(
        IdParser.extractNumericId('http://localhost:8000/api/v1/invoices/987#section'),
        equals(987),
      );
    });

    test('parses encoded URIs', () {
      expect(IdParser.extractNumericId('%2Fapi%2Forders%2F456'), equals(456));
    });

    test('returns null for null, empty, or non-numeric inputs', () {
      expect(IdParser.extractNumericId(null), isNull);
      expect(IdParser.extractNumericId(''), isNull);
      expect(IdParser.extractNumericId('   '), isNull);
      expect(IdParser.extractNumericId('invalid_string'), isNull);
      expect(IdParser.extractNumericId('/api/v1/orders/abc'), isNull);
    });

    test('handles double values safely', () {
      expect(IdParser.extractNumericId(577.0), equals(577));
      expect(IdParser.extractNumericId(577.5), isNull);
    });
  });
}
