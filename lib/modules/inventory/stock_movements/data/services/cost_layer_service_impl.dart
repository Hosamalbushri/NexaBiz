import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';

import '../../../shared/data/database/inventory_database.dart';
import '../../domain/entities/cost_consumption.dart';
import '../../domain/entities/cost_layer.dart';
import '../../domain/enums/cost_valuation_method.dart';
import '../../domain/services/cost_layer_service.dart';

class CostLayerServiceImpl implements CostLayerService {
  CostLayerServiceImpl({
    required this._db,
    this._readCompanyId,
  });

  final InventoryDatabase _db;
  final String Function()? _readCompanyId;

  String get _currentCompanyId {
    final cid = _readCompanyId?.call().trim();
    if (cid == null || cid.isEmpty) {
      throw MissingCompanyContextException(
        'CostLayerService operation failed: missing company context.',
      );
    }
    return cid;
  }

  @override
  Future<void> createLayer(CostLayer layer) async {
    final effectiveCompanyId = layer.companyId ?? _currentCompanyId;
    final existing = await (_db.select(_db.inventoryCostLayers)
          ..where((tbl) =>
              tbl.uuid.equals(layer.id) &
              tbl.companyId.equals(effectiveCompanyId)))
        .getSingleOrNull();

    if (existing != null) {
      return;
    }

    final sanitizedReceivedQty = layer.receivedQty < 0 ? 0.0 : layer.receivedQty;
    final sanitizedRemainingQty = layer.remainingQty.clamp(0.0, sanitizedReceivedQty);
    final isClosed = layer.closed || sanitizedRemainingQty <= 0.000001;

    await _db.into(_db.inventoryCostLayers).insert(
          InventoryCostLayersCompanion(
            uuid: Value(layer.id),
            itemCode: Value(layer.itemCode),
            warehouseId: Value(layer.warehouseId),
            movementUuid: Value(layer.movementUuid),
            movementType: Value(layer.movementType),
            receivedDate: Value(layer.receivedDate.millisecondsSinceEpoch),
            receivedQty: Value(sanitizedReceivedQty),
            remainingQty: Value(sanitizedRemainingQty),
            unitCost: Value(layer.unitCost < 0 ? 0.0 : layer.unitCost),
            totalCost: Value(sanitizedReceivedQty * (layer.unitCost < 0 ? 0.0 : layer.unitCost)),
            closed: Value(isClosed ? 1 : 0),
            createdAt: Value(layer.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(layer.updatedAt.millisecondsSinceEpoch),
            syncStatus: const Value('synced'),
            version: Value(layer.version),
            companyId: Value(effectiveCompanyId),
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

    final effectiveCompanyId = companyId ?? _currentCompanyId;

    // Duplicate Consumption Guard: Check if issueLineUuid has ALREADY been consumed for this company
    final existingConsumptions = await (_db.select(_db.inventoryCostConsumptions)
          ..where((tbl) =>
              tbl.issueLineUuid.equals(issueLineUuid) &
              tbl.companyId.equals(effectiveCompanyId)))
        .get();

    if (existingConsumptions.isNotEmpty) {
      final totalCost = existingConsumptions.fold<double>(0.0, (s, c) => s + c.totalCost);
      final totalConsumed = existingConsumptions.fold<double>(0.0, (s, c) => s + c.consumedQty);
      final effCost = totalConsumed > 0 ? totalCost / totalConsumed : 0.0;
      return LayerConsumptionResult(
        consumptions: existingConsumptions
            .map((row) => CostConsumption(
                  id: row.uuid,
                  layerUuid: row.layerUuid,
                  issueLineUuid: row.issueLineUuid,
                  movementType: row.movementType,
                  consumedQty: row.consumedQty,
                  unitCost: row.unitCost,
                  totalCost: row.totalCost,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
                  companyId: row.companyId,
                ))
            .toList(),
        totalCost: totalCost,
        effectiveUnitCost: effCost,
        isShortage: false,
        shortageQty: 0.0,
      );
    }

    if (method == CostValuationMethod.weightedAverage) {
      return _consumeWeightedAverage(
        itemCode: itemCode,
        quantity: quantity,
        issueLineUuid: issueLineUuid,
        movementType: movementType,
        warehouseId: warehouseId,
        companyId: effectiveCompanyId,
      );
    }

    // FIFO or LIFO under atomic transaction loop
    final isFifo = method == CostValuationMethod.fifo;

    return await _db.transaction(() async {
      var remainingNeeded = quantity;
      var accumulatedTotalCost = 0.0;
      final consumptions = <CostConsumption>[];

      while (remainingNeeded > 0.000001) {
        var query = _db.select(_db.inventoryCostLayers)
          ..where((tbl) =>
              tbl.itemCode.equals(itemCode) &
              tbl.companyId.equals(effectiveCompanyId) &
              tbl.remainingQty.isBiggerThanValue(0) &
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
          ])
          ..limit(1);

        final topLayer = await query.getSingleOrNull();
        if (topLayer == null) {
          break;
        }

        final avail = topLayer.remainingQty;
        if (avail <= 0) break;

        final takeQty = avail <= remainingNeeded ? avail : remainingNeeded;
        var newRemaining = avail - takeQty;
        if (newRemaining < 0.000001) {
          newRemaining = 0.0;
        }
        final isClosed = newRemaining <= 0.000001;

        // Atomic conditional UPDATE with quantity guard to prevent concurrency race & negative quantity
        final updatedCount = await (_db.update(_db.inventoryCostLayers)
              ..where((tbl) =>
                  tbl.uuid.equals(topLayer.uuid) &
                  tbl.companyId.equals(effectiveCompanyId) &
                  tbl.remainingQty.isBiggerOrEqualValue(takeQty) &
                  tbl.closed.equals(0) &
                  tbl.deletedAt.isNull()))
            .write(
          InventoryCostLayersCompanion(
            remainingQty: Value(newRemaining),
            closed: Value(isClosed ? 1 : 0),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );

        if (updatedCount == 0) {
          // Race condition detected! Another concurrent request consumed from this layer.
          // Retry loop to evaluate latest available quantity.
          continue;
        }

        final lineCost = takeQty * topLayer.unitCost;
        accumulatedTotalCost += lineCost;
        remainingNeeded -= takeQty;

        final consumptionUuid = generateUuidV4();
        final now = DateTime.now().toUtc();
        await _db.into(_db.inventoryCostConsumptions).insert(
              InventoryCostConsumptionsCompanion(
                uuid: Value(consumptionUuid),
                layerUuid: Value(topLayer.uuid),
                issueLineUuid: Value(issueLineUuid),
                movementType: Value(movementType),
                consumedQty: Value(takeQty),
                unitCost: Value(topLayer.unitCost),
                totalCost: Value(lineCost),
                createdAt: Value(now.millisecondsSinceEpoch),
                companyId: Value(effectiveCompanyId),
              ),
            );

        consumptions.add(
          CostConsumption(
            id: consumptionUuid,
            layerUuid: topLayer.uuid,
            issueLineUuid: issueLineUuid,
            movementType: movementType,
            consumedQty: takeQty,
            unitCost: topLayer.unitCost,
            totalCost: lineCost,
            createdAt: now,
            companyId: effectiveCompanyId,
          ),
        );
      }

      final isShortage = remainingNeeded > 0.000001;
      if (isShortage) {
        final fallbackCost = await _getFallbackUnitCost(itemCode, companyId: effectiveCompanyId);
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
    });
  }

  Future<LayerConsumptionResult> _consumeWeightedAverage({
    required String itemCode,
    required double quantity,
    required String issueLineUuid,
    required String movementType,
    String? warehouseId,
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;

    return await _db.transaction(() async {
      final avgCost = await getWeightedAverageCost(itemCode, warehouseId: warehouseId, companyId: effectiveCompanyId);
      final unitCostToUse = avgCost > 0 ? avgCost : await _getFallbackUnitCost(itemCode, companyId: effectiveCompanyId);

      var query = _db.select(_db.inventoryCostLayers)
        ..where((tbl) =>
            tbl.itemCode.equals(itemCode) &
            tbl.companyId.equals(effectiveCompanyId) &
            tbl.closed.equals(0) &
            tbl.deletedAt.isNull());

      if (warehouseId != null && warehouseId.isNotEmpty) {
        query = query..where((tbl) => tbl.warehouseId.equals(warehouseId));
      }

      query = query..orderBy([(tbl) => OrderingTerm.asc(tbl.receivedDate)]);
      final layers = await query.get();

      final totalQty = layers.fold<double>(0.0, (sum, row) => sum + row.remainingQty);

      if (quantity > totalQty + 0.000001) {
        final shortageQty = quantity - totalQty;
        return LayerConsumptionResult(
          consumptions: const [],
          totalCost: 0.0,
          effectiveUnitCost: unitCostToUse,
          isShortage: true,
          shortageQty: shortageQty,
        );
      }

      if (totalQty <= 0) {
        return LayerConsumptionResult(
          consumptions: const [],
          totalCost: 0.0,
          effectiveUnitCost: unitCostToUse,
          isShortage: quantity > 0,
          shortageQty: quantity,
        );
      }

      final fraction = quantity / totalQty;
      final totalCost = quantity * unitCostToUse;
      final consumptions = <CostConsumption>[];

      for (final row in layers) {
        final avail = row.remainingQty;
        if (avail <= 0) continue;

        final takeQty = (fraction >= 1.0) ? avail : avail * fraction;
        var newRemaining = avail - takeQty;
        if (newRemaining < 0.000001) {
          newRemaining = 0.0;
        }
        final isClosed = newRemaining <= 0.000001;

        // Atomic conditional UPDATE with quantity guard to prevent negative quantity & concurrency conflict
        final updatedCount = await (_db.update(_db.inventoryCostLayers)
              ..where((tbl) =>
                  tbl.uuid.equals(row.uuid) &
                  tbl.companyId.equals(effectiveCompanyId) &
                  tbl.remainingQty.isBiggerOrEqualValue(takeQty) &
                  tbl.closed.equals(0) &
                  tbl.deletedAt.isNull()))
            .write(
          InventoryCostLayersCompanion(
            remainingQty: Value(newRemaining),
            closed: Value(isClosed ? 1 : 0),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );

        if (updatedCount == 0) {
          // Concurrency conflict detected: abort WAC loop to prevent partial consumption
          throw JournalException(
            JournalException.concurrencyConflict,
            'Concurrent inventory consumption modified cost layer ${row.uuid}. Retrying consumption.',
          );
        }

        final lineCost = takeQty * unitCostToUse;
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
                companyId: Value(effectiveCompanyId),
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
            companyId: effectiveCompanyId,
          ),
        );
      }

      return LayerConsumptionResult(
        consumptions: consumptions,
        totalCost: totalCost,
        effectiveUnitCost: unitCostToUse,
        isShortage: false,
        shortageQty: 0.0,
      );
    });
  }

  @override
  Future<void> reverseConsumptions(String issueLineUuid) async {
    final effectiveCompanyId = _currentCompanyId;
    await _db.transaction(() async {
      final query = _db.select(_db.inventoryCostConsumptions)
        ..where((tbl) =>
            tbl.issueLineUuid.equals(issueLineUuid) &
            tbl.companyId.equals(effectiveCompanyId));
      final consumptions = await query.get();

      if (consumptions.isEmpty) {
        return;
      }

      for (final c in consumptions) {
        final layerQuery = _db.select(_db.inventoryCostLayers)
          ..where((tbl) =>
              tbl.uuid.equals(c.layerUuid) &
              tbl.companyId.equals(effectiveCompanyId));
        final layer = await layerQuery.getSingleOrNull();

        if (layer != null) {
          // Enforce invariant: restoredQty <= layer.receivedQty and remainingQty >= 0
          final maxAllowed = layer.receivedQty > 0 ? layer.receivedQty : double.infinity;
          final restoredQty = (layer.remainingQty + c.consumedQty).clamp(0.0, maxAllowed);
          final isClosed = restoredQty <= 0.000001;

          await (_db.update(_db.inventoryCostLayers)
                ..where((tbl) =>
                    tbl.uuid.equals(layer.uuid) &
                    tbl.companyId.equals(effectiveCompanyId)))
              .write(
            InventoryCostLayersCompanion(
              remainingQty: Value(restoredQty),
              closed: Value(isClosed ? 1 : 0),
              updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
            ),
          );
        }
      }

      // Delete consumption rows scoped by tenant
      await (_db.delete(_db.inventoryCostConsumptions)
            ..where((tbl) =>
                tbl.issueLineUuid.equals(issueLineUuid) &
                tbl.companyId.equals(effectiveCompanyId)))
          .go();
    });
  }

  @override
  Future<void> reverseLayer(String movementUuid) async {
    final effectiveCompanyId = _currentCompanyId;
    await _db.transaction(() async {
      final query = _db.select(_db.inventoryCostLayers)
        ..where((tbl) =>
            tbl.movementUuid.equals(movementUuid) &
            tbl.companyId.equals(effectiveCompanyId));
      final layers = await query.get();

      final now = DateTime.now().toUtc();
      for (final layer in layers) {
        // Orphan Consumption Guard: check if downstream consumptions exist for this layer
        final consumptions = await (_db.select(_db.inventoryCostConsumptions)
              ..where((tbl) =>
                  tbl.layerUuid.equals(layer.uuid) &
                  tbl.companyId.equals(effectiveCompanyId)))
            .get();

        if (consumptions.isNotEmpty || layer.remainingQty < layer.receivedQty - 0.000001) {
          throw JournalException(
            JournalException.dependencyViolation,
            'Cannot reverse or delete cost layer created by movement $movementUuid because downstream cost consumptions exist.',
          );
        }

        // Soft-delete the layer
        await (_db.update(_db.inventoryCostLayers)
              ..where((tbl) =>
                  tbl.uuid.equals(layer.uuid) &
                  tbl.companyId.equals(effectiveCompanyId)))
            .write(
          InventoryCostLayersCompanion(
            deletedAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            closed: const Value(1),
          ),
        );
      }
    });
  }

  @override
  Future<double> getWeightedAverageCost(
    String itemCode, {
    String? warehouseId,
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.companyId.equals(effectiveCompanyId) &
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
      return _getFallbackUnitCost(itemCode, companyId: effectiveCompanyId);
    }

    return totalValue / totalQty;
  }

  @override
  Future<List<CostLayer>> getOpenLayers(
    String itemCode, {
    String? warehouseId,
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.companyId.equals(effectiveCompanyId) &
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
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;
    var query = _db.select(_db.inventoryCostLayers)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.companyId.equals(effectiveCompanyId) &
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
            tbl.companyId.equals(effectiveCompanyId) &
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
      resolvedCost = await _getFallbackUnitCost(itemCode, companyId: effectiveCompanyId);
    }

    return resolvedCost;
  }

  Future<double> _getFallbackUnitCost(
    String itemCode, {
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;
    final query = _db.select(_db.products)
      ..where((tbl) =>
          tbl.itemCode.equals(itemCode) &
          tbl.companyId.equals(effectiveCompanyId));
    final product = await query.getSingleOrNull();
    if (product == null) return 0.0;
    return product.unitCost > 0 ? product.unitCost : 0.0;
  }
}
