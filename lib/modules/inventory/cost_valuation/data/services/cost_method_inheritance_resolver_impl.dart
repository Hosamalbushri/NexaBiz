import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/services/cost_method_inheritance_resolver.dart';

class CostMethodInheritanceResolverImpl
    implements CostMethodInheritanceResolver {
  CostMethodInheritanceResolverImpl({
    required InventoryDatabase db,
    CostValuationMethod systemDefaultMethod = CostValuationMethod.fifo,
    Map<String, CostValuationMethod>? productWarehouseOverrides,
  }) : _db = db,
       _systemDefaultMethod = systemDefaultMethod,
       _productWarehouseOverrides = productWarehouseOverrides ?? {};

  final InventoryDatabase _db;
  final CostValuationMethod _systemDefaultMethod;
  final Map<String, CostValuationMethod> _productWarehouseOverrides;

  /// Register an explicit Product + Warehouse costing method override (Tier 1).
  void registerProductWarehouseOverride({
    required String itemCode,
    required String warehouseId,
    required CostValuationMethod method,
  }) {
    _productWarehouseOverrides['$itemCode:$warehouseId'] = method;
  }

  @override
  CostValuationMethod getSystemDefaultCostMethod() => _systemDefaultMethod;

  @override
  Future<EffectiveCostMethodResult> resolveForProduct({
    required String itemCode,
    required String? warehouseId,
    String? companyId,
  }) async {
    // 1. Tier 1: Product + Warehouse explicit override check (Highest Priority)
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final overrideKey = '$itemCode:$warehouseId';
      if (_productWarehouseOverrides.containsKey(overrideKey)) {
        final overrideMethod = _productWarehouseOverrides[overrideKey]!;
        return EffectiveCostMethodResult(
          effectiveMethod: overrideMethod,
          source: CostMethodSource.productWarehouse,
          resolvedEntityId: overrideKey,
          resolvedEntityName: 'Product $itemCode @ Warehouse $warehouseId',
        );
      }
    }

    // 2. Tier 2: Product Master Override
    final prodQuery = _db.select(_db.products)
      ..where((p) {
        var expr = p.itemCode.equals(itemCode) & p.deletedAt.isNull();
        if (companyId != null && companyId.isNotEmpty) {
          expr = expr & (p.companyId.equals(companyId) | p.companyId.isNull());
        }
        return expr;
      });
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

      // 3. Tier 3: Category Tree Overrides (Product -> Category -> Parent Categories)
      if (product.categoryId != null && product.categoryId!.isNotEmpty) {
        final catResult = await resolveForCategory(
          categoryId: product.categoryId!,
          companyId: companyId,
        );
        if (catResult.source == CostMethodSource.category) {
          return catResult;
        }
      }
    }

    // 4. Tier 4: Warehouse Override
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final whResult = await resolveForWarehouse(
        warehouseId: warehouseId,
        companyId: companyId,
      );
      if (whResult.source == CostMethodSource.warehouse) {
        return whResult;
      }
    }

    // 5. Tier 5: System / Company Default Fallback
    return EffectiveCostMethodResult(
      effectiveMethod: _systemDefaultMethod,
      source: CostMethodSource.system,
    );
  }

  @override
  Future<EffectiveCostMethodResult> resolveForCategory({
    required String categoryId,
    String? companyId,
  }) async {
    var currentCatId = categoryId;
    final visited = <String>{};

    while (currentCatId.isNotEmpty) {
      if (visited.contains(currentCatId)) {
        // Cycle detected in category hierarchy tree! Break loop.
        break;
      }
      visited.add(currentCatId);

      final query = _db.select(_db.categories)
        ..where((c) {
          var expr = c.uuid.equals(currentCatId) & c.deletedAt.isNull();
          if (companyId != null && companyId.isNotEmpty) {
            expr =
                expr & (c.companyId.equals(companyId) | c.companyId.isNull());
          }
          return expr;
        });
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
        if (cat.warehouseId.isNotEmpty) {
          final whResult = await resolveForWarehouse(
            warehouseId: cat.warehouseId,
            companyId: companyId,
          );
          if (whResult.source == CostMethodSource.warehouse) {
            return whResult;
          }
        }
        break;
      }
    }

    return EffectiveCostMethodResult(
      effectiveMethod: _systemDefaultMethod,
      source: CostMethodSource.system,
    );
  }

  @override
  Future<EffectiveCostMethodResult> resolveForWarehouse({
    required String warehouseId,
    String? companyId,
  }) async {
    final query = _db.select(_db.warehouses)
      ..where((w) {
        var expr = w.uuid.equals(warehouseId) & w.deletedAt.isNull();
        if (companyId != null && companyId.isNotEmpty) {
          expr = expr & (w.companyId.equals(companyId) | w.companyId.isNull());
        }
        return expr;
      });
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
    final normalized = raw.trim().toLowerCase().replaceAll('_', '');
    for (final method in CostValuationMethod.values) {
      if (method.name.toLowerCase().replaceAll('_', '') == normalized) {
        return method;
      }
    }
    return null;
  }
}
