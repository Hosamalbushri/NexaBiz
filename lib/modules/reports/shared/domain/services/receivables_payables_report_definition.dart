import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'receivables_payables_report_data_port.dart';
import 'report_definition.dart';

/// PDF builder for Receivables / Payables (ذمم العملاء والموردين) report.
class ReceivablesPayablesReportDefinition
    implements ReportDefinition<ReceivablesPayablesReportPayload> {
  const ReceivablesPayablesReportDefinition();

  @override
  String get id => 'receivables_payables';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required ReceivablesPayablesReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    final headers = <String>[
      payload.labels.columnEntityCode,
      payload.labels.columnEntityName,
      payload.labels.columnOpeningBalance,
      payload.labels.columnInvoices,
      payload.labels.columnPayments,
      payload.labels.columnEndingBalance,
    ];

    final rows = <List<String>>[
      for (final r in payload.rows)
        [
          r.entityCode,
          r.entityName,
          money.format(r.openingBalance),
          money.format(r.invoicesAmount),
          money.format(r.paymentsAmount),
          money.format(r.endingBalance),
        ],
    ];

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(70),
      1: const pw.FlexColumnWidth(2.5),
      2: const pw.FixedColumnWidth(70),
      3: const pw.FixedColumnWidth(70),
      4: const pw.FixedColumnWidth(70),
      5: const pw.FixedColumnWidth(75),
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
                  payload.labels.companyName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  payload.labels.reportTitle,
                  style: pw.TextStyle(
                    fontSize: ctx.pageNumber == 1 ? 16 : 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${payload.labels.periodLabel}  •  ${payload.labels.generatedAtLabel}: $generated  •  ${ctx.pageNumber}',
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
                  payload.labels.emptyMessage,
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
                    '${payload.labels.totalsLabel} (${payload.baseCurrencyCode})',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Opening: ${money.format(payload.totalOpening)} | Invoices: ${money.format(payload.totalInvoices)} | Payments: ${money.format(payload.totalPayments)} | Ending: ${money.format(payload.totalEnding)}',
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
