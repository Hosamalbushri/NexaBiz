import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'cash_flow_report_data_port.dart';
import 'report_definition.dart';

/// PDF builder for the Cash Flow (التدفقات النقدية) report.
class CashFlowReportDefinition
    implements ReportDefinition<CashFlowReportPayload> {
  const CashFlowReportDefinition();

  @override
  String get id => 'cash_flow';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required CashFlowReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    final headers = <String>[
      payload.labels.accountCodeLabel,
      payload.labels.accountNameLabel,
      payload.labels.inflowLabel,
      payload.labels.outflowLabel,
      payload.labels.netFlowLabel,
    ];

    final rows = <List<String>>[];

    // Opening Balance
    rows.add([
      '—',
      '=== ${payload.labels.openingCashLabel} ===',
      '—',
      '—',
      money.format(payload.openingCashBalance),
    ]);

    // Operations
    rows.add([
      '—',
      '=== ${payload.labels.operatingActivitiesHeader} ===',
      '—',
      '—',
      '—',
    ]);
    for (final item in payload.operatingItems) {
      rows.add([
        item.accountCode,
        item.accountName,
        money.format(item.inflow),
        money.format(item.outflow),
        money.format(item.netFlow),
      ]);
    }

    // Ending Balance
    rows.add([
      '—',
      '=== ${payload.labels.endingCashLabel} ===',
      '—',
      '—',
      money.format(payload.endingCashBalance),
    ]);

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(70),
      1: const pw.FlexColumnWidth(2.5),
      2: const pw.FixedColumnWidth(70),
      3: const pw.FixedColumnWidth(70),
      4: const pw.FixedColumnWidth(75),
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
                    '${payload.labels.netCashMovementLabel} (${payload.baseCurrencyCode})',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    money.format(payload.netCashChange),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: payload.netCashChange >= 0
                          ? PdfColors.green800
                          : PdfColors.red800,
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
