class WarehouseAccountingBinding {
  WarehouseAccountingBinding({
    required this.id,
    required this.warehouseId,
    this.inventoryAssetAccountId,
    this.cogsAccountId,
    this.inventoryAdjustmentAccountId,
    this.stockTransferClearingAccountId,
    required this.companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String warehouseId;
  final String? inventoryAssetAccountId;
  final String? cogsAccountId;
  final String? inventoryAdjustmentAccountId;
  final String? stockTransferClearingAccountId;
  final String companyId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  WarehouseAccountingBinding copyWith({
    String? id,
    String? warehouseId,
    String? inventoryAssetAccountId,
    bool clearInventoryAssetAccountId = false,
    String? cogsAccountId,
    bool clearCogsAccountId = false,
    String? inventoryAdjustmentAccountId,
    bool clearInventoryAdjustmentAccountId = false,
    String? stockTransferClearingAccountId,
    bool clearStockTransferClearingAccountId = false,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return WarehouseAccountingBinding(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      inventoryAssetAccountId: clearInventoryAssetAccountId
          ? null
          : (inventoryAssetAccountId ?? this.inventoryAssetAccountId),
      cogsAccountId: clearCogsAccountId
          ? null
          : (cogsAccountId ?? this.cogsAccountId),
      inventoryAdjustmentAccountId: clearInventoryAdjustmentAccountId
          ? null
          : (inventoryAdjustmentAccountId ?? this.inventoryAdjustmentAccountId),
      stockTransferClearingAccountId: clearStockTransferClearingAccountId
          ? null
          : (stockTransferClearingAccountId ??
                this.stockTransferClearingAccountId),
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
