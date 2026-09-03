import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Helper to convert Eastern Arabic digits (٠١٢٣٤٥٦٧٨٩) to Western Arabic (0123456789).
String convertEasternArabicDigits(String input) {
  const easternDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var result = input;
  for (var i = 0; i < easternDigits.length; i++) {
    result = result.replaceAll(easternDigits[i], i.toString());
  }
  return result;
}

/// Normalizes integer values, converting Eastern Arabic digits and removing thousands separators.
class NumberNormalizer {
  const NumberNormalizer();

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    if (rawValue is int) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: rawValue,
        isNull: false,
      );
    }

    if (rawValue is double) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: rawValue.toInt(),
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {'truncatedFloat': true},
      );
    }

    var str = rawValue.toString().trim();
    final hadEasternDigits = RegExp(r'[\u0660-\u0669]').hasMatch(str);
    str = convertEasternArabicDigits(str);

    // Replace commas or spaces used as thousands separators if there's no decimal point
    str = str.replaceAll(RegExp(r'[\s,\._]'), '');

    final parsed = int.tryParse(str);
    if (parsed == null) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: null,
        isMalformed: true,
        normalizationMetadata: {'error': 'unparsable_integer'},
      );
    }

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: parsed,
      isNormalized: true,
      isNull: false,
      normalizationMetadata: {
        if (hadEasternDigits) 'easternArabicDigitsConverted': true,
      },
    );
  }
}
