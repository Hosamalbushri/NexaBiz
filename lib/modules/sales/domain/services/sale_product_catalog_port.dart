/// Product snapshot for sale line selection (opaque Inventory identity).
class SaleProductRef {
  const SaleProductRef({
    required this.productId,
    required this.itemCode,
    required this.name,
    required this.unitPrice,
    this.barcode,
    this.packSize = 1,
  });

  /// Product.uuid
  final String productId;
  final String itemCode;
  final String name;
  final String? barcode;
  final double unitPrice;

  /// Pieces per main unit from inventory catalog.
  final int packSize;
}

/// Catalog / scan resolution — App wires to Inventory (modules ↛ modules).
abstract class SaleProductCatalogPort {
  Future<SaleProductRef?> findById(String productId);

  Future<SaleProductRef?> findByItemCode(String itemCode);

  Future<SaleProductRef?> findByBarcode(String barcode);

  /// Resolves barcode, item code, or product QR payload when supported.
  Future<SaleProductRef?> resolveScan(String raw);

  Future<List<SaleProductRef>> search(String query, {int limit = 40});
}

class NoOpSaleProductCatalogPort implements SaleProductCatalogPort {
  const NoOpSaleProductCatalogPort();

  @override
  Future<SaleProductRef?> findById(String productId) async => null;

  @override
  Future<SaleProductRef?> findByItemCode(String itemCode) async => null;

  @override
  Future<SaleProductRef?> findByBarcode(String barcode) async => null;

  @override
  Future<SaleProductRef?> resolveScan(String raw) async => null;

  @override
  Future<List<SaleProductRef>> search(String query, {int limit = 40}) async {
    return const [];
  }
}
