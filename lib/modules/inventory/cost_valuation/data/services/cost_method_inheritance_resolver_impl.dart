import 'package:drift/drift.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/services/cost_method_inheritance_resolver.dart';

class CostMethodInheritanceResolverImpl
    implements CostMethodInheritanceResolver {
  CostMethodInheritanceResolverImpl({
    required NexabizDatabase db,
    CostValuationMethod systemDefaultMethod = CostValuationMethod.fifo,
    Map<String, CostValuationMethod>? productWarehouseOverrides,
  }) : _db = db,
       _systemDefaultMethod = systemDefaultMethod,
       _productWarehouseOverrides = productWarehouseOverrides ?? {};

  final NexabizDatabase _db;
  final CostValuationMethod _systemDefaultMethod;
  final Map<String, CostValuationMethod> _productWarehouseOverrides;

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

    final prodQuery = _db.select(_db.products)
      ..where((p) {
        var expr = p.itemCode.equals(itemCode) & p.isActive.equals(true);
        if (companyId != null && companyId.isNotEmpty) {
          expr = expr & (p.companyId.equals(companyId) | p.companyId.isNull());
        }
        return expr;
      });
    final product = await prodQuery.getSingleOrNull();

    if (product != null) {
      if (product.categoryUuid != null && product.categoryUuid!.isNotEmpty) {
        final catResult = await resolveForCategory(
          categoryId: product.categoryUuid!,
          companyId: companyId,
        );
        if (catResult.source == CostMethodSource.category) {
          return catResult;
        }
      }
    }

    if (warehouseId != null && warehouseId.isNotEmpty) {
      final whResult = await resolveForWarehouse(
        warehouseId: warehouseId,
        companyId: companyId,
      );
      if (whResult.source == CostMethodSource.warehouse) {
        return whResult;
      }
    }

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
        break;
      }
      visited.add(currentCatId);

      final query = _db.select(_db.productCategories)
        ..where((c) {
          var expr = c.uuid.equals(currentCatId) & c.isActive.equals(true);
          if (companyId != null && companyId.isNotEmpty) {
            expr =
                expr & (c.companyId.equals(companyId) | c.companyId.isNull());
          }
          return expr;
        });
      final cat = await query.getSingleOrNull();

      if (cat == null) break;

      if (cat.parentUuid != null && cat.parentUuid!.isNotEmpty) {
        currentCatId = cat.parentUuid!;
      } else {
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
        var expr = w.uuid.equals(warehouseId) & w.isActive.equals(true);
        if (companyId != null && companyId.isNotEmpty) {
          expr = expr & (w.companyId.equals(companyId) | w.companyId.isNull());
        }
        return expr;
      });
    final wh = await query.getSingleOrNull();

    if (wh != null) {
      return EffectiveCostMethodResult(
        effectiveMethod: _systemDefaultMethod,
        source: CostMethodSource.warehouse,
        resolvedEntityId: wh.uuid,
        resolvedEntityName: wh.name,
      );
    }

    return EffectiveCostMethodResult(
      effectiveMethod: _systemDefaultMethod,
      source: CostMethodSource.system,
    );
  }
}
