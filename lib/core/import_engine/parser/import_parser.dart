import '../domain/entities/parsed_document.dart';
import '../domain/entities/parsed_sheet.dart';
import '../domain/ports/import_source.dart';

/// Abstract base parser interface for document sources.
abstract class ImportParser {
  const ImportParser();

  /// Identifies the format supported by this parser instance.
  ImportFileFormat get format;

  /// Parses an [ImportSource] into a complete [ParsedDocument].
  Future<ParsedDocument> parseDocument(ImportSource source);

  /// Parses a single sheet/table from an [ImportSource].
  Future<ParsedSheet> parseSheet(
    ImportSource source, {
    String? sheetName,
    int? sheetIndex,
  });
}
