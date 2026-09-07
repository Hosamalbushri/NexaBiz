import 'validation_severity.dart';

/// Single validation finding report targeting a row and field.
class ValidationIssue {
  const ValidationIssue({
    required this.row,
    required this.field,
    required this.code,
    required this.severity,
    required this.message,
    this.originalValue,
    this.normalizedValue,
  });

  /// 1-indexed row number.
  final int row;

  /// Target field key (e.g. 'product_code').
  final String field;

  /// Error / warning machine-readable code.
  final String code;

  /// Severity level (INFO, WARNING, ERROR, FATAL).
  final ValidationSeverity severity;

  /// Human-readable explanation.
  final String message;

  /// Raw input value before normalization.
  final dynamic originalValue;

  /// Normalized value produced by NormalizationEngine.
  final dynamic normalizedValue;

  Map<String, dynamic> toJson() => {
    'row': row,
    'field': field,
    'code': code,
    'severity': severity.name,
    'message': message,
    'originalValue': originalValue?.toString(),
    'normalizedValue': normalizedValue?.toString(),
  };
}
