import '../../domain/entities/product.dart';
import '../../domain/repositories/barcode_label_printer.dart';

/// Placeholder thermal printer — UI can call [supportsThermal] before invoking.
class ThermalBarcodeLabelPrinter implements BarcodeLabelPrinter {
  const ThermalBarcodeLabelPrinter();

  @override
  bool get supportsThermal => false;

  @override
  Future<void> printLabel(Product product) {
    throw UnsupportedError('Use PdfBarcodeLabelPrinter for system print.');
  }

  @override
  Future<void> shareLabel(Product product) {
    throw UnsupportedError('Use PdfBarcodeLabelPrinter for share.');
  }

  @override
  Future<void> printThermal(Product product) {
    throw UnsupportedError('Thermal barcode printing is not available yet.');
  }
}
