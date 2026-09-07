import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse_accounting_binding.dart';

abstract class WarehouseAccountingBindingRepository {
  Future<WarehouseAccountingBinding?> getBindingForWarehouse(
    String warehouseId,
  );
  Future<void> saveBinding(WarehouseAccountingBinding binding);
  Future<void> deleteBinding(String warehouseId);
}
