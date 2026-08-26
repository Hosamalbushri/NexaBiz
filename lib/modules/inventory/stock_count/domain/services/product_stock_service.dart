import 'package:stock_count/modules/inventory/products/domain/models/product_exception.dart';
import '../models/stock_quantity_line.dart';
import 'package:stock_count/modules/inventory/products/domain/repositories/product_repository.dart';

/// Perpetual inventory mutations for operational documents (sales, future POs).
class ProductStockService {
  ProductStockService(this._products);

  final ProductRepository _products;

  Future<void> issueLines(Iterable<StockQuantityLine> lines) async {
    for (final line in lines) {
      final id = line.productUuid.trim();
      if (id.isEmpty || line.quantity <= 0) {
        continue;
      }
      await _products.adjustOnHandByUuid(uuid: id, delta: -line.quantity);
    }
  }

  Future<void> receiveLines(Iterable<StockQuantityLine> lines) async {
    for (final line in lines) {
      final id = line.productUuid.trim();
      if (id.isEmpty || line.quantity <= 0) {
        continue;
      }
      await _products.adjustOnHandByUuid(uuid: id, delta: line.quantity);
    }
  }

  Future<double> costForLines(Iterable<StockQuantityLine> lines) async {
    var total = 0.0;
    for (final line in lines) {
      final id = line.productUuid.trim();
      if (id.isEmpty || line.quantity <= 0) {
        continue;
      }
      final product = await _products.getByUuid(id);
      if (product == null) {
        throw const ProductException(ProductException.notFound);
      }
      total += line.quantity * product.unitCost;
    }
    return total;
  }
}
