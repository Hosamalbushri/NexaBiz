import 'number_normalizer.dart';
import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Normalizes datetime ISO strings and date-time combinations preserving timestamp precision.
class DateTimeNormalizer {
  const DateTimeNormalizer();

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    if (rawValue is DateTime) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: rawValue,
        isNull: false,
      );
    }

    var str = rawValue.toString().trim();
    final hadEasternDigits = RegExp(r'[\u0660-\u0669]').hasMatch(str);
    str = convertEasternArabicDigits(str);

    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: parsed,
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {
          if (hadEasternDigits) 'easternArabicDigitsConverted': true,
          'detectedFormat': 'ISO-8601',
        },
      );
    }

    // Try space separated YYYY-MM-DD HH:mm:ss
    final match = RegExp(
      r'^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(str);

    if (match != null) {
      final y = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final d = int.parse(match.group(3)!);
      final hh = int.parse(match.group(4)!);
      final mm = int.parse(match.group(5)!);
      final ss = match.group(6) != null ? int.parse(match.group(6)!) : 0;

      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: DateTime(y, m, d, hh, mm, ss),
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {'detectedFormat': 'YYYY-MM-DD HH:mm:ss'},
      );
    }

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: null,
      isMalformed: true,
      normalizationMetadata: {'error': 'unparsable_datetime'},
    );
  }
}
