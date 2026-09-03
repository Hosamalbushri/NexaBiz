/// Preserves raw source inputs without destructive information loss while capturing
/// the normalized representation and metadata flags.
class NormalizedValue {
  const NormalizedValue({
    required this.originalValue,
    this.normalizedValue,
    this.isNormalized = false,
    this.isNull = false,
    this.isMalformed = false,
    this.normalizationMetadata = const {},
  });

  /// Raw input value exactly as received from parser/source.
  final dynamic originalValue;

  /// Typed / formatted normalized value.
  final dynamic normalizedValue;

  /// Whether the raw value underwent non-trivial normalization.
  final bool isNormalized;

  /// Whether the raw value represents a null/empty placeholder.
  final bool isNull;

  /// Whether the raw value failed normalization parsing.
  final bool isMalformed;

  /// Detailed metadata flags detailing transformation steps.
  final Map<String, dynamic> normalizationMetadata;

  NormalizedValue copyWith({
    dynamic originalValue,
    dynamic normalizedValue,
    bool? isNormalized,
    bool? isNull,
    bool? isMalformed,
    Map<String, dynamic>? normalizationMetadata,
  }) {
    return NormalizedValue(
      originalValue: originalValue ?? this.originalValue,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      isNormalized: isNormalized ?? this.isNormalized,
      isNull: isNull ?? this.isNull,
      isMalformed: isMalformed ?? this.isMalformed,
      normalizationMetadata:
          normalizationMetadata ?? this.normalizationMetadata,
    );
  }
}
