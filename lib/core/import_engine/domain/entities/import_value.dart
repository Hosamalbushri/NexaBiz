/// Supported generic data types in the import engine.
enum ImportDataType {
  text,
  number,
  integer,
  boolean,
  date,
  dateTime,
  json,
  relation,
}

/// Encapsulates a raw cell value and its normalized typed representation.
class ImportValue {
  const ImportValue({
    required this.rawValue,
    this.normalizedValue,
    this.dataType = ImportDataType.text,
    this.isValid = true,
    this.conversionError,
  });

  factory ImportValue.empty(ImportDataType dataType) => ImportValue(
        rawValue: null,
        normalizedValue: null,
        dataType: dataType,
        isValid: true,
      );

  final dynamic rawValue;
  final dynamic normalizedValue;
  final ImportDataType dataType;
  final bool isValid;
  final String? conversionError;

  bool get isNull => rawValue == null && normalizedValue == null;
  bool get isEmpty =>
      isNull || (rawValue is String && (rawValue as String).trim().isEmpty);

  ImportValue copyWith({
    dynamic rawValue,
    dynamic normalizedValue,
    ImportDataType? dataType,
    bool? isValid,
    String? conversionError,
  }) {
    return ImportValue(
      rawValue: rawValue ?? this.rawValue,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      dataType: dataType ?? this.dataType,
      isValid: isValid ?? this.isValid,
      conversionError: conversionError ?? this.conversionError,
    );
  }
}
