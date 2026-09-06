import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'income_statement_report_data_port.dart';
import 'report_definition.dart';

/// PDF builder for the Income Statement / P&L (قائمة الدخل) report.
class IncomeStatementReportDefinition
    implements ReportDefinition<IncomeStatementReportPayload> {
  const IncomeStatementReportDefinition();

  @override
  String get id => 'income_statement';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required IncomeStatementReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    final headers = <String>[
      payload.labels.accountCodeLabel,
      payload.labels.accountNameLabel,
      payload.labels.amountLabel,
    ];

    final rows = <List<String>>[];

    // Revenue Section
    rows.add([
      '—',
      '=== ${payload.labels.revenueHeader} ===',
      money.format(payload.totalRevenue),
    ]);
    for (final r in payload.revenueItems) {
      rows.add([r.accountCode, r.accountName, money.format(r.amount)]);
    }

    // COGS Section
    rows.add([
      '—',
      '=== ${payload.labels.cogsHeader} ===',
      money.format(payload.totalCogs),
    ]);
    for (final r in payload.cogsItems) {
      rows.add([r.accountCode, r.accountName, money.format(r.amount)]);
    }

    // Gross Profit Line
    rows.add([
      '—',
      '>>> ${payload.labels.grossProfitLabel} <<<',
      money.format(payload.grossProfit),
    ]);

    // Expenses Section
    rows.add([
      '—',
      '=== ${payload.labels.operatingExpensesHeader} ===',
      money.format(payload.totalExpenses),
    ]);
    for (final r in payload.expenseItems) {
      rows.add([r.accountCode, r.accountName, money.format(r.amount)]);
    }

    // Net Profit Line
    final netLabel = payload.netProfit >= 0
        ? payload.labels.netProfitLabel
        : payload.labels.netLossLabel;
    rows.add(['—', '*** $netLabel ***', money.format(payload.netProfit)]);

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(80),
      1: const pw.FlexColumnWidth(3.0),
      2: const pw.FixedColumnWidth(100),
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
                    '$netLabel (${payload.baseCurrencyCode})',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    money.format(payload.netProfit),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: payload.netProfit >= 0
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
