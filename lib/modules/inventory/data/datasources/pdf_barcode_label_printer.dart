import 'dart:io';
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/product.dart';
import '../../domain/models/product_code_format.dart';
import '../../domain/repositories/barcode_label_printer.dart';
import '../../domain/services/product_qr_payload_builder.dart';

/// Builds a small Code128 or QR PDF label and prints/shares it via the OS.
class PdfBarcodeLabelPrinter implements BarcodeLabelPrinter {
  const PdfBarcodeLabelPrinter({
    this.qrPayloadBuilder = const ProductQrPayloadBuilder(),
  });

  final ProductQrPayloadBuilder qrPayloadBuilder;

  @override
  bool get supportsThermal => false;

  @override
  Future<void> printThermal(Product product) {
    throw UnsupportedError('Thermal barcode printing is not available yet.');
  }

  /// Prefer ASCII-safe Code128; fall back to Code39 when needed.
  Barcode _linearBarcodeFor(String value) {
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

  Future<Uint8List> _buildPdf(
    Product product, {
    required ProductCodeFormat format,
  }) async {
    final String svg;
    final PdfPageFormat pageFormat;
    final double imageWidthMm;
    final double imageHeightMm;

    switch (format) {
      case ProductCodeFormat.barcode:
        final barcodeValue = product.barcode?.trim();
        if (barcodeValue == null || barcodeValue.isEmpty) {
          throw StateError('Product has no barcode to print.');
        }
        // Vector barcode only — no product name / item code on the label.
        svg = _linearBarcodeFor(barcodeValue).toSvg(
          barcodeValue,
          width: 320,
          height: 110,
          drawText: true,
          fontHeight: 16,
          textPadding: 6,
        );
        pageFormat = const PdfPageFormat(
          80 * PdfPageFormat.mm,
          40 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        );
        imageWidthMm = 72 * PdfPageFormat.mm;
        imageHeightMm = 32 * PdfPageFormat.mm;
      case ProductCodeFormat.qrCode:
        final payload = qrPayloadBuilder.build(product);
        svg = Barcode.qrCode(
          errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
        ).toSvg(payload, width: 220, height: 220, drawText: false);
        pageFormat = const PdfPageFormat(
          50 * PdfPageFormat.mm,
          50 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        );
        imageWidthMm = 42 * PdfPageFormat.mm;
        imageHeightMm = 42 * PdfPageFormat.mm;
    }

    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Center(
            child: pw.SvgImage(
              svg: svg,
              width: imageWidthMm,
              height: imageHeightMm,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );
    return document.save();
  }

  @override
  Future<void> printLabel(
    Product product, {
    ProductCodeFormat format = ProductCodeFormat.barcode,
  }) async {
    final bytes = await _buildPdf(product, format: format);
    final prefix = format == ProductCodeFormat.qrCode ? 'qr' : 'barcode';
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${prefix}_${product.itemCode}',
    );
  }

  @override
  Future<void> shareLabel(
    Product product, {
    ProductCodeFormat format = ProductCodeFormat.barcode,
  }) async {
    final bytes = await _buildPdf(product, format: format);
    final prefix = format == ProductCodeFormat.qrCode ? 'qr' : 'barcode';
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${prefix}_${product.itemCode}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    final barcode = product.barcode?.trim();
    final shareText = format == ProductCodeFormat.qrCode
        ? '${product.itemCode} · ${product.name}'
        : '${product.itemCode} · ${barcode ?? ''}';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: product.name,
        text: shareText,
      ),
    );
  }
}
