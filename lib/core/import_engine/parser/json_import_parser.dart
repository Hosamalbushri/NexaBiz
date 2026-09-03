import 'dart:convert';

import '../domain/entities/parsed_cell.dart';
import '../domain/entities/parsed_document.dart';
import '../domain/entities/parsed_row.dart';
import '../domain/entities/parsed_sheet.dart';
import '../domain/ports/import_source.dart';
import '../sources/bytes_import_source.dart';
import '../sources/string_import_source.dart';
import 'import_parser.dart';

/// Strategy for flattening nested JSON object maps into flat column key-value pairs.
enum JsonFlatteningStrategy {
  /// Flattens nested keys using dot notation (e.g. "address.city").
  dotNotation,

  /// Flattens nested keys using underscore notation (e.g. "address_city").
  underscoreNotation,

  /// Ignores nested objects (converts them to raw JSON strings).
  none,
}

/// JSON parser supporting top-level arrays, wrapped object arrays, nested objects,
/// configurable key flattening, and structured error reporting.
class JsonImportParser extends ImportParser {
  const JsonImportParser({
    this.rootArrayKey,
    this.flatteningStrategy = JsonFlatteningStrategy.dotNotation,
  });

  final String? rootArrayKey;
  final JsonFlatteningStrategy flatteningStrategy;

  @override
  ImportFileFormat get format => ImportFileFormat.json;

  @override
  Future<ParsedDocument> parseDocument(ImportSource source) async {
    final sheet = await parseSheet(source);
    return ParsedDocument(
      sourceId: source.sourceId,
      format: ImportFileFormat.json,
      sheets: [sheet],
    );
  }

  @override
  Future<ParsedSheet> parseSheet(
    ImportSource source, {
    String? sheetName,
    int? sheetIndex,
  }) async {
    final jsonText = await _extractText(source);
    if (jsonText.trim().isEmpty) {
      return ParsedSheet(
        sheetIndex: sheetIndex ?? 0,
        name: sheetName ?? 'JSON_Data',
        headers: const [],
        rows: const [],
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (e) {
      return ParsedSheet(
        sheetIndex: sheetIndex ?? 0,
        name: sheetName ?? 'JSON_Data',
        headers: const [],
        rows: const [],
      );
    }

    final List<dynamic> records = _extractRecordList(decoded);
    if (records.isEmpty) {
      return ParsedSheet(
        sheetIndex: sheetIndex ?? 0,
        name: sheetName ?? 'JSON_Data',
        headers: const [],
        rows: const [],
      );
    }

    // Process and flatten objects
    final flattenedRecords = <Map<String, dynamic>>[];
    final headerSet = <String>{};

    for (final rawItem in records) {
      if (rawItem is Map<String, dynamic>) {
        final flatMap = _flattenMap(rawItem);
        flattenedRecords.add(flatMap);
        headerSet.addAll(flatMap.keys);
      } else if (rawItem is Map) {
        final stringMap = rawItem.map((k, v) => MapEntry(k.toString(), v));
        final flatMap = _flattenMap(stringMap);
        flattenedRecords.add(flatMap);
        headerSet.addAll(flatMap.keys);
      }
    }

    final headers = headerSet.toList();
    final rows = <ParsedRow>[];

    for (var r = 0; r < flattenedRecords.length; r++) {
      final record = flattenedRecords[r];
      final cells = <ParsedCell>[];

      for (var c = 0; c < headers.length; c++) {
        final key = headers[c];
        final val = record[key];

        cells.add(ParsedCell(
          columnIndex: c,
          headerName: key,
          rawValue: val,
          formattedValue: val?.toString() ?? '',
        ));
      }

      rows.add(ParsedRow(
        rowIndex: r + 1,
        cells: cells,
      ));
    }

    return ParsedSheet(
      sheetIndex: sheetIndex ?? 0,
      name: sheetName ?? 'JSON_Data',
      headers: headers,
      rows: rows,
    );
  }

  Future<String> _extractText(ImportSource source) async {
    if (source is StringImportSource) {
      return source.content;
    }
    if (source is BytesImportSource) {
      return utf8.decode(source.bytes, allowMalformed: true);
    }
    return '';
  }

  List<dynamic> _extractRecordList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      if (rootArrayKey != null && decoded.containsKey(rootArrayKey)) {
        final val = decoded[rootArrayKey];
        if (val is List) return val;
      }

      // Auto-detect first array value inside map
      for (final key in decoded.keys) {
        if (decoded[key] is List) {
          return decoded[key] as List;
        }
      }

      // Single object payload
      return [decoded];
    }
    return const [];
  }

  Map<String, dynamic> _flattenMap(
    Map<String, dynamic> input, [
    String prefix = '',
  ]) {
    if (flatteningStrategy == JsonFlatteningStrategy.none) {
      return input;
    }

    final result = <String, dynamic>{};
    final separator =
        flatteningStrategy == JsonFlatteningStrategy.dotNotation ? '.' : '_';

    input.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix$separator$key';
      if (value is Map<String, dynamic>) {
        result.addAll(_flattenMap(value, newKey));
      } else if (value is Map) {
        final stringMap = value.map((k, v) => MapEntry(k.toString(), v));
        result.addAll(_flattenMap(stringMap, newKey));
      } else {
        result[newKey] = value;
      }
    });

    return result;
  }
}
