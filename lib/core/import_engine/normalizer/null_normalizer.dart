import 'normalized_value.dart';

/// Detects null placeholders across English and Arabic text representations.
class NullNormalizer {
  const NullNormalizer();

  static const _nullPlaceholders = {
    '',
    'null',
    'nil',
    'none',
    'n/a',
    'na',
    '-',
    '--',
    'لا يوجد',
    'عدم وجود',
    'فارغ',
  };

  /// Normalizes value checking for null or empty placeholders.
  static NormalizedValue normalize(dynamic rawValue) {
    if (rawValue == null) {
      return const NormalizedValue(
        originalValue: null,
        normalizedValue: null,
        isNull: true,
        normalizationMetadata: {'reason': 'null_reference'},
      );
    }

    final str = rawValue.toString().trim().toLowerCase();
    if (_nullPlaceholders.contains(str)) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: null,
        isNormalized: true,
        isNull: true,
        normalizationMetadata: {
          'reason': 'placeholder_detected',
          'placeholder': rawValue.toString().trim(),
        },
      );
    }

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: rawValue,
      isNull: false,
    );
  }
}
