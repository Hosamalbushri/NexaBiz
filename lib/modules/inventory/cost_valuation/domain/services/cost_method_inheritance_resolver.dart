import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

/// Source level where the cost valuation method setting was resolved.
enum CostMethodSource {
  /// Overridden directly on the Product master catalog.
  product,

  /// Overridden on the Category or any parent Subcategory in the tree.
  category,

  /// Overridden on the Warehouse.
  warehouse,

  /// Fallback to System Default configuration.
  system;

  String get displayName {
    switch (this) {
      case CostMethodSource.product:
        return 'إعداد خاص بالمنتج (Product Override)';
      case CostMethodSource.category:
        return 'موروث من التصنيف (Category Override)';
      case CostMethodSource.warehouse:
        return 'موروث من المستودع (Warehouse Override)';
      case CostMethodSource.system:
        return 'افتراضي النظام (System Default)';
    }
  }
}

/// Result of evaluating effective cost valuation method for a context.
class EffectiveCostMethodResult {
  const EffectiveCostMethodResult({
    required this.effectiveMethod,
    required this.source,
    this.resolvedEntityId,
    this.resolvedEntityName,
  });

  final CostValuationMethod effectiveMethod;
  final CostMethodSource source;

  /// Identifier of the entity where the override was defined (Product ID, Category UUID, or Warehouse UUID).
  final String? resolvedEntityId;

  /// Display name of the resolving entity.
  final String? resolvedEntityName;
}

/// Service governing resolution of effective inventory cost valuation method
/// across the inheritance cascade: Product -> Category -> Warehouse -> System Default.
abstract class CostMethodInheritanceResolver {
  /// Resolves effective cost valuation method for a specific [itemCode] within a [warehouseId].
  Future<EffectiveCostMethodResult> resolveForProduct({
    required String itemCode,
    required String? warehouseId,
  });

  /// Resolves effective cost valuation method for a category hierarchy starting at [categoryId].
  Future<EffectiveCostMethodResult> resolveForCategory({
    required String categoryId,
  });

  /// Resolves effective cost valuation method for a warehouse [warehouseId].
  Future<EffectiveCostMethodResult> resolveForWarehouse({
    required String warehouseId,
  });

  /// Returns system default cost valuation method.
  CostValuationMethod getSystemDefaultCostMethod();
}
