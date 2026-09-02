import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/models/report_dataset.dart';
import '../domain/models/report_definition_spec.dart';


/// Exporter generating native Microsoft Excel (.xlsx) workbooks with metadata & styled tables.
class ExcelReportExporter {
  const ExcelReportExporter();

  /// Exports [ReportDataset] to an .xlsx file and opens system share/save sheet.
  static Future<File> exportAndShare(
    ReportDefinitionSpec definition,
    ReportDataset dataset,
  ) async {
    final excel = Excel.createExcel();
    final sheetName = definition.name.length > 30
        ? definition.name.substring(0, 30)
        : definition.name;
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Header Styling
    final CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
    );

    int rowIndex = 0;

    // Report Title & Metadata Header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue(dataset.metadata.reportTitle)
      ..cellStyle = titleStyle;
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('الشركة: ${dataset.metadata.companyName}');
    rowIndex++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      .value = TextCellValue('تاريخ التوليد: ${DateFormat('yyyy/MM/dd HH:mm').format(dataset.metadata.generatedAt)}');
    rowIndex++;

    if (dataset.metadata.activeFiltersSummary.isNotEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('معايير التصفية: ${dataset.metadata.activeFiltersSummary}');
      rowIndex++;
    }

    rowIndex++; // Empty space before table

    // Column Headers
    final visibleColumns = definition.columns.where((c) => c.isVisible).toList();
    for (int colIdx = 0; colIdx < visibleColumns.length; colIdx++) {
      final col = visibleColumns[colIdx];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIndex))
        ..value = TextCellValue(col.label)
        ..cellStyle = headerStyle;
    }
    rowIndex++;

    // Data Rows
    for (final row in dataset.rows) {
      for (int colIdx = 0; colIdx < visibleColumns.length; colIdx++) {
        final col = visibleColumns[colIdx];
        final rawVal = row[col.id];

        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIndex));

        if (rawVal == null) {
          cell.value = TextCellValue('');
        } else if (rawVal is num) {
          cell.value = DoubleCellValue(rawVal.toDouble());
        } else if (rawVal is DateTime) {
          cell.value = TextCellValue(DateFormat('yyyy/MM/dd').format(rawVal));
        } else if (rawVal is bool) {
          cell.value = TextCellValue(rawVal ? 'نعم' : 'لا');
        } else {
          cell.value = TextCellValue(rawVal.toString());
        }
      }
      rowIndex++;
    }

    // Save File
    final fileBytes = excel.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = '${definition.id}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${tempDir.path}/$fileName');

    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: dataset.metadata.reportTitle,
      );
    }

    return file;
  }
}
