import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'report_definition.dart';
import 'rp_report_data_port.dart';

class RpTransactionReportDefinition
    implements ReportDefinition<RpReportPayload> {
  const RpTransactionReportDefinition();

  @override
  String get id => 'receipts_payments_transactions';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required RpReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final dateFmt = DateFormat('dd-MM-yyyy');
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final isRtl = context.textDirection == pw.TextDirection.rtl;

    final headers = <String>[
      payload.columnNumber,
      payload.columnDate,
      payload.columnType,
      payload.columnParty,
      payload.columnStatus,
      payload.columnAmount,
    ];

    final rows = <List<String>>[
      for (final row in payload.rows)
        [
          row.transactionNumber,
          dateFmt.format(row.transactionDate.toLocal()),
          row.typeLabel,
          row.partyLabel,
          row.statusLabel,
          '${row.amount.toStringAsFixed(2)} ${row.currencyCode}',
        ],
    ];

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(64),
      1: const pw.FixedColumnWidth(72),
      2: const pw.FixedColumnWidth(56),
      3: const pw.FlexColumnWidth(2),
      4: const pw.FixedColumnWidth(56),
      5: const pw.FixedColumnWidth(80),
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
                pw.SizedBox(height: 8),
                pw.Text(
                  '${payload.totalLabel}: ${payload.totalAmount.toStringAsFixed(2)}  •  ${payload.countLabel}: ${payload.totalCount}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (payload.truncatedNote != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    payload.truncatedNote!,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
                pw.SizedBox(height: 8),
              ],
            ),
          );
        },
        build: (ctx) {
          return [
            pw.Directionality(
              textDirection: context.textDirection,
              child: ReportTable.fromStringGrid(
                headers: headers,
                rows: rows,
                columnWidths: widths,
                isRtl: isRtl,
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }
}
