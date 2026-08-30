import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/reporting/pdf_document_preview_page.dart';
import '../../../core/reporting/report_pdf_theme.dart';
import '../../../modules/reports/shared/presentation/pages/reports_routes.dart';
import 'package:stock_count/core/report_engine/domain/models/report_dataset.dart';
import 'package:stock_count/core/report_engine/domain/models/report_definition_spec.dart';


/// PDF Exporter driver for the NexaBiz ERP Universal Report Engine.
class PdfReportExporter {
  /// Builds PDF document bytes for any report definition and dataset.
  static Future<Uint8List> generatePdf({
    required ReportDefinitionSpec definition,
    required ReportDataset dataset,
    required String companyName,
    bool isRtl = true,
  }) async {
    final pdfContext = await ReportPdfContext.create(
      isRtl: isRtl,
      localeCode: isRtl ? 'ar' : 'en',
    );

    final doc = pw.Document(theme: pdfContext.theme);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final visibleColumns = definition.columns.where((c) => c.isVisible).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (ctx) {
          return pw.Directionality(
            textDirection: pdfContext.textDirection,
            child: pw.Column(
              children: [
                // Company & Report Title Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          definition.name,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'تاريخ الطباعة: ${dateFmt.format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'إجمالي السجلات: ${dataset.rows.length}',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Header Info KPI Cards (if present)
                if (dataset.headerCards.isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: dataset.headerCards.map((card) {
                        return pw.Column(
                          children: [
                            pw.Text(card.title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            pw.Text(card.value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                            if (card.subValue != null)
                              pw.Text(card.subValue!, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
        footer: (ctx) {
          return pw.Directionality(
            textDirection: pdfContext.textDirection,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NexaBiz ERP — Unified Reporting System', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          );
        },
        build: (ctx) {
          return [
            pw.Directionality(
              textDirection: pdfContext.textDirection,
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
                children: [
                  // Table Column Headers
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: visibleColumns.map((col) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          col.label,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                  // Table Rows
                  for (int i = 0; i < dataset.rows.length; i++)
                    pw.TableRow(
                      decoration: i % 2 == 1 ? const pw.BoxDecoration(color: PdfColors.grey50) : null,
                      children: visibleColumns.map((col) {
                        final val = dataset.rows[i][col.id]?.toString() ?? '';
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            val,
                            textAlign: col.isNumeric ? pw.TextAlign.right : pw.TextAlign.left,
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        );
                      }).toList(),
                    ),
                  // Footer Summaries (if present)
                  if (dataset.summaryTotals.isNotEmpty)
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: visibleColumns.map((col) {
                        final summary = dataset.summaryTotals.firstWhere(
                          (s) => s.columnId == col.id,
                          orElse: () => const ReportSummaryData(label: '', value: ''),
                        );
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            summary.value.isNotEmpty ? '${summary.label}: ${summary.value}' : '',
                            textAlign: col.isNumeric ? pw.TextAlign.right : pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),

                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();
    return Uint8List.fromList(bytes);
  }

  /// Opens the standard NexaBiz PDF Print Preview page.
  static Future<void> openPrintPreview({
    required BuildContext context,
    required ReportDefinitionSpec definition,
    required ReportDataset dataset,
    required String companyName,
  }) async {
    final pdfBytes = await generatePdf(
      definition: definition,
      dataset: dataset,
      companyName: companyName,
    );

    PdfDocumentPreviewArgs.holder = PdfDocumentPreviewArgs(
      bytes: pdfBytes,
      title: definition.name,
      fileName: '${definition.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (context.mounted) {
      await context.push(ReportsRoutes.preview);
    }
  }
}
