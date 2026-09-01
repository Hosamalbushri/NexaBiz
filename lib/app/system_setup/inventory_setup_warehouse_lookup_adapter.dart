import 'package:stock_count/core/domain/ports/setup_warehouse_lookup_port.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_repository.dart';

class InventorySetupWarehouseLookupAdapter implements SetupWarehouseLookupPort {
  InventorySetupWarehouseLookupAdapter(this._warehouseRepository);

  final WarehouseRepository _warehouseRepository;

  @override
  Future<SetupWarehouseData?> getWarehouseById(String warehouseId) async {
    final warehouse = await _warehouseRepository.getWarehouseById(warehouseId);
    if (warehouse == null) return null;

    return SetupWarehouseData(
      id: warehouse.id,
      companyId: warehouse.companyId,
      isActive: warehouse.isActive,
      isDeleted: warehouse.deletedAt != null,
    );
  }
}
