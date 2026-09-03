import 'dart:typed_data';
import 'package:excel/excel.dart';

import '../domain/entities/import_parse_error.dart';
import '../domain/entities/import_value.dart';
import '../domain/entities/parsed_cell.dart';
import '../domain/entities/parsed_document.dart';
import '../domain/entities/parsed_row.dart';
import '../domain/entities/parsed_sheet.dart';
import '../domain/ports/import_source.dart';
import '../sources/bytes_import_source.dart';
import 'import_parser.dart';

/// XLSX Excel workbook parser supporting multiple worksheets, sheet selection,
/// headers, empty cells, formula values, numeric/date types, and structured errors.
class XlsxImportParser extends ImportParser {
  const XlsxImportParser({
    this.hasHeader = true,
  });

  final bool hasHeader;

  @override
  ImportFileFormat get format => ImportFileFormat.xlsx;

  @override
  Future<ParsedDocument> parseDocument(ImportSource source) async {
    final bytes = await _extractBytes(source);
    if (bytes.isEmpty) {
      return ParsedDocument(
        sourceId: source.sourceId,
        format: ImportFileFormat.xlsx,
        sheets: const [],
        errors: [
          ImportParseError(
            code: 'EMPTY_FILE',
            message: 'Excel bytes are empty.',
            sourceId: source.sourceId,
          ),
        ],
      );
    }

    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (e) {
      return ParsedDocument(
        sourceId: source.sourceId,
        format: ImportFileFormat.xlsx,
        sheets: const [],
        errors: [
          ImportParseError(
            code: 'DECODE_FAILED',
            message: 'Failed to decode Excel XLSX workbook: ${e.toString()}',
            sourceId: source.sourceId,
          ),
        ],
      );
    }

    final parsedSheets = <ParsedSheet>[];
    var sheetIdx = 0;

    for (final sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName];
      if (table == null) continue;

      final parsedSheet = _parseExcelTable(
        sheetIndex: sheetIdx++,
        sheetName: sheetName,
        table: table,
        sourceId: source.sourceId,
      );
      parsedSheets.add(parsedSheet);
    }

    return ParsedDocument(
      sourceId: source.sourceId,
      format: ImportFileFormat.xlsx,
      sheets: parsedSheets,
    );
  }

  @override
  Future<ParsedSheet> parseSheet(
    ImportSource source, {
    String? sheetName,
    int? sheetIndex,
  }) async {
    final doc = await parseDocument(source);
    if (doc.sheets.isEmpty) {
      return ParsedSheet(
        sheetIndex: sheetIndex ?? 0,
        name: sheetName ?? 'Sheet1',
        headers: const [],
        rows: const [],
      );
    }

    if (sheetName != null) {
      final found = doc.getSheetByName(sheetName);
      if (found != null) return found;
    }

    if (sheetIndex != null &&
        sheetIndex >= 0 &&
        sheetIndex < doc.sheets.length) {
      return doc.sheets[sheetIndex];
    }

    return doc.sheets.first;
  }

  Future<Uint8List> _extractBytes(ImportSource source) async {
    if (source is BytesImportSource) {
      return source.bytes;
    }
    return Uint8List(0);
  }

  ParsedSheet _parseExcelTable({
    required int sheetIndex,
    required String sheetName,
    required Sheet table,
    required String sourceId,
  }) {
    if (table.maxRows == 0) {
      return ParsedSheet(
        sheetIndex: sheetIndex,
        name: sheetName,
        headers: const [],
        rows: const [],
      );
    }

    final headers = <String>[];
    var startRowIndex = 0;

    if (hasHeader && table.maxRows > 0) {
      final headerRow = table.rows.first;
      for (var colIdx = 0; colIdx < headerRow.length; colIdx++) {
        final cell = headerRow[colIdx];
        final headerText = cell?.value != null ? cell!.value.toString().trim() : '';
        headers.add(headerText);
      }
      startRowIndex = 1;
    }

    final parsedRows = <ParsedRow>[];

    for (var r = startRowIndex; r < table.maxRows; r++) {
      final excelRow = table.rows[r];
      final isRowEmpty = excelRow.every((c) => c?.value == null || c!.value.toString().trim().isEmpty);
      if (isRowEmpty) continue;

      final cells = <ParsedCell>[];
      final colCount = headers.isNotEmpty ? headers.length : excelRow.length;

      for (var c = 0; c < colCount; c++) {
        final Data? excelCell = c < excelRow.length ? excelRow[c] : null;
        final headerName = c < headers.length ? headers[c] : null;

        dynamic rawVal;
        ImportDataType dataType = ImportDataType.text;

        if (excelCell != null && excelCell.value != null) {
          final cellValue = excelCell.value;
          if (cellValue is IntCellValue) {
            rawVal = cellValue.value;
            dataType = ImportDataType.integer;
          } else if (cellValue is DoubleCellValue) {
            rawVal = cellValue.value;
            dataType = ImportDataType.number;
          } else if (cellValue is BoolCellValue) {
            rawVal = cellValue.value;
            dataType = ImportDataType.boolean;
          } else if (cellValue is DateCellValue) {
            rawVal = DateTime(
              cellValue.year,
              cellValue.month,
              cellValue.day,
            ).toIso8601String();
            dataType = ImportDataType.date;
          } else if (cellValue is FormulaCellValue) {
            rawVal = cellValue.formula;
            dataType = ImportDataType.text;
          } else {
            rawVal = cellValue.toString();
          }
        }

        cells.add(ParsedCell(
          columnIndex: c,
          headerName: headerName,
          rawValue: rawVal,
          formattedValue: rawVal?.toString() ?? '',
          dataType: dataType,
        ));
      }

      parsedRows.add(ParsedRow(
        rowIndex: r + 1,
        cells: cells,
      ));
    }

    return ParsedSheet(
      sheetIndex: sheetIndex,
      name: sheetName,
      headers: headers,
      rows: parsedRows,
    );
  }
}
