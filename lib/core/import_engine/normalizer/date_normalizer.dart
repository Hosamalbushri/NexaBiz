import 'number_normalizer.dart';
import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Normalizes dates across representations (YYYY-MM-DD, YYYY/MM/DD, DD/MM/YYYY, DD-MM-YYYY, ISO-8601).
class DateNormalizer {
  const DateNormalizer();

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    if (rawValue is DateTime) {
      final dateOnly = DateTime(rawValue.year, rawValue.month, rawValue.day);
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: dateOnly,
        isNull: false,
      );
    }

    var str = rawValue.toString().trim();
    final hadEasternDigits = RegExp(r'[\u0660-\u0669]').hasMatch(str);
    str = convertEasternArabicDigits(str);

    // Standard DateTime.tryParse check (ISO 8601)
    final isoParse = DateTime.tryParse(str);
    if (isoParse != null) {
      final dateOnly = DateTime(isoParse.year, isoParse.month, isoParse.day);
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: dateOnly,
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {
          if (hadEasternDigits) 'easternArabicDigitsConverted': true,
          'detectedFormat': 'ISO-8601',
        },
      );
    }

    // Try custom Regex patterns for non-ISO formats: DD/MM/YYYY, DD-MM-YYYY, YYYY/MM/DD
    // 1. YYYY/MM/DD
    var match = RegExp(
      r'^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})$',
    ).firstMatch(str);
    if (match != null) {
      final y = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final d = int.parse(match.group(3)!);
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: DateTime(y, m, d),
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {'detectedFormat': 'YYYY/MM/DD'},
      );
    }

    // 2. DD/MM/YYYY or DD-MM-YYYY
    match = RegExp(r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$').firstMatch(str);
    if (match != null) {
      final d = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final y = int.parse(match.group(3)!);
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: DateTime(y, m, d),
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {'detectedFormat': 'DD/MM/YYYY'},
      );
    }

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: null,
      isMalformed: true,
      normalizationMetadata: {'error': 'unparsable_date'},
    );
  }
}
