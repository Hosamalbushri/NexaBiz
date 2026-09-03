import '../domain/entities/import_value.dart';
import '../detector/inferred_primitive_type.dart';
import 'boolean_normalizer.dart';
import 'code_normalizer.dart';
import 'date_normalizer.dart';
import 'datetime_normalizer.dart';
import 'decimal_normalizer.dart';
import 'null_normalizer.dart';
import 'normalized_value.dart';
import 'number_normalizer.dart';
import 'string_normalizer.dart';

/// Central Value Normalization Engine routing raw cell values to typed normalizers
/// based on target field data types or detected primitive types.
class NormalizationEngine {
  const NormalizationEngine();

  /// Normalizes a [rawValue] given a target [ImportDataType].
  NormalizedValue normalizeForDataType(dynamic rawValue, ImportDataType dataType) {
    switch (dataType) {
      case ImportDataType.text:
      case ImportDataType.json:
        return StringNormalizer.normalize(rawValue);
      case ImportDataType.integer:
        return NumberNormalizer.normalize(rawValue);
      case ImportDataType.number:
        return DecimalNormalizer.normalize(rawValue);
      case ImportDataType.boolean:
        return BooleanNormalizer.normalize(rawValue);
      case ImportDataType.date:
        return DateNormalizer.normalize(rawValue);
      case ImportDataType.dateTime:
        return DateTimeNormalizer.normalize(rawValue);
      case ImportDataType.relation:
        return CodeNormalizer.normalize(rawValue);
    }
  }


  /// Normalizes a [rawValue] given an [InferredPrimitiveType].
  NormalizedValue normalizeForPrimitiveType(
    dynamic rawValue,
    InferredPrimitiveType primitiveType,
  ) {
    switch (primitiveType) {
      case InferredPrimitiveType.string:
        return StringNormalizer.normalize(rawValue);
      case InferredPrimitiveType.integer:
        return NumberNormalizer.normalize(rawValue);
      case InferredPrimitiveType.decimal:
        return DecimalNormalizer.normalize(rawValue);
      case InferredPrimitiveType.boolean:
        return BooleanNormalizer.normalize(rawValue);
      case InferredPrimitiveType.date:
        return DateNormalizer.normalize(rawValue);
      case InferredPrimitiveType.datetime:
        return DateTimeNormalizer.normalize(rawValue);
      case InferredPrimitiveType.nullOrMixed:
        return NullNormalizer.normalize(rawValue);
    }
  }

  /// Explicitly normalizes a value as an entity Code / SKU.
  NormalizedValue normalizeCode(dynamic rawValue) {
    return CodeNormalizer.normalize(rawValue);
  }
}
