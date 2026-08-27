import 'package:drift/drift.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../../shared/data/database/inventory_database.dart';
import '../../domain/entities/cost_layer.dart';
import '../../domain/entities/stock_movement_line.dart';
import '../../domain/entities/stock_return.dart';
import '../../domain/enums/cost_valuation_method.dart';
import '../../domain/repositories/stock_returns_repository.dart';
import '../../domain/services/cost_layer_service.dart';
import '../services/cost_layer_service_impl.dart';

class StockReturnsRepositoryImpl implements StockReturnsRepository {
  StockReturnsRepositoryImpl({
    required InventoryDatabase db,
    SyncQueue? syncQueue,
    CostLayerService? costLayerService,
    CostValuationMethod valuationMethod = CostValuationMethod.fifo,
  })  : _db = db,
        _syncQueue = syncQueue,
        _costLayerService = costLayerService ?? CostLayerServiceImpl(db: db),
        _valuationMethod = valuationMethod;

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;
  final CostLayerService _costLayerService;
  final CostValuationMethod _valuationMethod;

  static const returnEntityType = 'stock_return';

  @override
  Future<List<StockReturn>> getAllReturns() async {
    final query = _db.select(_db.stockReturns)
      ..where((tbl) => tbl.deletedAt.isNull());
    final rows = await query.get();
    final results = <StockReturn>[];

    for (final row in rows) {
      final lines = await _getLinesForMovement(row.uuid, row.returnType);
      results.add(_mapRowToReturn(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockReturn>> watchAllReturns() {
    final query = _db.select(_db.stockReturns)
      ..where((tbl) => tbl.deletedAt.isNull());

    return query.watch().asyncMap((rows) async {
      final results = <StockReturn>[];
      for (final row in rows) {
        final lines = await _getLinesForMovement(row.uuid, row.returnType);
        results.add(_mapRowToReturn(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockReturn?> getReturnById(String id) async {
    final query = _db.select(_db.stockReturns)
      ..where((tbl) => tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForMovement(row.uuid, row.returnType);
    return _mapRowToReturn(row, lines);
  }

  @override
  Future<void> saveReturn(StockReturn returnDoc) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.stockReturns)
            ..where((tbl) => tbl.uuid.equals(returnDoc.id)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? returnDoc.version) + (existing == null ? 0 : 1);
      final returnTypeStr = returnDoc.isPurchaseReturn ? 'purchase_return' : 'sales_return';

      // Save header
      if (existing != null) {
        await (_db.update(_db.stockReturns)..where((tbl) => tbl.uuid.equals(returnDoc.id))).write(
          StockReturnsCompanion(
            returnNumber: Value(returnDoc.returnNumber),
            returnType: Value(returnTypeStr),
            originalMovementUuid: Value(returnDoc.originalMovementUuid),
            partyName: Value(returnDoc.partyName),
            warehouse: Value(returnDoc.warehouse),
            notes: Value(returnDoc.notes),
            returnDate: Value(returnDoc.returnDate.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(returnDoc.companyId),
          ),
        );

        // Reverse prior effects if editing existing
        if (returnDoc.isSalesReturn) {
          await _costLayerService.reverseLayer(returnDoc.id);
          final oldLines = await _getLinesForMovement(returnDoc.id, returnTypeStr);
          for (final line in oldLines) {
            await _adjustProductQty(line.itemCode, -line.quantity);
          }
        } else {
          final oldLines = await _getLinesForMovement(returnDoc.id, returnTypeStr);
          for (final line in oldLines) {
            await _costLayerService.reverseConsumptions(line.id);
            await _adjustProductQty(line.itemCode, line.quantity);
          }
        }
      } else {
        await _db.into(_db.stockReturns).insert(
          StockReturnsCompanion(
            uuid: Value(returnDoc.id),
            returnNumber: Value(returnDoc.returnNumber),
            returnType: Value(returnTypeStr),
            originalMovementUuid: Value(returnDoc.originalMovementUuid),
            partyName: Value(returnDoc.partyName),
            warehouse: Value(returnDoc.warehouse),
            notes: Value(returnDoc.notes),
            returnDate: Value(returnDoc.returnDate.millisecondsSinceEpoch),
            createdAt: Value(returnDoc.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(returnDoc.companyId),
          ),
        );
      }

      // Re-insert lines
      await (_db.delete(_db.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(returnDoc.id)))
          .go();

      for (final line in returnDoc.lines) {
        if (returnDoc.isSalesReturn) {
          // Sales Return: Goods return into stock -> create a new cost layer
          await _db.into(_db.stockMovementLines).insert(
                StockMovementLinesCompanion(
                  uuid: Value(line.id),
                  movementUuid: Value(returnDoc.id),
                  movementType: Value(returnTypeStr),
                  itemCode: Value(line.itemCode),
                  itemName: Value(line.itemName),
                  mainQuantity: Value(line.mainQuantity),
                  subQuantity: Value(line.subQuantity),
                  quantity: Value(line.quantity),
                  unitCost: Value(line.unitCost),
                  totalCost: Value(line.totalCost),
                ),
              );

          await _costLayerService.createLayer(
            CostLayer(
              itemCode: line.itemCode,
              movementUuid: returnDoc.id,
              movementType: returnTypeStr,
              receivedDate: returnDoc.returnDate,
              receivedQty: line.quantity,
              unitCost: line.unitCost,
              companyId: returnDoc.companyId,
            ),
          );

          await _adjustProductQty(line.itemCode, line.quantity);
        } else {
          // Purchase Return: Goods leave stock back to supplier -> consume active cost layers
          final consumptionResult = await _costLayerService.consumeLayers(
            itemCode: line.itemCode,
            quantity: line.quantity,
            method: _valuationMethod,
            issueLineUuid: line.id,
            movementType: returnTypeStr,
            warehouseId: returnDoc.warehouse,
            companyId: returnDoc.companyId,
          );

          final effectiveUnitCost = consumptionResult.effectiveUnitCost > 0
              ? consumptionResult.effectiveUnitCost
              : line.unitCost;
          final effectiveTotalCost = consumptionResult.totalCost > 0
              ? consumptionResult.totalCost
              : line.totalCost;

          await _db.into(_db.stockMovementLines).insert(
                StockMovementLinesCompanion(
                  uuid: Value(line.id),
                  movementUuid: Value(returnDoc.id),
                  movementType: Value(returnTypeStr),
                  itemCode: Value(line.itemCode),
                  itemName: Value(line.itemName),
                  mainQuantity: Value(line.mainQuantity),
                  subQuantity: Value(line.subQuantity),
                  quantity: Value(line.quantity),
                  unitCost: Value(effectiveUnitCost),
                  totalCost: Value(effectiveTotalCost),
                ),
              );

          await _adjustProductQty(line.itemCode, -line.quantity);
        }
      }

      await _enqueueReturn(returnDoc.copyWith(version: newVersion), existing == null ? SyncOperationType.create : SyncOperationType.update);
    });
  }

  @override
  Future<void> deleteReturn(String id) async {
    await _db.transaction(() async {
      final returnDoc = await getReturnById(id);
      if (returnDoc == null) return;

      final now = DateTime.now().toUtc();
      final returnTypeStr = returnDoc.isPurchaseReturn ? 'purchase_return' : 'sales_return';

      // Soft delete header
      await (_db.update(_db.stockReturns)..where((tbl) => tbl.uuid.equals(id))).write(
        StockReturnsCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(returnDoc.version + 1),
        ),
      );

      if (returnDoc.isSalesReturn) {
        await _costLayerService.reverseLayer(id);
        for (final line in returnDoc.lines) {
          await _adjustProductQty(line.itemCode, -line.quantity);
        }
      } else {
        for (final line in returnDoc.lines) {
          await _costLayerService.reverseConsumptions(line.id);
          await _adjustProductQty(line.itemCode, line.quantity);
        }
      }

      await _enqueueReturn(returnDoc.copyWith(version: returnDoc.version + 1, deletedAt: now), SyncOperationType.delete);
    });
  }

  Future<List<StockMovementLine>> _getLinesForMovement(String movementUuid, String type) async {
    final query = _db.select(_db.stockMovementLines)
      ..where((tbl) => tbl.movementUuid.equals(movementUuid) & tbl.movementType.equals(type));
    final rows = await query.get();

    return rows
        .map(
          (row) => StockMovementLine(
            id: row.uuid,
            movementUuid: row.movementUuid,
            movementType: row.movementType,
            itemCode: row.itemCode,
            itemName: row.itemName,
            mainQuantity: row.mainQuantity,
            subQuantity: row.subQuantity,
            quantity: row.quantity,
            unitCost: row.unitCost,
            totalCost: row.totalCost,
          ),
        )
        .toList();
  }

  Future<void> _adjustProductQty(String itemCode, double delta) async {
    final product = await (_db.select(_db.products)..where((tbl) => tbl.itemCode.equals(itemCode))).getSingleOrNull();

    if (product != null) {
      final newQty = product.onHandQty + delta;
      final updatedUnitCost = await _costLayerService.getWeightedAverageCost(itemCode);
      await (_db.update(_db.products)..where((tbl) => tbl.itemCode.equals(itemCode))).write(
        ProductsCompanion(
          onHandQty: Value(newQty),
          unitCost: Value(updatedUnitCost > 0 ? updatedUnitCost : product.unitCost),
          updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    }
  }

  StockReturn _mapRowToReturn(StockReturnRow row, List<StockMovementLine> lines) {
    final isSales = row.returnType == 'sales_return';
    return StockReturn(
      id: row.uuid,
      returnNumber: row.returnNumber,
      returnType: isSales ? StockReturnType.salesReturn : StockReturnType.purchaseReturn,
      originalMovementUuid: row.originalMovementUuid,
      partyName: row.partyName,
      warehouse: row.warehouse,
      notes: row.notes,
      returnDate: DateTime.fromMillisecondsSinceEpoch(row.returnDate, isUtc: true),
      lines: lines,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Future<void> _enqueueReturn(StockReturn returnDoc, SyncOperationType type) async {
    if (_syncQueue == null) return;

    final payload = {
      'uuid': returnDoc.id,
      'return_number': returnDoc.returnNumber,
      'return_type': returnDoc.isSalesReturn ? 'sales_return' : 'purchase_return',
      'original_movement_uuid': returnDoc.originalMovementUuid,
      'party_name': returnDoc.partyName,
      'warehouse': returnDoc.warehouse,
      'notes': returnDoc.notes,
      'return_date': returnDoc.returnDate.millisecondsSinceEpoch,
      'version': returnDoc.version,
      'company_id': returnDoc.companyId,
      'lines': returnDoc.lines
          .map(
            (line) => {
              'uuid': line.id,
              'item_code': line.itemCode,
              'item_name': line.itemName,
              'main_quantity': line.mainQuantity,
              'sub_quantity': line.subQuantity,
              'quantity': line.quantity,
              'unit_cost': line.unitCost,
              'total_cost': line.totalCost,
            },
          )
          .toList(),
    };

    final syncOp = SyncOperation.create(
      entityType: returnEntityType,
      entityId: returnDoc.id,
      type: type,
      baseVersion: returnDoc.version,
      payload: payload,
    );

    await _syncQueue.enqueue(syncOp);
  }
}
