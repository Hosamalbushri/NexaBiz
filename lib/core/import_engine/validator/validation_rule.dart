import '../normalizer/normalized_value.dart';
import 'validation_issue.dart';
import 'validation_severity.dart';

/// Abstract validation rule contract.
abstract class ValidationRule {
  const ValidationRule();

  /// Evaluates a cell's [normalizedValue] for a given [row] index and [field] key.
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  });
}

/// Validates mandatory field presence.
class RequiredValidationRule extends ValidationRule {
  const RequiredValidationRule({
    this.severity = ValidationSeverity.error,
    this.message = 'Field is required',
  });

  final ValidationSeverity severity;
  final String message;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    if (normalizedValue.isNull || normalizedValue.normalizedValue == null) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'REQUIRED_FIELD_MISSING',
        severity: severity,
        message: message,
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    return null;
  }
}

/// Validates value primitive / data type compatibility.
class TypeValidationRule extends ValidationRule {
  const TypeValidationRule({
    required this.expectedType,
    this.severity = ValidationSeverity.error,
  });

  final Type expectedType;
  final ValidationSeverity severity;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    if (normalizedValue.isNull) return null;
    if (normalizedValue.isMalformed) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'TYPE_MISMATCH',
        severity: severity,
        message: 'Value is malformed or invalid for type $expectedType',
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    final val = normalizedValue.normalizedValue;
    if (val != null && val.runtimeType != expectedType) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'TYPE_MISMATCH',
        severity: severity,
        message: 'Expected type $expectedType but got ${val.runtimeType}',
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    return null;
  }
}

/// Validates format conditions (e.g., date formatting).
class FormatValidationRule extends ValidationRule {
  const FormatValidationRule({
    this.severity = ValidationSeverity.error,
    this.message = 'Invalid format',
  });

  final ValidationSeverity severity;
  final String message;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    if (normalizedValue.isNull) return null;
    if (normalizedValue.isMalformed) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'INVALID_FORMAT',
        severity: severity,
        message: message,
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    return null;
  }
}

/// Validates numeric range bounds (min <= value <= max).
class RangeValidationRule extends ValidationRule {
  const RangeValidationRule({
    this.min,
    this.max,
    this.severity = ValidationSeverity.error,
  });

  final num? min;
  final num? max;
  final ValidationSeverity severity;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    if (normalizedValue.isNull || normalizedValue.isMalformed) return null;
    final val = normalizedValue.normalizedValue;
    if (val is num) {
      if (min != null && val < min!) {
        return ValidationIssue(
          row: row,
          field: field,
          code: 'VALUE_BELOW_MINIMUM',
          severity: severity,
          message: 'Value $val is below minimum $min',
          originalValue: normalizedValue.originalValue,
          normalizedValue: normalizedValue.normalizedValue,
        );
      }
      if (max != null && val > max!) {
        return ValidationIssue(
          row: row,
          field: field,
          code: 'VALUE_ABOVE_MAXIMUM',
          severity: severity,
          message: 'Value $val exceeds maximum $max',
          originalValue: normalizedValue.originalValue,
          normalizedValue: normalizedValue.normalizedValue,
        );
      }
    }
    return null;
  }
}

/// Validates string character length limits.
class LengthValidationRule extends ValidationRule {
  const LengthValidationRule({
    this.minLength,
    this.maxLength,
    this.severity = ValidationSeverity.error,
  });

  final int? minLength;
  final int? maxLength;
  final ValidationSeverity severity;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    if (normalizedValue.isNull || normalizedValue.isMalformed) return null;
    final str = normalizedValue.normalizedValue.toString();
    if (minLength != null && str.length < minLength!) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'LENGTH_TOO_SHORT',
        severity: severity,
        message: 'Length ${str.length} is below minimum length $minLength',
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    if (maxLength != null && str.length > maxLength!) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'LENGTH_TOO_LONG',
        severity: severity,
        message: 'Length ${str.length} exceeds maximum length $maxLength',
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    return null;
  }
}

/// Validates string values against regular expressions.
class RegexValidationRule extends ValidationRule {
  const RegexValidationRule({
    required this.pattern,
    this.severity = ValidationSeverity.error,
    this.message = 'Value does not match required pattern',
  });

  final RegExp pattern;
  final ValidationSeverity severity;
  final String message;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    if (normalizedValue.isNull || normalizedValue.isMalformed) return null;
    final str = normalizedValue.normalizedValue.toString();
    if (!pattern.hasMatch(str)) {
      return ValidationIssue(
        row: row,
        field: field,
        code: 'PATTERN_MISMATCH',
        severity: severity,
        message: message,
        originalValue: normalizedValue.originalValue,
        normalizedValue: normalizedValue.normalizedValue,
      );
    }
    return null;
  }
}

/// Evaluates unique constraint across rows within dataset in-memory.
class UniqueValidationRule extends ValidationRule {
  const UniqueValidationRule({
    this.severity = ValidationSeverity.error,
    this.message = 'Duplicate value detected in dataset',
  });

  final ValidationSeverity severity;
  final String message;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    // Note: Unique validation across rows is evaluated by ValidationEngine orchestrator
    return null;
  }
}

/// Validates existence against an external lookup callback (e.g. database/relation check).
class ExistsValidationRule extends ValidationRule {
  const ExistsValidationRule({
    required this.lookupFn,
    this.severity = ValidationSeverity.error,
    this.message = 'Referenced entity does not exist',
  });

  final Future<bool> Function(dynamic value) lookupFn;
  final ValidationSeverity severity;
  final String message;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    // Evaluated asynchronously by ValidationEngine orchestrator
    return null;
  }
}

/// Custom user-provided validation callback.
class CustomValidationRule extends ValidationRule {
  const CustomValidationRule({required this.validator});

  final ValidationIssue? Function({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) validator;

  @override
  ValidationIssue? evaluate({
    required int row,
    required String field,
    required NormalizedValue normalizedValue,
  }) {
    return validator(
      row: row,
      field: field,
      normalizedValue: normalizedValue,
    );
  }
}
