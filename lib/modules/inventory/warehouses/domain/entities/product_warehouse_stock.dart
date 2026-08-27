class ProductWarehouseStock {
  ProductWarehouseStock({
    required this.id,
    required this.itemCode,
    required this.warehouseId,
    this.onHandQty = 0.0,
    this.minReorderLevel,
    this.binLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String itemCode;
  final String warehouseId;
  final double onHandQty;
  final double? minReorderLevel;
  final String? binLocation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  ProductWarehouseStock copyWith({
    String? id,
    String? itemCode,
    String? warehouseId,
    double? onHandQty,
    double? minReorderLevel,
    String? binLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? companyId,
    DateTime? deletedAt,
  }) {
    return ProductWarehouseStock(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      warehouseId: warehouseId ?? this.warehouseId,
      onHandQty: onHandQty ?? this.onHandQty,
      minReorderLevel: minReorderLevel ?? this.minReorderLevel,
      binLocation: binLocation ?? this.binLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
