import '../../domain/entities/product.dart';

/// Port for printing / sharing product barcode labels.
///
/// PDF implementation is active now; thermal printers plug in later.
abstract class BarcodeLabelPrinter {
  /// System print dialog (PDF layout).
  Future<void> printLabel(Product product);

  /// Share/save the label file.
  Future<void> shareLabel(Product product);

  /// Whether a thermal printer backend is available.
  bool get supportsThermal;

  /// Thermal print — unimplemented until a thermal driver is wired.
  Future<void> printThermal(Product product);
}
