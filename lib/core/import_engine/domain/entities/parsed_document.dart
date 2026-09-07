import 'import_parse_error.dart';
import 'parsed_sheet.dart';

/// Supported import document file formats.
enum ImportFileFormat { csv, xlsx, json, unknown }

/// Generic parsed document representing an ingested file workbook or dataset.
class ParsedDocument {
  const ParsedDocument({
    required this.sourceId,
    required this.format,
    required this.sheets,
    this.errors = const [],
  });

  factory ParsedDocument.empty(String sourceId, ImportFileFormat format) =>
      ParsedDocument(sourceId: sourceId, format: format, sheets: const []);

  final String sourceId;
  final ImportFileFormat format;
  final List<ParsedSheet> sheets;
  final List<ImportParseError> errors;

  /// Default active sheet (first sheet or named sheet).
  ParsedSheet? get activeSheet => sheets.isNotEmpty ? sheets.first : null;

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty => sheets.isEmpty || sheets.every((sheet) => sheet.isEmpty);

  ParsedSheet? getSheetByName(String name) {
    for (final sheet in sheets) {
      if (sheet.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return sheet;
      }
    }
    return null;
  }
}
