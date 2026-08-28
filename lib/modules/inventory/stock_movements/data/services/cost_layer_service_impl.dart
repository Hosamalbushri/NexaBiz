import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

import '../../../shared/data/database/inventory_database.dart';
import '../../domain/entities/cost_consumption.dart';
import '../../domain/entities/cost_layer.dart';
import '../../domain/enums/cost_valuation_method.dart';
import '../../domain/services/cost_layer_service.dart';

class CostLayerServiceImpl implements CostLayerService {
  CostLayerServiceImpl({required InventoryDatabase db}) : _db = db;

  final InventoryDatabase _db;

  @override
  Future<void> createLayer(CostLayer layer) async {
    await _db.into(_db.inventoryCostLayers).insert(
          InventoryCostLayersCompanion(
            uuid: Value(layer.id),
            itemCode: Value(layer.itemCode),
            warehouseId: Value(layer.warehouseId),
            movementUuid: Value(layer.movementUuid),
            movementType: Value(layer.movementType),
            receivedDate: Value(layer.receivedDate.millisecondsSinceEpoch),
            receivedQty: Value(layer.receivedQty),
            remainingQty: Value(layer.remainingQty),
            unitCost: Value(layer.unitCost),
            totalCost: Value(layer.totalCost),
            closed: Value(layer.closed ? 1 : 0),
            createdAt: Value(layer.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(layer.updatedAt.millisecondsSinceEpoch),
            syncStatus: const Value('synced'),
            version: Value(layer.version),
            companyId: Value(layer.companyId),
          ),
        );
  }

  @override
  Future<LayerConsumptionResult> consumeLayers({
    required String itemCode,
    required double quantity,
    required CostValuationMethod method,
    required String issueLineUuid,
    required String movementType,
    String? warehouseId,
    String? companyId,
  }) async {
    if (quantity <= 0) {
      return const LayerConsumptionResult(
        consumptions: [],
        totalCost: 0,
        effectiveUnitCost: 0,
        isShortage: false,
        shortageQty: 0,
      );
    }

    if (method == CostValuationMethod.weightedAverage) {
      return _consumeWeightedAverage(
        itemCode: itemCode,
        quantity: quantity,
        issueLineUuid: issueLineUuid,
        movementType: movementType,
        warehouseId: warehouseId,
        companyId: companyId,
      );
    }

    // FIFO or LIFO
    final isFifo = method == CostValuationMethod.fifo;
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.closed.equals(0) &
          tbl.deletedAt.isNull());

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query..where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    query = query
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.receivedDate,
              mode: isFifo ? OrderingMode.asc : OrderingMode.desc,
            ),
        (tbl) => OrderingTerm(
              expression: tbl.id,
              mode: isFifo ? OrderingMode.asc : OrderingMode.desc,
            ),
      ]);

    final layers = await query.get();
    var remainingNeeded = quantity;
    var accumulatedTotalCost = 0.0;
    final consumptions = <CostConsumption>[];

    for (final row in layers) {
      if (remainingNeeded <= 0.000001) break;

      final avail = row.remainingQty;
      if (avail <= 0) continue;

      final takeQty = avail <= remainingNeeded ? avail : remainingNeeded;
      final newRemaining = avail - takeQty;
      final isClosed = newRemaining <= 0.000001;
      final lineCost = takeQty * row.unitCost;

      accumulatedTotalCost += lineCost;
      remainingNeeded -= takeQty;

      // Update layer remaining quantity
      await (_db.update(_db.inventoryCostLayers)
            ..where((tbl) => tbl.uuid.equals(row.uuid)))
          .write(
        InventoryCostLayersCompanion(
          remainingQty: Value(newRemaining),
          closed: Value(isClosed ? 1 : 0),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      // Record consumption
      final consumptionUuid = generateUuidV4();
      final now = DateTime.now().toUtc();
      await _db.into(_db.inventoryCostConsumptions).insert(
            InventoryCostConsumptionsCompanion(
              uuid: Value(consumptionUuid),
              layerUuid: Value(row.uuid),
              issueLineUuid: Value(issueLineUuid),
              movementType: Value(movementType),
              consumedQty: Value(takeQty),
              unitCost: Value(row.unitCost),
              totalCost: Value(lineCost),
              createdAt: Value(now.millisecondsSinceEpoch),
              companyId: Value(companyId),
            ),
          );

      consumptions.add(
        CostConsumption(
          id: consumptionUuid,
          layerUuid: row.uuid,
          issueLineUuid: issueLineUuid,
          movementType: movementType,
          consumedQty: takeQty,
          unitCost: row.unitCost,
          totalCost: lineCost,
          createdAt: now,
          companyId: companyId,
        ),
      );
    }

    final isShortage = remainingNeeded > 0.000001;
    if (isShortage) {
      // If shortage exists, evaluate fallback cost for the unfulfilled quantity
      final fallbackCost = await _getFallbackUnitCost(itemCode);
      accumulatedTotalCost += (remainingNeeded * fallbackCost);
    }

    final effectiveUnitCost = quantity > 0 ? accumulatedTotalCost / quantity : 0.0;

    return LayerConsumptionResult(
      consumptions: consumptions,
      totalCost: accumulatedTotalCost,
      effectiveUnitCost: effectiveUnitCost,
      isShortage: isShortage,
      shortageQty: isShortage ? remainingNeeded : 0.0,
    );
  }

  Future<LayerConsumptionResult> _consumeWeightedAverage({
    required String itemCode,
    required double quantity,
    required String issueLineUuid,
    required String movementType,
    String? warehouseId,
    String? companyId,
  }) async {
    final avgCost = await getWeightedAverageCost(itemCode, warehouseId: warehouseId);
    final unitCostToUse = avgCost > 0 ? avgCost : await _getFallbackUnitCost(itemCode);
    final totalCost = quantity * unitCostToUse;

    // Proportionally deduct from open FIFO layers for consistency
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.closed.equals(0) &
          tbl.deletedAt.isNull());

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query..where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    query = query..orderBy([(tbl) => OrderingTerm.asc(tbl.receivedDate)]);
    final layers = await query.get();

    var remainingNeeded = quantity;
    final consumptions = <CostConsumption>[];

    for (final row in layers) {
      if (remainingNeeded <= 0.000001) break;

      final avail = row.remainingQty;
      if (avail <= 0) continue;

      final takeQty = avail <= remainingNeeded ? avail : remainingNeeded;
      final newRemaining = avail - takeQty;
      final isClosed = newRemaining <= 0.000001;
      final lineCost = takeQty * unitCostToUse;

      remainingNeeded -= takeQty;

      await (_db.update(_db.inventoryCostLayers)
            ..where((tbl) => tbl.uuid.equals(row.uuid)))
          .write(
        InventoryCostLayersCompanion(
          remainingQty: Value(newRemaining),
          closed: Value(isClosed ? 1 : 0),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

      final consumptionUuid = generateUuidV4();
      final now = DateTime.now().toUtc();
      await _db.into(_db.inventoryCostConsumptions).insert(
            InventoryCostConsumptionsCompanion(
              uuid: Value(consumptionUuid),
              layerUuid: Value(row.uuid),
              issueLineUuid: Value(issueLineUuid),
              movementType: Value(movementType),
              consumedQty: Value(takeQty),
              unitCost: Value(unitCostToUse),
              totalCost: Value(lineCost),
              createdAt: Value(now.millisecondsSinceEpoch),
              companyId: Value(companyId),
            ),
          );

      consumptions.add(
        CostConsumption(
          id: consumptionUuid,
          layerUuid: row.uuid,
          issueLineUuid: issueLineUuid,
          movementType: movementType,
          consumedQty: takeQty,
          unitCost: unitCostToUse,
          totalCost: lineCost,
          createdAt: now,
          companyId: companyId,
        ),
      );
    }

    final isShortage = remainingNeeded > 0.000001;

    return LayerConsumptionResult(
      consumptions: consumptions,
      totalCost: totalCost,
      effectiveUnitCost: unitCostToUse,
      isShortage: isShortage,
      shortageQty: isShortage ? remainingNeeded : 0.0,
    );
  }

  @override
  Future<void> reverseConsumptions(String issueLineUuid) async {
    final query = _db.select(_db.inventoryCostConsumptions)
      ..where((tbl) => tbl.issueLineUuid.equals(issueLineUuid));
    final consumptions = await query.get();

    for (final c in consumptions) {
      final layerQuery = _db.select(_db.inventoryCostLayers)
        ..where((tbl) => tbl.uuid.equals(c.layerUuid));
      final layer = await layerQuery.getSingleOrNull();

      if (layer != null) {
        final restoredQty = layer.remainingQty + c.consumedQty;
        await (_db.update(_db.inventoryCostLayers)
              ..where((tbl) => tbl.uuid.equals(layer.uuid)))
            .write(
          InventoryCostLayersCompanion(
            remainingQty: Value(restoredQty),
            closed: const Value(0),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
      }
    }

    // Delete consumption rows
    await (_db.delete(_db.inventoryCostConsumptions)
          ..where((tbl) => tbl.issueLineUuid.equals(issueLineUuid)))
        .go();
  }

  @override
  Future<void> reverseLayer(String movementUuid) async {
    final query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) => tbl.movementUuid.equals(movementUuid));
    final layers = await query.get();

    final now = DateTime.now().toUtc();
    for (final layer in layers) {
      // Soft-delete the layer
      await (_db.update(_db.inventoryCostLayers)
            ..where((tbl) => tbl.uuid.equals(layer.uuid)))
          .write(
        InventoryCostLayersCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          closed: const Value(1),
        ),
      );
    }
  }

  @override
  Future<double> getWeightedAverageCost(String itemCode, {String? warehouseId}) async {
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.closed.equals(0) &
          tbl.deletedAt.isNull());

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query..where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    final layers = await query.get();
    var totalValue = 0.0;
    var totalQty = 0.0;

    for (final row in layers) {
      if (row.remainingQty > 0) {
        totalQty += row.remainingQty;
        totalValue += (row.remainingQty * row.unitCost);
      }
    }

    if (totalQty <= 0) {
      return _getFallbackUnitCost(itemCode);
    }

    return totalValue / totalQty;
  }

  @override
  Future<List<CostLayer>> getOpenLayers(String itemCode, {String? warehouseId}) async {
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.closed.equals(0) &
          tbl.deletedAt.isNull());

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query..where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    query = query..orderBy([(tbl) => OrderingTerm.asc(tbl.receivedDate)]);
    final rows = await query.get();

    return rows
        .map(
          (row) => CostLayer(
            id: row.uuid,
            itemCode: row.itemCode,
            warehouseId: row.warehouseId,
            movementUuid: row.movementUuid,
            movementType: row.movementType,
            receivedDate: DateTime.fromMillisecondsSinceEpoch(row.receivedDate, isUtc: true),
            receivedQty: row.receivedQty,
            remainingQty: row.remainingQty,
            unitCost: row.unitCost,
            totalCost: row.totalCost,
            closed: row.closed == 1,
            createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
            version: row.version,
            companyId: row.companyId,
            deletedAt: row.deletedAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
          ),
        )
        .toList();
  }

  @override
  Future<double> getItemCostValuation({
    required String itemCode,
    CostValuationMethod method = CostValuationMethod.weightedAverage,
    String? warehouseId,
  }) async {
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.closed.equals(0) &
          tbl.deletedAt.isNull());

    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query..where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    if (method == CostValuationMethod.fifo) {
      query = query..orderBy([(tbl) => OrderingTerm.asc(tbl.receivedDate)]);
    } else if (method == CostValuationMethod.lifo) {
      query = query..orderBy([(tbl) => OrderingTerm.desc(tbl.receivedDate)]);
    }

    final layers = await query.get();
    var resolvedCost = 0.0;

    if (layers.isNotEmpty) {
      if (method == CostValuationMethod.weightedAverage) {
        var totalValue = 0.0;
        var totalQty = 0.0;
        for (final layer in layers) {
          if (layer.remainingQty > 0) {
            totalQty += layer.remainingQty;
            totalValue += (layer.remainingQty * layer.unitCost);
          }
        }
        if (totalQty > 0) {
          resolvedCost = totalValue / totalQty;
        }
      } else {
        // FIFO or LIFO: pick cost from the first active layer with remainingQty > 0
        for (final layer in layers) {
          if (layer.remainingQty > 0 && layer.unitCost > 0) {
            resolvedCost = layer.unitCost;
            break;
          }
        }
      }
    }

    // If open layers yielded zero, lookup historical cost layers for itemCode
    if (resolvedCost <= 0) {
      final historicalQuery = _db.select(_db.inventoryCostLayers)
        ..where((tbl) =>
            tbl.itemCode.equals(itemCode) &
            tbl.unitCost.isBiggerThanValue(0) &
            tbl.deletedAt.isNull())
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.receivedDate)])
        ..limit(1);
      final lastLayer = await historicalQuery.getSingleOrNull();
      if (lastLayer != null && lastLayer.unitCost > 0) {
        resolvedCost = lastLayer.unitCost;
      }
    }

    // Fallback to product catalog unitCost
    if (resolvedCost <= 0) {
      resolvedCost = await _getFallbackUnitCost(itemCode);
    }

    return resolvedCost;
  }

  Future<double> _getFallbackUnitCost(String itemCode) async {
    final query = _db.select(_db.products)
      ..where((tbl) => tbl.itemCode.equals(itemCode));
    final product = await query.getSingleOrNull();
    if (product == null) return 0.0;
    return product.unitCost > 0 ? product.unitCost : 0.0;
  }
}
