import 'number_normalizer.dart';
import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Normalizes floating-point decimal numbers across formats (1,250.50, 1250.50, 1250,50, ١٢٥٠٫٥٠).
class DecimalNormalizer {
  const DecimalNormalizer();

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    if (rawValue is double) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: rawValue,
        isNull: false,
      );
    }

    if (rawValue is int) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: rawValue.toDouble(),
        isNormalized: true,
        isNull: false,
      );
    }

    var str = rawValue.toString().trim();
    final hadEasternDigits = RegExp(r'[\u0660-\u0669]').hasMatch(str);

    // Convert Eastern Arabic digits
    str = convertEasternArabicDigits(str);

    // Replace Arabic decimal separator (٫) with standard dot (.)
    str = str.replaceAll('٫', '.');

    // Handle comma vs dot separators:
    // Case A: 1,250.50 -> strip comma
    // Case B: 1.250,50 -> strip dot, replace comma with dot
    // Case C: 1250,50 -> replace comma with dot
    if (str.contains(',') && str.contains('.')) {
      final lastComma = str.lastIndexOf(',');
      final lastDot = str.lastIndexOf('.');
      if (lastDot > lastComma) {
        // e.g. 1,250.50 -> remove commas
        str = str.replaceAll(',', '');
      } else {
        // e.g. 1.250,50 -> remove dots, change comma to dot
        str = str.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (str.contains(',')) {
      // Check if comma is used as decimal separator (e.g. 1250,50)
      str = str.replaceAll(',', '.');
    }

    // Strip spaces/underscores
    str = str.replaceAll(RegExp(r'[\s_]'), '');

    final parsed = double.tryParse(str);
    if (parsed == null) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: null,
        isMalformed: true,
        normalizationMetadata: {'error': 'unparsable_decimal'},
      );
    }

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: parsed,
      isNormalized: true,
      isNull: false,
      normalizationMetadata: {
        if (hadEasternDigits) 'easternArabicDigitsConverted': true,
        'parsedFormat': str,
      },
    );
  }
}
