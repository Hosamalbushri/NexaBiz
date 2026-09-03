import 'number_normalizer.dart';
import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Normalizes identifiers, SKUs, and entity codes (strips zero-width chars/BOM, converts Eastern digits, uppercases ASCII).
class CodeNormalizer {
  const CodeNormalizer();

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    var text = rawValue.toString();
    // Strip BOM (\uFEFF) and zero-width characters (\u200B, \u200C, \u200D)
    var cleaned = text
        .replaceAll(RegExp(r'[\uFEFF\u200B\u200C\u200D]'), '')
        .trim();

    final hadEasternDigits = RegExp(r'[\u0660-\u0669]').hasMatch(cleaned);
    cleaned = convertEasternArabicDigits(cleaned);

    // Uppercase ASCII code letters
    final uppercased = cleaned.toUpperCase();
    final isChanged = uppercased != text;

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: uppercased,
      isNormalized: isChanged,
      isNull: false,
      normalizationMetadata: {
        if (hadEasternDigits) 'easternArabicDigitsConverted': true,
        if (isChanged) 'codeStandardized': true,
      },
    );
  }
}
