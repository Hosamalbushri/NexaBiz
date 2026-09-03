import 'null_normalizer.dart';
import 'normalized_value.dart';

/// Normalizes truthy and falsy values across English and Arabic representations.
class BooleanNormalizer {
  const BooleanNormalizer();

  static const _truthyValues = {
    'true',
    't',
    '1',
    'yes',
    'y',
    'active',
    'enabled',
    'نعم',
    'صح',
    'مفعل',
    'ايوا',
    'ايوه',
    'نشط',
  };

  static const _falsyValues = {
    'false',
    'f',
    '0',
    'no',
    'n',
    'inactive',
    'disabled',
    'لا',
    'خطأ',
    'غير مفعل',
    'معطل',
    'غير نشط',
  };

  static NormalizedValue normalize(dynamic rawValue) {
    final nullCheck = NullNormalizer.normalize(rawValue);
    if (nullCheck.isNull) return nullCheck;

    if (rawValue is bool) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: rawValue,
        isNull: false,
      );
    }

    final str = rawValue.toString().trim().toLowerCase();

    if (_truthyValues.contains(str)) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: true,
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {'parsedAs': 'truthy'},
      );
    }

    if (_falsyValues.contains(str)) {
      return NormalizedValue(
        originalValue: rawValue,
        normalizedValue: false,
        isNormalized: true,
        isNull: false,
        normalizationMetadata: {'parsedAs': 'falsy'},
      );
    }

    return NormalizedValue(
      originalValue: rawValue,
      normalizedValue: null,
      isMalformed: true,
      normalizationMetadata: {'error': 'unparsable_boolean'},
    );
  }
}
