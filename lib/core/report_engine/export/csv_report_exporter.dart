import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/models/report_dataset.dart';
import '../domain/models/report_definition_spec.dart';


/// Exporter generating UTF-8 BOM CSV files for Excel & Spreadsheet compatibility.
class CsvReportExporter {
  const CsvReportExporter();

  /// Exports [ReportDataset] to a CSV file and opens system share/save dialog.
  static Future<File> exportAndShare(
    ReportDefinitionSpec definition,
    ReportDataset dataset,
  ) async {
    final buffer = StringBuffer();

    // UTF-8 BOM Header for Excel Arabic UTF-8 auto-detection
    buffer.write('\uFEFF');

    // Title & Metadata Headers
    buffer.writeln('"${dataset.metadata.reportTitle}"');
    buffer.writeln('"الشركة: ${dataset.metadata.companyName}"');
    buffer.writeln('"تاريخ التوليد: ${DateFormat('yyyy/MM/dd HH:mm').format(dataset.metadata.generatedAt)}"');
    if (dataset.metadata.activeFiltersSummary.isNotEmpty) {
      buffer.writeln('"معايير التصفية: ${dataset.metadata.activeFiltersSummary}"');
    }
    buffer.writeln();

    // Column Headers
    final visibleColumns = definition.columns.where((c) => c.isVisible).toList();
    final headerRow = visibleColumns.map((c) => '"${c.label.replaceAll('"', '""')}"').join(',');
    buffer.writeln(headerRow);

    // Data Rows
    for (final row in dataset.rows) {
      final rowValues = visibleColumns.map((col) {
        final val = row[col.id];
        if (val == null) return '""';
        final strVal = val.toString().replaceAll('"', '""');
        return '"$strVal"';
      }).join(',');
      buffer.writeln(rowValues);
    }

    // Write file to temp directory
    final tempDir = await getTemporaryDirectory();
    final fileName = '${definition.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), encoding: utf8);

    // Share / Open File
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: dataset.metadata.reportTitle,
    );

    return file;
  }
}
