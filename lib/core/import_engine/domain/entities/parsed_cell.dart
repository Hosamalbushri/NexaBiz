import 'import_value.dart';

/// Single parsed cell within a row.
class ParsedCell {
  const ParsedCell({
    required this.columnIndex,
    required this.rawValue,
    this.headerName,
    this.formattedValue,
    this.dataType = ImportDataType.text,
  });

  factory ParsedCell.empty(int columnIndex, {String? headerName}) => ParsedCell(
        columnIndex: columnIndex,
        headerName: headerName,
        rawValue: null,
        formattedValue: '',
        dataType: ImportDataType.text,
      );

  final int columnIndex;
  final String? headerName;
  final dynamic rawValue;
  final String? formattedValue;
  final ImportDataType dataType;

  bool get isNull => rawValue == null;
  bool get isEmpty =>
      isNull || (rawValue is String && (rawValue as String).trim().isEmpty);

  String get textValue =>
      formattedValue ?? (rawValue != null ? rawValue.toString() : '');
}
