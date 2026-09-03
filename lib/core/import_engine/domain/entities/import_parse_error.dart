/// Structured error encountered during source parsing (identifying sheet, row, and column context).
class ImportParseError {
  const ImportParseError({
    required this.code,
    required this.message,
    this.sourceId,
    this.sheetName,
    this.rowIndex,
    this.columnIndex,
    this.columnHeader,
    this.rawContent,
  });

  final String code;
  final String message;
  final String? sourceId;
  final String? sheetName;
  final int? rowIndex;
  final int? columnIndex;
  final String? columnHeader;
  final String? rawContent;

  @override
  String toString() {
    final buffer = StringBuffer('ImportParseError[$code]: $message');
    if (sourceId != null) buffer.write(' (Source: $sourceId)');
    if (sheetName != null) buffer.write(' (Sheet: $sheetName)');
    if (rowIndex != null) buffer.write(' (Row: $rowIndex)');
    if (columnHeader != null) {
      buffer.write(' [Header: "$columnHeader"]');
    } else if (columnIndex != null) {
      buffer.write(' [Col: $columnIndex]');
    }
    return buffer.toString();
  }
}
