/// Represents a validation or processing error for a specific row/field in an import.
class ImportError {
  const ImportError({
    required this.code,
    required this.message,
    this.rowIndex,
    this.fieldKey,
    this.isFatal = false,
  });

  final String code;
  final String message;
  final int? rowIndex;
  final String? fieldKey;
  final bool isFatal;

  @override
  String toString() =>
      'ImportError($code): $message${rowIndex != null ? ' at row $rowIndex' : ''}${fieldKey != null ? ' [field: $fieldKey]' : ''}';
}

/// Represents a non-fatal warning generated during import validation or parsing.
class ImportWarning {
  const ImportWarning({
    required this.code,
    required this.message,
    this.rowIndex,
    this.fieldKey,
  });

  final String code;
  final String message;
  final int? rowIndex;
  final String? fieldKey;

  @override
  String toString() =>
      'ImportWarning($code): $message${rowIndex != null ? ' at row $rowIndex' : ''}${fieldKey != null ? ' [field: $fieldKey]' : ''}';
}
