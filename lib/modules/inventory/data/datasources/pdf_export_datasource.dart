import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/reporting/report_fonts.dart';
import '../../../../core/reporting/report_table.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../../domain/models/report_export_labels.dart';

/// Builds inventory report PDFs (shared reporting fonts / table helpers).
class PdfExportDatasource {
  /// Large “all items” / “not counted” exports can exceed the MultiPage default (20).
  static const int _maxPages = 2000;

  /// Builds PDF bytes for in-app preview (reports kit).
  Future<({Uint8List bytes, String fileName})> buildPdf({
    required List<InventoryItem> items,
    required ReportExportLabels labels,
  }) async {
    final (baseFont, boldFont) = await _loadReportFonts();
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final textDirection = labels.isRtl
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;

    final document = pw.Document(theme: theme);
    final generated = DateTime.now();
    final generatedText = '${labels.generatedAt}: ${generated.toLocal()}'
        .split('.')
        .first;

    final headers = <String>[
      labels.code,
      labels.name,
      labels.systemMainQuantity,
      labels.systemSubQuantity,
      labels.countedMainQuantity,
      labels.countedSubQuantity,
      labels.varianceMainQuantity,
      labels.varianceSubQuantity,
      labels.status,
    ];

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(50),
      1: const pw.FlexColumnWidth(2.4),
      2: const pw.FixedColumnWidth(58),
      3: const pw.FixedColumnWidth(58),
      4: const pw.FixedColumnWidth(58),
      5: const pw.FixedColumnWidth(58),
      6: const pw.FixedColumnWidth(58),
      7: const pw.FixedColumnWidth(58),
      8: const pw.FixedColumnWidth(56),
    };

    final resolved = ReportTable.resolveRtl(
      headers: headers,
      rows: [
        for (final item in items)
          _rowCells(item: item, labels: labels, isRtl: false),
      ],
      widths: columnWidths,
      isRtl: labels.isRtl,
    );

    document.addPage(
      pw.MultiPage(
        maxPages: _maxPages,
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(18),
          theme: theme,
          textDirection: textDirection,
        ),
        header: (context) {
          return pw.Directionality(
            textDirection: textDirection,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  labels.reportTitle,
                  style: pw.TextStyle(
                    fontSize: context.pageNumber == 1 ? 18 : 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  textDirection: textDirection,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${labels.reportSection}: ${labels.filterLabel}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  textDirection: textDirection,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${labels.totalItems}: ${items.length}  •  $generatedText'
                  '  •  ${context.pageNumber}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                  textDirection: textDirection,
                ),
                pw.SizedBox(height: 10),
              ],
            ),
          );
        },
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: resolved.headers,
            data: resolved.rows,
            headerDirection: textDirection,
            tableDirection: textDirection,
            headerStyle: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerAlignment: labels.isRtl
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            cellAlignment: labels.isRtl
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 4,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
            columnWidths: resolved.widths,
            cellDecoration: (index, data, rowNum) {
              final itemIndex = rowNum - 1;
              if (itemIndex < 0 || itemIndex >= items.length) {
                return const pw.BoxDecoration();
              }
              final color = _statusRowColor(items[itemIndex].status);
              if (color == null) {
                return const pw.BoxDecoration();
              }
              return pw.BoxDecoration(color: color);
            },
          ),
        ],
      ),
    );

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'inventory_report_${labels.localeCode}_$timestamp.pdf';
    final bytes = await document.save();
    return (bytes: bytes, fileName: fileName);
  }

  /// Writes PDF to app documents and returns the path (Excel print fallback).
  Future<String> export({
    required List<InventoryItem> items,
    required ReportExportLabels labels,
  }) async {
    final prepared = await buildPdf(items: items, labels: labels);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${prepared.fileName}';
    final file = File(path);
    await file.writeAsBytes(prepared.bytes, flush: true);
    return path;
  }

  /// Prefer Amiri (reports kit); fall back to Helvetica when fonts fail.
  Future<(pw.Font, pw.Font)> _loadReportFonts() async {
    try {
      return await ReportFontLoader.loadAmiri();
    } catch (_) {
      return (pw.Font.helvetica(), pw.Font.helveticaBold());
    }
  }

  List<String> _rowCells({
    required InventoryItem item,
    required ReportExportLabels labels,
    required bool isRtl,
  }) {
    final cells = <String>[
      item.itemCode,
      item.itemName,
      _formatQuantity(item.systemMainQuantity),
      _formatQuantity(item.systemSubQuantity),
      _formatQuantity(item.mainQuantity),
      _formatQuantity(item.subQuantity),
      item.isCounted ? _formatSigned(item.differenceMainQuantity) : '-',
      item.isCounted ? _formatSigned(item.differenceSubQuantity) : '-',
      labels.statusLabel(item.status),
    ];
    return isRtl ? cells.reversed.toList(growable: false) : cells;
  }

  PdfColor? _statusRowColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.shortage:
        return PdfColors.orange100;
      case ItemStatus.overage:
        return PdfColors.lightBlue100;
      case ItemStatus.matched:
        return PdfColors.green50;
      case ItemStatus.notCounted:
        return PdfColors.grey100;
    }
  }

  String _formatSigned(double value) {
    final absValue = value.abs();
    final formatted = absValue == absValue.roundToDouble()
        ? absValue.toInt().toString()
        : absValue.toStringAsFixed(2);
    if (value > 0) {
      return '+$formatted';
    }
    if (value < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  String _formatQuantity(double? value) {
    if (value == null) {
      return '-';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
