import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/sync/sync.dart';

/// Category entity in the warehouse-rooted category tree.
class Category {
  const Category({
    required this.id,
    required this.code,
    required this.name,
    required this.warehouseId,
    this.parentId,
    this.level = 0,
    this.isGroup = true,
    this.isActive = true,
    this.costValuationMethod,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  });

  final String id;
  final String code;
  final String name;

  /// Top root: Warehouse identifier where this category belongs.
  final String warehouseId;

  /// Parent category ID for tree hierarchy (null for root categories).
  final String? parentId;

  /// Depth in the tree (roots under warehouse = 0).
  final int level;

  /// When true, this is a group (header) category — contains subcategories.
  /// When false, this is a leaf category — directly holds products.
  final bool isGroup;

  final bool isActive;

  /// Cost Valuation Method Override: Null = inherit from parent/warehouse.
  final CostValuationMethod? costValuationMethod;

  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  bool get isRoot => parentId == null || parentId!.isEmpty;
  bool get isLeaf => !isGroup;
  bool get isDeleted => deletedAt != null;

  Category copyWith({
    String? id,
    String? code,
    String? name,
    String? warehouseId,
    String? parentId,
    bool clearParentId = false,
    int? level,
    bool? isGroup,
    bool? isActive,
    CostValuationMethod? costValuationMethod,
    bool clearCostValuationMethod = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    int? version,
    String? companyId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      warehouseId: warehouseId ?? this.warehouseId,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      level: level ?? this.level,
      isGroup: isGroup ?? this.isGroup,
      isActive: isActive ?? this.isActive,
      costValuationMethod: clearCostValuationMethod
          ? null
          : (costValuationMethod ?? this.costValuationMethod),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
