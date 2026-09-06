import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'general_ledger_report_data_port.dart';
import 'report_definition.dart';

/// PDF builder for the General Ledger (الأستاذ العام) report.
class GeneralLedgerReportDefinition
    implements ReportDefinition<GeneralLedgerReportPayload> {
  const GeneralLedgerReportDefinition();

  @override
  String get id => 'general_ledger';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required GeneralLedgerReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final dateFmt = DateFormat('dd-MM-yyyy');
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    final headers = <String>[
      payload.labels.columnDate,
      payload.labels.columnVoucher,
      payload.labels.columnType,
      payload.labels.columnAccount,
      payload.labels.columnDescription,
      payload.labels.columnDebit,
      payload.labels.columnCredit,
      payload.labels.columnBalance,
    ];

    final rows = <List<String>>[];

    if (payload.openingBalance != 0) {
      rows.add([
        '—',
        '—',
        '—',
        '—',
        payload.labels.openingBalanceLabel,
        '—',
        '—',
        money.format(payload.openingBalance),
      ]);
    }

    for (final row in payload.rows) {
      rows.add([
        dateFmt.format(row.date.toLocal()),
        row.voucherNumber,
        row.voucherType,
        '${row.accountCode} - ${row.accountName}',
        row.description,
        row.debit > 0 ? money.format(row.debit) : '—',
        row.credit > 0 ? money.format(row.credit) : '—',
        money.format(row.runningBalance),
      ]);
    }

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(55),
      1: const pw.FixedColumnWidth(60),
      2: const pw.FixedColumnWidth(45),
      3: const pw.FlexColumnWidth(1.8),
      4: const pw.FlexColumnWidth(2.0),
      5: const pw.FixedColumnWidth(60),
      6: const pw.FixedColumnWidth(60),
      7: const pw.FixedColumnWidth(65),
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
              headerFontSize: 7,
              cellFontSize: 7,
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
                    '${money.format(payload.totalDebit)}  /  ${money.format(payload.totalCredit)}  |  Balance: ${money.format(payload.endingBalance)}',
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
