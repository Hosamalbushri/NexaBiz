import 'dart:io';
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/barcode_label_printer.dart';

/// Builds a small Code128 PDF label and prints/shares it via the OS.
class PdfBarcodeLabelPrinter implements BarcodeLabelPrinter {
  const PdfBarcodeLabelPrinter();

  @override
  bool get supportsThermal => false;

  @override
  Future<void> printThermal(Product product) {
    throw UnsupportedError('Thermal barcode printing is not available yet.');
  }

  /// Prefer ASCII-safe Code128; fall back to Code39 when needed.
  Barcode _barcodeFor(String value) {
    final code128 = Barcode.code128();
    if (code128.isValid(value)) {
      return code128;
    }
    final code39 = Barcode.code39();
    if (code39.isValid(value)) {
      return code39;
    }
    return code128;
  }

  Future<Uint8List> _buildPdf(Product product) async {
    final barcodeValue = product.barcode?.trim();
    if (barcodeValue == null || barcodeValue.isEmpty) {
      throw StateError('Product has no barcode to print.');
    }

    // Vector barcode only — no product name / item code on the label.
    final barcode = _barcodeFor(barcodeValue);
    final svg = barcode.toSvg(
      barcodeValue,
      width: 320,
      height: 110,
      drawText: true,
      fontHeight: 16,
      textPadding: 6,
    );

    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          40 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Center(
            child: pw.SvgImage(
              svg: svg,
              width: 72 * PdfPageFormat.mm,
              height: 32 * PdfPageFormat.mm,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );
    return document.save();
  }

  @override
  Future<void> printLabel(Product product) async {
    final bytes = await _buildPdf(product);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'barcode_${product.itemCode}',
    );
  }

  @override
  Future<void> shareLabel(Product product) async {
    final bytes = await _buildPdf(product);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/barcode_${product.itemCode}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: product.name,
        text: '${product.itemCode} · ${product.barcode}',
      ),
    );
  }
}
