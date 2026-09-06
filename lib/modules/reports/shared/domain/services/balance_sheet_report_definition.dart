import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'balance_sheet_report_data_port.dart';
import 'report_definition.dart';

/// PDF builder for the Balance Sheet (الميزانية العمومية) report.
class BalanceSheetReportDefinition
    implements ReportDefinition<BalanceSheetReportPayload> {
  const BalanceSheetReportDefinition();

  @override
  String get id => 'balance_sheet';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required BalanceSheetReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    final headers = <String>['Code', 'Account', 'Amount'];
    final rows = <List<String>>[];

    // Assets
    rows.add(['—', '=== ${payload.labels.assetsHeader} ===', money.format(payload.totalAssets)]);
    for (final a in payload.assetItems) {
      rows.add([a.accountCode, a.accountName, money.format(a.amount)]);
    }

    // Liabilities
    rows.add(['—', '=== ${payload.labels.liabilitiesHeader} ===', money.format(payload.totalLiabilities)]);
    for (final l in payload.liabilityItems) {
      rows.add([l.accountCode, l.accountName, money.format(l.amount)]);
    }

    // Equity
    rows.add(['—', '=== ${payload.labels.equityHeader} ===', money.format(payload.totalEquity)]);
    for (final e in payload.equityItems) {
      rows.add([e.accountCode, e.accountName, money.format(e.amount)]);
    }
    rows.add(['—', payload.labels.retainedEarningsLabel, money.format(payload.retainedEarnings)]);

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(80),
      1: const pw.FlexColumnWidth(3.0),
      2: const pw.FixedColumnWidth(100),
    };

    final balanceNote = payload.isBalanced
        ? payload.labels.balancedLabel
        : payload.labels.unbalancedLabel;

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
                  '${payload.labels.asOfDateLabel}  •  ${payload.labels.generatedAtLabel}: $generated  •  ${ctx.pageNumber}',
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
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${payload.labels.totalAssetsLabel}: ${money.format(payload.totalAssets)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${payload.labels.totalLiabilitiesAndEquityLabel}: ${money.format(payload.totalLiabilitiesAndEquity)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    balanceNote,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: payload.isBalanced
                          ? PdfColors.green800
                          : PdfColors.red800,
                    ),
                    textAlign: pw.TextAlign.center,
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
