import 'dart:convert';

import '../domain/entities/import_parse_error.dart';
import '../domain/entities/parsed_cell.dart';
import '../domain/entities/parsed_document.dart';
import '../domain/entities/parsed_row.dart';
import '../domain/entities/parsed_sheet.dart';
import '../domain/ports/import_source.dart';
import '../sources/bytes_import_source.dart';
import '../sources/string_import_source.dart';
import 'import_parser.dart';

/// Production-grade CSV parser supporting UTF-8, BOM removal, auto-delimiter detection,
/// quoted fields, escaped quotes (""), multiline quotes, and Arabic text preservation.
class CsvImportParser extends ImportParser {
  const CsvImportParser({this.customDelimiter, this.hasHeader = true});

  final String? customDelimiter;
  final bool hasHeader;

  @override
  ImportFileFormat get format => ImportFileFormat.csv;

  @override
  Future<ParsedDocument> parseDocument(ImportSource source) async {
    final sheet = await parseSheet(source);
    return ParsedDocument(
      sourceId: source.sourceId,
      format: ImportFileFormat.csv,
      sheets: [sheet],
    );
  }

  @override
  Future<ParsedSheet> parseSheet(
    ImportSource source, {
    String? sheetName,
    int? sheetIndex,
  }) async {
    final rawText = await _extractTextFromSource(source);
    if (rawText.trim().isEmpty) {
      return ParsedSheet(
        sheetIndex: sheetIndex ?? 0,
        name: sheetName ?? 'Sheet1',
        headers: const [],
        rows: const [],
      );
    }

    final sanitizedText = _stripUtf8Bom(rawText);
    final delimiter = customDelimiter ?? _detectDelimiter(sanitizedText);
    final rawTable = _parseCsvToGrid(sanitizedText, delimiter, source.sourceId);

    if (rawTable.isEmpty) {
      return ParsedSheet(
        sheetIndex: sheetIndex ?? 0,
        name: sheetName ?? 'Sheet1',
        headers: const [],
        rows: const [],
      );
    }

    final headers = <String>[];
    var startRowIndex = 0;

    if (hasHeader && rawTable.isNotEmpty) {
      final headerRow = rawTable.first;
      for (var colIdx = 0; colIdx < headerRow.length; colIdx++) {
        headers.add(headerRow[colIdx].trim());
      }
      startRowIndex = 1;
    }

    final rows = <ParsedRow>[];
    for (var r = startRowIndex; r < rawTable.length; r++) {
      final rawRowValues = rawTable[r];
      final rowErrors = <ImportParseError>[];

      // Check if row is completely empty
      final isRowEmpty = rawRowValues.every((val) => val.trim().isEmpty);
      if (isRowEmpty) continue;

      final cells = <ParsedCell>[];
      final colCount = headers.isNotEmpty
          ? headers.length
          : rawRowValues.length;

      for (var c = 0; c < colCount; c++) {
        final rawVal = c < rawRowValues.length ? rawRowValues[c] : '';
        final headerName = c < headers.length ? headers[c] : null;

        cells.add(
          ParsedCell(
            columnIndex: c,
            headerName: headerName,
            rawValue: rawVal,
            formattedValue: rawVal,
          ),
        );
      }

      rows.add(
        ParsedRow(
          rowIndex: r + 1, // 1-indexed for user readability
          cells: cells,
          errors: rowErrors,
        ),
      );
    }

    return ParsedSheet(
      sheetIndex: sheetIndex ?? 0,
      name: sheetName ?? 'Sheet1',
      headers: headers,
      rows: rows,
    );
  }

  /// Extracts text content from source object.
  Future<String> _extractTextFromSource(ImportSource source) async {
    if (source is StringImportSource) {
      return source.content;
    }
    if (source is BytesImportSource) {
      return utf8.decode(source.bytes, allowMalformed: true);
    }
    return '';
  }

  /// Removes UTF-8 Byte Order Mark (\uFEFF or EF BB BF).
  String _stripUtf8Bom(String text) {
    if (text.startsWith('\uFEFF')) {
      return text.substring(1);
    }
    return text;
  }

  /// Auto-detects CSV field delimiter (comma, semicolon, tab, pipe).
  String _detectDelimiter(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).take(5);
    if (lines.isEmpty) return ',';

    final candidates = [',', ';', '\t', '|'];
    var bestDelimiter = ',';
    var maxCount = -1;

    for (final delimiter in candidates) {
      var count = 0;
      for (final line in lines) {
        count += _countOccurrences(line, delimiter);
      }
      if (count > maxCount) {
        maxCount = count;
        bestDelimiter = delimiter;
      }
    }

    return bestDelimiter;
  }

  int _countOccurrences(String line, String char) {
    var count = 0;
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      if (line[i] == '"') {
        inQuotes = !inQuotes;
      } else if (line[i] == char && !inQuotes) {
        count++;
      }
    }
    return count;
  }

  /// Robust state-machine parser handling quotes, escaped quotes (""), and linebreaks inside quotes.
  List<List<String>> _parseCsvToGrid(
    String input,
    String delimiter,
    String sourceId,
  ) {
    final grid = <List<String>>[];
    var currentRow = <String>[];
    final currentField = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < input.length) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            // Escaped quote ("")
            currentField.write('"');
            i += 2;
            continue;
          } else {
            // Closing quote
            inQuotes = false;
            i++;
            continue;
          }
        } else {
          currentField.write(char);
          i++;
          continue;
        }
      } else {
        if (char == '"') {
          inQuotes = true;
          i++;
          continue;
        } else if (input.startsWith(delimiter, i)) {
          currentRow.add(currentField.toString());
          currentField.clear();
          i += delimiter.length;
          continue;
        } else if (char == '\r') {
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentField.toString());
          currentField.clear();
          grid.add(currentRow);
          currentRow = [];
          i++;
          continue;
        } else if (char == '\n') {
          currentRow.add(currentField.toString());
          currentField.clear();
          grid.add(currentRow);
          currentRow = [];
          i++;
          continue;
        } else {
          currentField.write(char);
          i++;
          continue;
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      grid.add(currentRow);
    }

    return grid;
  }
}
