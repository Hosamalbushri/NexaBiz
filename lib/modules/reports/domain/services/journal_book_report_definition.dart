import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/reporting/report_exception.dart';
import '../../../../core/reporting/report_pdf_theme.dart';
import '../../../../core/reporting/report_table.dart';
import '../services/journal_book_report_data_port.dart';
import '../services/report_definition.dart';

/// PDF builder for the journal-book (دفتر اليومية) report.
class JournalBookReportDefinition
    implements ReportDefinition<JournalBookReportPayload> {
  const JournalBookReportDefinition();

  @override
  String get id => 'journal_book';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required JournalBookReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final dateFmt = DateFormat('dd-MM-yyyy');
    final generated = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    final headers = <String>[
      payload.columnDate,
      payload.columnVoucher,
      payload.columnType,
      payload.columnDescription,
      payload.columnAccount,
      payload.columnDebit,
      payload.columnCredit,
    ];

    final rows = <List<String>>[
      for (final row in payload.rows)
        [
          dateFmt.format(row.entryDate.toLocal()),
          row.voucherNumber,
          row.voucherType,
          row.description,
          '${row.accountCode} — ${row.accountName}',
          money.format(row.debit),
          money.format(row.credit),
        ],
    ];

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(58),
      1: const pw.FixedColumnWidth(62),
      2: const pw.FixedColumnWidth(52),
      3: const pw.FlexColumnWidth(2.2),
      4: const pw.FlexColumnWidth(2.0),
      5: const pw.FixedColumnWidth(68),
      6: const pw.FixedColumnWidth(68),
    };

    final currencySuffix = (payload.baseCurrencyCode ?? '').trim().isEmpty
        ? ''
        : ' (${payload.baseCurrencyCode!.trim()})';

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
              headerFontSize: 7,
              cellFontSize: 7,
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
                        '${payload.totalsLabel}$currencySuffix',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${money.format(payload.totalsDebit)}  /  ${money.format(payload.totalsCredit)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (payload.fromDate != null || payload.toDate != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${payload.fromDate == null ? '…' : dateFmt.format(payload.fromDate!.toLocal())}'
                      ' → '
                      '${payload.toDate == null ? '…' : dateFmt.format(payload.toDate!.toLocal())}',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
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
