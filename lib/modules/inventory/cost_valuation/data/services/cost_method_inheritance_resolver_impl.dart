import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/services/cost_method_inheritance_resolver.dart';

class CostMethodInheritanceResolverImpl
    implements CostMethodInheritanceResolver {
  CostMethodInheritanceResolverImpl({
    required this._db,
    this._systemDefaultMethod = CostValuationMethod.fifo,
  });

  final InventoryDatabase _db;
  final CostValuationMethod _systemDefaultMethod;

  @override
  CostValuationMethod getSystemDefaultCostMethod() => _systemDefaultMethod;

  @override
  Future<EffectiveCostMethodResult> resolveForProduct({
    required String itemCode,
    required String? warehouseId,
  }) async {
    // 1. Level 1: Product Override
    final prodQuery = _db.select(_db.products)
      ..where((p) => p.itemCode.equals(itemCode) & p.deletedAt.isNull());
    final product = await prodQuery.getSingleOrNull();

    if (product != null) {
      if (product.costValuationMethod != null &&
          product.costValuationMethod!.isNotEmpty) {
        final parsed = _parseMethod(product.costValuationMethod);
        if (parsed != null) {
          return EffectiveCostMethodResult(
            effectiveMethod: parsed,
            source: CostMethodSource.product,
            resolvedEntityId: product.uuid,
            resolvedEntityName: product.name,
          );
        }
      }

      // 2. Level 2 & Level 3: Category Tree Overrides (Product -> Category -> Parent Categories)
      if (product.categoryId != null && product.categoryId!.isNotEmpty) {
        final catResult =
            await resolveForCategory(categoryId: product.categoryId!);
        if (catResult.source == CostMethodSource.category) {
          return catResult;
        }
      }
    }

    // 3. Level 4: Warehouse Override
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final whResult = await resolveForWarehouse(warehouseId: warehouseId);
      if (whResult.source == CostMethodSource.warehouse) {
        return whResult;
      }
    }

    // 4. Level 5: System Default
    return EffectiveCostMethodResult(
      effectiveMethod: _systemDefaultMethod,
      source: CostMethodSource.system,
    );
  }

  @override
  Future<EffectiveCostMethodResult> resolveForCategory({
    required String categoryId,
  }) async {
    var currentCatId = categoryId;
    final visited = <String>{};

    while (currentCatId.isNotEmpty) {
      if (visited.contains(currentCatId)) {
        // Cycle detected in category hierarchy tree! Break loop to avoid infinite recursion.
        break;
      }
      visited.add(currentCatId);

      final query = _db.select(_db.categories)
        ..where((c) => c.uuid.equals(currentCatId) & c.deletedAt.isNull());
      final cat = await query.getSingleOrNull();

      if (cat == null) break;

      // Check if this category has a direct cost method override
      if (cat.costValuationMethod != null &&
          cat.costValuationMethod!.isNotEmpty) {
        final parsed = _parseMethod(cat.costValuationMethod);
        if (parsed != null) {
          return EffectiveCostMethodResult(
            effectiveMethod: parsed,
            source: CostMethodSource.category,
            resolvedEntityId: cat.uuid,
            resolvedEntityName: cat.name,
          );
        }
      }

      // Walk up tree to parent category if present
      if (cat.parentId != null && cat.parentId!.isNotEmpty) {
        currentCatId = cat.parentId!;
      } else {
        // Reached root category, check warehouse override if parent category had no override
        if (cat.warehouseId.isNotEmpty) {
          final whResult =
              await resolveForWarehouse(warehouseId: cat.warehouseId);
          if (whResult.source == CostMethodSource.warehouse) {
            return whResult;
          }
        }
        break;
      }
    }

    // Fallback to System Default if no override was found up the category tree
    return EffectiveCostMethodResult(
      effectiveMethod: _systemDefaultMethod,
      source: CostMethodSource.system,
    );
  }

  @override
  Future<EffectiveCostMethodResult> resolveForWarehouse({
    required String warehouseId,
  }) async {
    final query = _db.select(_db.warehouses)
      ..where((w) => w.uuid.equals(warehouseId) & w.deletedAt.isNull());
    final wh = await query.getSingleOrNull();

    if (wh != null &&
        wh.costValuationMethod != null &&
        wh.costValuationMethod!.isNotEmpty) {
      final parsed = _parseMethod(wh.costValuationMethod);
      if (parsed != null) {
        return EffectiveCostMethodResult(
          effectiveMethod: parsed,
          source: CostMethodSource.warehouse,
          resolvedEntityId: wh.uuid,
          resolvedEntityName: wh.name,
        );
      }
    }

    return EffectiveCostMethodResult(
      effectiveMethod: _systemDefaultMethod,
      source: CostMethodSource.system,
    );
  }

  CostValuationMethod? _parseMethod(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final method in CostValuationMethod.values) {
      if (method.name.toLowerCase() == raw.toLowerCase()) {
        return method;
      }
    }
    return null;
  }
}
