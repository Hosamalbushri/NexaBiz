import '../../modules/inventory/domain/entities/product.dart';
import '../../modules/inventory/domain/repositories/product_repository.dart';
import '../../modules/inventory/domain/services/product_scan_resolver.dart';
import '../../modules/sales/domain/services/sale_product_catalog_port.dart';

/// App adapter: Sales product catalog → Inventory products + scan resolver.
class InventorySaleProductCatalogAdapter implements SaleProductCatalogPort {
  InventorySaleProductCatalogAdapter({
    required ProductRepository repository,
    required ProductScanResolver scanResolver,
  }) : _repository = repository,
       _scanResolver = scanResolver;

  final ProductRepository _repository;
  final ProductScanResolver _scanResolver;

  SaleProductRef _map(Product p) {
    return SaleProductRef(
      productId: p.uuid,
      itemCode: p.itemCode,
      name: p.name,
      barcode: p.barcode,
      unitPrice: p.price,
      packSize: p.packSize <= 0 ? 1 : p.packSize,
    );
  }

  @override
  Future<SaleProductRef?> findById(String productId) async {
    final all = await _repository.getAll();
    for (final p in all) {
      if (p.uuid == productId && !p.isDeleted) {
        return _map(p);
      }
    }
    return null;
  }

  @override
  Future<SaleProductRef?> findByItemCode(String itemCode) async {
    final product = await _repository.getByItemCode(itemCode);
    if (product == null || product.isDeleted) {
      return null;
    }
    return _map(product);
  }

  @override
  Future<SaleProductRef?> findByBarcode(String barcode) async {
    final product = await _repository.getByBarcode(barcode);
    if (product == null || product.isDeleted) {
      return null;
    }
    return _map(product);
  }

  @override
  Future<SaleProductRef?> resolveScan(String raw) async {
    final resolution = await _scanResolver.resolve(raw);
    if (resolution == null) {
      return null;
    }
    return _map(resolution.product);
  }

  @override
  Future<List<SaleProductRef>> search(String query, {int limit = 40}) async {
    final results = await _repository.search(query);
    return results
        .where((p) => !p.isDeleted)
        .take(limit)
        .map(_map)
        .toList(growable: false);
  }
}
