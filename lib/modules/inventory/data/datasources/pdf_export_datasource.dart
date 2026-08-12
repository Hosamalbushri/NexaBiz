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
  /// Large “all items” / “not counted” exports can exceed the MultiPage default (20).
  static const int _maxPages = 2000;

  Future<String> export({
    required List<InventoryItem> items,
    required ReportExportLabels labels,
  }) async {
    final baseFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();
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

    final resolvedHeaders = labels.isRtl
        ? headers.reversed.toList(growable: false)
        : headers;
    final resolvedWidths = labels.isRtl
        ? <int, pw.TableColumnWidth>{
            for (var i = 0; i < columnWidths.length; i++)
              i: columnWidths[columnWidths.length - 1 - i]!,
          }
        : columnWidths;

    final data = <List<String>>[
      for (final item in items)
        _rowCells(item: item, labels: labels, isRtl: labels.isRtl),
    ];

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
          // Table must be a MultiPage child that can split across pages.
          // Nesting it in Column was causing TooManyPages for large filters.
          pw.TableHelper.fromTextArray(
            headers: resolvedHeaders,
            data: data,
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
            columnWidths: resolvedWidths,
            cellDecoration: (index, data, rowNum) {
              final itemIndex = rowNum - 1; // header occupies row 0
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

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path =
        '${directory.path}/inventory_report_${labels.localeCode}_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await document.save(), flush: true);
    return path;
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
