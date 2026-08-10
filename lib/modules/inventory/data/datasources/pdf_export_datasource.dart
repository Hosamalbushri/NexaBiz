import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import '../../domain/models/report_export_labels.dart';

/// Exports inventory report data to a localized PDF document.
class PdfExportDatasource {
  Future<String> export({
    required List<InventoryItem> items,
    required ReportExportLabels labels,
  }) async {
    final baseFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();
    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final textDirection =
        labels.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final document = pw.Document(theme: theme);
    final generated = DateTime.now();
    final generatedText =
        '${labels.generatedAt}: ${generated.toLocal()}'.split('.').first;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(18),
          theme: theme,
          textDirection: textDirection,
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: textDirection,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  labels.reportTitle,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  textDirection: textDirection,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '${labels.reportSection}: ${labels.filterLabel}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  textDirection: textDirection,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${labels.totalItems}: ${items.length}  •  $generatedText',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                  textDirection: textDirection,
                ),
                pw.SizedBox(height: 16),
                _buildItemsTable(
                  items: items,
                  labels: labels,
                  textDirection: textDirection,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path =
        '${directory.path}/inventory_report_${labels.localeCode}_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await document.save(), flush: true);
    return path;
  }

  pw.Widget _buildItemsTable({
    required List<InventoryItem> items,
    required ReportExportLabels labels,
    required pw.TextDirection textDirection,
  }) {
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

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(50),
      1: const pw.FixedColumnWidth(130),
      2: const pw.FixedColumnWidth(62),
      3: const pw.FixedColumnWidth(62),
      4: const pw.FixedColumnWidth(62),
      5: const pw.FixedColumnWidth(62),
      6: const pw.FixedColumnWidth(62),
      7: const pw.FixedColumnWidth(62),
      8: const pw.FixedColumnWidth(60),
    };

    final headerCells = [
      for (final header in headers) _headerCell(header, textDirection),
    ];

    final bodyRows = <pw.TableRow>[
      for (final item in items)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _statusRowColor(item.status),
          ),
          children: [
            _bodyCell(item.itemCode, textDirection),
            _nameCell(item.itemName, textDirection),
            _bodyCell(_formatQuantity(item.systemMainQuantity), textDirection),
            _bodyCell(_formatQuantity(item.systemSubQuantity), textDirection),
            _bodyCell(_formatQuantity(item.mainQuantity), textDirection),
            _bodyCell(_formatQuantity(item.subQuantity), textDirection),
            _bodyCell(
              item.isCounted
                  ? _formatSigned(item.differenceMainQuantity)
                  : '-',
              textDirection,
              bold: true,
            ),
            _bodyCell(
              item.isCounted
                  ? _formatSigned(item.differenceSubQuantity)
                  : '-',
              textDirection,
              bold: true,
            ),
            _bodyCell(labels.statusLabel(item.status), textDirection),
          ],
        ),
    ];

    final resolvedWidths = labels.isRtl
        ? <int, pw.TableColumnWidth>{
            for (var i = 0; i < widths.length; i++)
              i: widths[widths.length - 1 - i]!,
          }
        : widths;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: resolvedWidths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: labels.isRtl ? headerCells.reversed.toList() : headerCells,
        ),
        for (final row in bodyRows)
          pw.TableRow(
            decoration: row.decoration,
            children: labels.isRtl
                ? row.children.reversed.toList()
                : row.children,
          ),
      ],
    );
  }

  pw.Widget _headerCell(String text, pw.TextDirection textDirection) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
        textAlign: textDirection == pw.TextDirection.rtl
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        textDirection: textDirection,
      ),
    );
  }

  pw.Widget _bodyCell(
    String text,
    pw.TextDirection textDirection, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: textDirection == pw.TextDirection.rtl
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        textDirection: textDirection,
      ),
    );
  }

  pw.Widget _nameCell(String text, pw.TextDirection textDirection) {
    return pw.Container(
      width: 130,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7.5),
        softWrap: true,
        textAlign: textDirection == pw.TextDirection.rtl
            ? pw.TextAlign.right
            : pw.TextAlign.left,
        textDirection: textDirection,
      ),
    );
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
