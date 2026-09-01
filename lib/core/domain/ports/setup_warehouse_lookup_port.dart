class SetupWarehouseData {
  const SetupWarehouseData({
    required this.id,
    this.companyId,
    required this.isActive,
    required this.isDeleted,
  });

  final String id;
  final String? companyId;
  final bool isActive;
  final bool isDeleted;
}

abstract class SetupWarehouseLookupPort {
  Future<SetupWarehouseData?> getWarehouseById(String warehouseId);
}

class NoOpSetupWarehouseLookupPort implements SetupWarehouseLookupPort {
  const NoOpSetupWarehouseLookupPort();

  @override
  Future<SetupWarehouseData?> getWarehouseById(String warehouseId) async => null;
}
