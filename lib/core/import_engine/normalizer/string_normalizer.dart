import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Trims whitespace, strips BOM & zero-width Unicode characters, and preserves text.
class StringNormalizer {
  const StringNormalizer();

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    var text = rawValue.toString();
    // Strip BOM (\uFEFF) and zero-width spaces (\u200B, \u200C, \u200D)
    final cleaned = text
        .replaceAll(RegExp(r'[\uFEFF\u200B\u200C\u200D]'), '')
        .trim();

    final isChanged = cleaned != text;

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: cleaned,
      isNormalized: isChanged,
      isNull: false,
      normalizationMetadata: {
        if (isChanged) 'trimmedWhitespace': true,
      },
    );
  }
}
