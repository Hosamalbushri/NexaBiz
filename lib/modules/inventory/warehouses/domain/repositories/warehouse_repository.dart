import '../entities/product_warehouse_stock.dart';
import '../entities/warehouse.dart';

abstract class WarehouseRepository {
  /// Warehouses
  Future<List<Warehouse>> getAllWarehouses();
  Stream<List<Warehouse>> watchAllWarehouses();
  Future<Warehouse?> getWarehouseById(String id);
  Future<Warehouse?> getDefaultWarehouse();
  Future<Warehouse> ensureDefaultWarehouse();
  Future<void> saveWarehouse(Warehouse warehouse);
  Future<void> deleteWarehouse(String id);

  /// Per-Warehouse Product Stocks
  Future<List<ProductWarehouseStock>> getStocksForWarehouse(String warehouseId);
  Future<ProductWarehouseStock?> getStock(String itemCode, String warehouseId);
  Future<void> updateWarehouseStock(String itemCode, String warehouseId, double deltaQty);
}
