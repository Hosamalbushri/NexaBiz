import '../domain/entities/parsed_document.dart';
import '../domain/exceptions/import_engine_exception.dart';
import 'csv_import_parser.dart';
import 'import_parser.dart';
import 'json_import_parser.dart';
import 'xlsx_import_parser.dart';

/// Factory responsible for instantiating the appropriate [ImportParser] based on format/file name.
class UniversalParserFactory {
  const UniversalParserFactory();

  /// Resolves an [ImportParser] based on [ImportFileFormat].
  static ImportParser forFormat(ImportFileFormat format) {
    switch (format) {
      case ImportFileFormat.csv:
        return const CsvImportParser();
      case ImportFileFormat.xlsx:
        return const XlsxImportParser();
      case ImportFileFormat.json:
        return const JsonImportParser();
      case ImportFileFormat.unknown:
        throw const ImportEngineException(
          'Unsupported or unknown file format.',
          'UNSUPPORTED_FORMAT',
        );
    }
  }

  /// Resolves an [ImportParser] based on file path or file name extension.
  static ImportParser forFileName(String fileName) {
    final clean = fileName.trim().toLowerCase();
    if (clean.endsWith('.csv') || clean.endsWith('.txt')) {
      return const CsvImportParser();
    }
    if (clean.endsWith('.xlsx') || clean.endsWith('.xls')) {
      return const XlsxImportParser();
    }
    if (clean.endsWith('.json')) {
      return const JsonImportParser();
    }

    throw ImportEngineException(
      'Unable to detect parser for file "$fileName". Unrecognized extension.',
      'UNRECOGNIZED_FILE_EXTENSION',
    );
  }
}
