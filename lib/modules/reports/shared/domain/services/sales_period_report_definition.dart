import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import '../services/report_definition.dart';
import '../services/sales_period_report_data_port.dart';

/// PDF builder for the sales-period list report.
class SalesPeriodReportDefinition
    implements ReportDefinition<SalesPeriodReportPayload> {
  const SalesPeriodReportDefinition();

  @override
  String get id => 'sales_period';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required SalesPeriodReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    // Pattern-based formats avoid intl locale data init (PDF has no Flutter Localizations).
    final dateFmt = DateFormat('dd-MM-yyyy');
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

    final headers = <String>[
      payload.columnSaleNumber,
      payload.columnDate,
      payload.columnCustomer,
      payload.columnSettlement,
      payload.columnStatus,
      payload.columnCurrency,
      payload.columnTotal,
    ];

    final rows = <List<String>>[
      for (final row in payload.rows)
        [
          row.saleNumber,
          dateFmt.format(row.saleDate.toLocal()),
          row.customerName?.trim().isNotEmpty == true
              ? row.customerName!.trim()
              : '—',
          row.settlementLabel,
          row.statusLabel,
          row.currencyCode,
          row.total.toStringAsFixed(2),
        ],
    ];

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(64),
      1: const pw.FixedColumnWidth(72),
      2: const pw.FlexColumnWidth(2.2),
      3: const pw.FixedColumnWidth(56),
      4: const pw.FixedColumnWidth(64),
      5: const pw.FixedColumnWidth(44),
      6: const pw.FixedColumnWidth(64),
    };

    doc.addPage(
      pw.MultiPage(
        maxPages: context.pageFormat.maxPages,
        pageTheme: context.pageFormat.toPageTheme(
          theme: context.theme,
          textDirection: context.textDirection,
        ),
        header: (ctx) {
          return pw.Directionality(
            textDirection: context.textDirection,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  payload.companyName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  payload.reportTitle,
                  style: pw.TextStyle(
                    fontSize: ctx.pageNumber == 1 ? 16 : 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${payload.periodLabel}  •  ${payload.generatedAtLabel}: $generated  •  ${ctx.pageNumber}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
              ],
            ),
          );
        },
        footer: (ctx) {
          return pw.Directionality(
            textDirection: context.textDirection,
            child: pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          );
        },
        build: (ctx) {
          if (payload.rows.isEmpty) {
            return [
              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  payload.emptyMessage ?? '',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ];
          }
          return [
            ReportTable.fromStringGrid(
              headers: headers,
              rows: rows,
              columnWidths: widths,
              isRtl: context.isRtl,
              headerFontSize: 8,
              cellFontSize: 8,
            ),
            pw.SizedBox(height: 12),
            pw.Directionality(
              textDirection: context.textDirection,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${payload.rowsLabel}: ${payload.rows.length}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${payload.totalLabel}: ${payload.grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();
    if (bytes.isEmpty) {
      throw const ReportException(ReportException.generationFailed);
    }
    return Uint8List.fromList(bytes);
  }
}
