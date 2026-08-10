import '../repositories/product_repository.dart';

/// Builds a unique barcode value for the products catalog (does not persist).
class ProductBarcodeGenerator {
  const ProductBarcodeGenerator(this._repository);

  final ProductRepository _repository;

  /// Prefer [itemCode] when non-empty; otherwise `P` + timestamp.
  /// Appends `-2`, `-3`, … while [getByBarcode] finds a collision
  /// (skipping [excludingProductId] when editing).
  Future<String> generate({
    required String itemCode,
    int? excludingProductId,
    DateTime? now,
  }) async {
    final trimmedCode = itemCode.trim();
    final base = trimmedCode.isNotEmpty
        ? trimmedCode
        : 'P${(now ?? DateTime.now()).millisecondsSinceEpoch}';

    var candidate = base;
    var suffix = 2;
    while (true) {
      final existing = await _repository.getByBarcode(candidate);
      if (existing == null ||
          (excludingProductId != null && existing.id == excludingProductId)) {
        return candidate;
      }
      candidate = '$base-$suffix';
      suffix++;
      if (suffix > 9999) {
        return 'P${(now ?? DateTime.now()).millisecondsSinceEpoch}-$suffix';
      }
    }
  }
}
