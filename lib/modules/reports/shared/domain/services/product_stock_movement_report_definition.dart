import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'product_stock_movement_report_data_port.dart';
import 'report_definition.dart';

/// PDF Generator definition for Product Stock Movement Report.
/// Replicates the exact visual grid, boxes, colors, and tabular structure
/// shown in the reference document image.
class ProductStockMovementReportDefinition
    implements ReportDefinition<ProductStockMovementReportPayload> {
  const ProductStockMovementReportDefinition();

  @override
  String get id => 'product_stock_movement';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required ProductStockMovementReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final dateFmt = DateFormat('dd-MM-yyyy');

    final fromStr = payload.fromDate != null ? dateFmt.format(payload.fromDate!) : payload.labels.periodAll;
    final toStr = payload.toDate != null ? dateFmt.format(payload.toDate!) : payload.labels.periodAll;

    final labels = payload.labels;
    final op = payload.openingBalance;

    doc.addPage(
      pw.MultiPage(
        maxPages: context.pageFormat.maxPages,
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        header: (ctx) {
          return pw.Directionality(
            textDirection: context.textDirection,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Top Date Subtitle (Red text centered)
                pw.Text(
                  '${labels.periodLabel} $fromStr ${labels.periodAll == fromStr ? '' : 'الى تاريخ'} $toStr',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
                pw.SizedBox(height: 8),

                // Top Info Header Box
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600, width: 1),
                    color: PdfColors.grey100,
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Row(
                    children: [
                      // 1. Warehouse Name Box
                      pw.Container(
                        width: 90,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(labels.warehouseLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            pw.Text(payload.warehouseName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 6),

                      // 2. Product Information Box
                      pw.Expanded(
                        flex: 4,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                color: PdfColors.grey200,
                                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                                width: double.infinity,
                                child: pw.Text('بيانات الصنف', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                                children: [
                                  pw.Column(
                                    children: [
                                      pw.Text(labels.productCodeLabel, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                                      pw.Text(payload.productCode, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                    ],
                                  ),
                                  pw.Column(
                                    children: [
                                      pw.Text(labels.productNameLabel, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                                      pw.Text(payload.productName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),

                      // 3. Opening Balance Box
                      pw.Container(
                        width: 160,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              color: PdfColors.grey200,
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              width: double.infinity,
                              child: pw.Text(labels.openingBalanceLabel, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                              children: [
                                _boxHeaderValue(labels.cartonLabel, '${op.cartons}'),
                                _boxHeaderValue(labels.pieceLabel, '${op.pieces.toStringAsFixed(0)}'),
                                _boxHeaderValue(labels.finalQtyLabel, '${op.totalQty.toStringAsFixed(0)}'),
                                _boxHeaderValue(labels.costLabel, '${op.totalCost.toStringAsFixed(0)}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 6),

                      // 4. Unit Capacity Box
                      pw.Container(
                        width: 100,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${labels.mainCapacityLabel}: ${payload.mainUnitCapacity}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            pw.Text('${labels.subCapacityLabel}: ${payload.subUnitCapacity}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
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
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          );
        },
        build: (ctx) {
          return [
            pw.Directionality(
              textDirection: context.textDirection,
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
                children: [
                  // Group Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('بيانات المستند', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(labels.inwardHeaderLabel, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(labels.outwardHeaderLabel, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(labels.endingBalanceHeaderLabel, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Detailed Movements Table
            pw.Directionality(
              textDirection: context.textDirection,
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
                columnWidths: const {
                  0: pw.FixedColumnWidth(55),  // Date
                  1: pw.FixedColumnWidth(60),  // Doc Type
                  2: pw.FixedColumnWidth(65),  // Voucher
                  3: pw.FixedColumnWidth(40),  // Doc Num
                  4: pw.FixedColumnWidth(28),  // In Carton
                  5: pw.FixedColumnWidth(28),  // In Piece
                  6: pw.FixedColumnWidth(30),  // In Final
                  7: pw.FixedColumnWidth(45),  // In Cost
                  8: pw.FixedColumnWidth(28),  // Out Carton
                  9: pw.FixedColumnWidth(28),  // Out Piece
                  10: pw.FixedColumnWidth(30), // Out Final
                  11: pw.FixedColumnWidth(45), // Out Cost
                  12: pw.FixedColumnWidth(28), // Bal Carton
                  13: pw.FixedColumnWidth(28), // Bal Piece
                  14: pw.FixedColumnWidth(30), // Bal Final
                  15: pw.FixedColumnWidth(45), // Bal Cost
                },
                children: [
                  // Sub Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cellHeader(labels.docDateLabel),
                      _cellHeader(labels.docTypeLabel),
                      _cellHeader(labels.voucherBookLabel),
                      _cellHeader(labels.docNumLabel),
                      _cellHeader(labels.cartonLabel),
                      _cellHeader(labels.pieceLabel),
                      _cellHeader(labels.finalQtyLabel),
                      _cellHeader(labels.costLabel),
                      _cellHeader(labels.cartonLabel),
                      _cellHeader(labels.pieceLabel),
                      _cellHeader(labels.finalQtyLabel),
                      _cellHeader(labels.costLabel),
                      _cellHeader(labels.cartonLabel),
                      _cellHeader(labels.pieceLabel),
                      _cellHeader(labels.finalQtyLabel),
                      _cellHeader(labels.costLabel),
                    ],
                  ),

                  // Data Rows
                  for (final row in payload.rows)
                    pw.TableRow(
                      children: [
                        _cellText(dateFmt.format(row.documentDate), color: PdfColors.red800, isBold: true),
                        _cellText(row.documentType),
                        _cellText(row.voucherBook),
                        _cellText(row.documentNumber, isBold: true),

                        // Inward
                        _cellText('${row.inCartons}'),
                        _cellText('${row.inPieces.toStringAsFixed(0)}'),
                        _cellText('${row.inTotalQty.toStringAsFixed(0)}'),
                        _cellText(row.inCost > 0 ? row.unitCost.toStringAsFixed(0) : '0', isBold: row.inCost > 0),

                        // Outward
                        _cellText('${row.outCartons}'),
                        _cellText('${row.outPieces.toStringAsFixed(0)}'),
                        _cellText('${row.outTotalQty.toStringAsFixed(0)}'),
                        _cellText(row.outCost > 0 ? row.unitCost.toStringAsFixed(0) : '0', isBold: row.outCost > 0),

                        // Ending Balance
                        _cellText('${row.balanceCartons}'),
                        _cellText('${row.balancePieces.toStringAsFixed(0)}'),
                        _cellText('${row.balanceTotalQty.toStringAsFixed(0)}'),
                        _cellText('${row.unitCost.toStringAsFixed(0)}', isBold: true),
                      ],
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Footer Totals Row
            pw.Directionality(
              textDirection: context.textDirection,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                  color: PdfColors.grey100,
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      '${labels.totalIncomingCostLabel}:  ${payload.totalIncomingCost.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${labels.totalOutgoingCostLabel}:  ${payload.totalOutgoingCost.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
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

  pw.Widget _boxHeaderValue(String title, String val) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
        pw.Text(val, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _cellText(String text, {PdfColor color = PdfColors.black, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
