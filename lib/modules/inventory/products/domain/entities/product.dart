import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/sync/sync.dart';

/// Master product in the inventory catalog (Drift-backed).
class Product {
  const Product({
    required this.id,
    required this.uuid,
    required this.itemCode,
    required this.name,
    required this.packSize,
    required this.price,
    this.unitCost = 0,
    this.onHandQty = 0,
    this.categoryId,
    this.costValuationMethod,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  });

  final int id;
  final String uuid;
  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;
  final double onHandQty;
  final double unitCost;

  /// Category UUID linking product to warehouse-rooted category tree.
  final String? categoryId;

  /// Cost Valuation Method Override: Null = inherit from Category/Warehouse/System.
  final CostValuationMethod? costValuationMethod;

  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    int? id,
    String? uuid,
    String? itemCode,
    String? name,
    String? barcode,
    bool clearBarcode = false,
    int? packSize,
    double? price,
    double? onHandQty,
    double? unitCost,
    String? categoryId,
    bool clearCategoryId = false,
    CostValuationMethod? costValuationMethod,
    bool clearCostValuationMethod = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    int? version,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      packSize: packSize ?? this.packSize,
      price: price ?? this.price,
      onHandQty: onHandQty ?? this.onHandQty,
      unitCost: unitCost ?? this.unitCost,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      costValuationMethod: clearCostValuationMethod
          ? null
          : (costValuationMethod ?? this.costValuationMethod),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      version: version ?? this.version,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

/// Payload for create / update / upsert (no id / timestamps required).
class ProductDraft {
  const ProductDraft({
    required this.itemCode,
    required this.name,
    required this.packSize,
    required this.price,
    this.unitCost = 0,
    this.barcode,
    this.categoryId,
    this.costValuationMethod,
  });

  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;
  final double unitCost;
  final String? categoryId;
  final CostValuationMethod? costValuationMethod;
}
