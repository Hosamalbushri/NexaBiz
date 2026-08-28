import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../domain/entities/stock_transfer.dart';
import '../../domain/repositories/stock_transfer_repository.dart';

class StockTransferRepositoryImpl implements StockTransferRepository {
  StockTransferRepositoryImpl({
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

  static const transferEntityType = 'stock_transfer';

  @override
  Future<List<StockTransfer>> getAllTransfers() async {
    final query = _db.select(_db.stockTransfers)
      ..where((tbl) => tbl.deletedAt.isNull());
    final rows = await query.get();
    final results = <StockTransfer>[];

    for (final row in rows) {
      final lines = await _getLinesForTransfer(row.uuid);
      results.add(_mapRowToTransfer(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockTransfer>> watchAllTransfers() {
    final query = _db.select(_db.stockTransfers)
      ..where((tbl) => tbl.deletedAt.isNull());

    return query.watch().asyncMap((rows) async {
      final results = <StockTransfer>[];
      for (final row in rows) {
        final lines = await _getLinesForTransfer(row.uuid);
        results.add(_mapRowToTransfer(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockTransfer?> getTransferById(String id) async {
    final query = _db.select(_db.stockTransfers)
      ..where((tbl) => tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForTransfer(row.uuid);
    return _mapRowToTransfer(row, lines);
  }

  @override
  Future<void> saveTransfer(StockTransfer transfer) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.stockTransfers)
            ..where((tbl) => tbl.uuid.equals(transfer.id)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? transfer.version) + (existing == null ? 0 : 1);

      if (existing != null) {
        // Reverse previous transfer effects
        final oldLines = await _getLinesForTransfer(transfer.id);
        for (final line in oldLines) {
          await _costLayerService.reverseConsumptions(line.id);
          await _costLayerService.reverseLayer(line.id);
          await _adjustWhStock(line.itemCode, existing.fromWarehouseId, line.quantity);
          await _adjustWhStock(line.itemCode, existing.toWarehouseId, -line.quantity);
        }

        await (_db.update(_db.stockTransfers)..where((tbl) => tbl.uuid.equals(transfer.id))).write(
          StockTransfersCompanion(
            transferNumber: Value(transfer.transferNumber),
            fromWarehouseId: Value(transfer.fromWarehouseId),
            toWarehouseId: Value(transfer.toWarehouseId),
            transferDate: Value(transfer.transferDate.millisecondsSinceEpoch),
            notes: Value(transfer.notes),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(transfer.companyId),
          ),
        );
      } else {
        await _db.into(_db.stockTransfers).insert(
          StockTransfersCompanion(
            uuid: Value(transfer.id),
            transferNumber: Value(transfer.transferNumber),
            fromWarehouseId: Value(transfer.fromWarehouseId),
            toWarehouseId: Value(transfer.toWarehouseId),
            transferDate: Value(transfer.transferDate.millisecondsSinceEpoch),
            notes: Value(transfer.notes),
            createdAt: Value(transfer.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(transfer.companyId),
          ),
        );
      }

      // Re-insert lines
      await (_db.delete(_db.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(transfer.id)))
          .go();

      for (final line in transfer.lines) {
        // 1. Consume cost layers from source warehouse
        final consumptionResult = await _costLayerService.consumeLayers(
          itemCode: line.itemCode,
          quantity: line.quantity,
          method: _valuationMethod,
          issueLineUuid: line.id,
          movementType: 'transfer_out',
          warehouseId: transfer.fromWarehouseId,
          companyId: transfer.companyId,
        );

        final effectiveUnitCost = consumptionResult.effectiveUnitCost > 0
            ? consumptionResult.effectiveUnitCost
            : line.unitCost;
        final effectiveTotalCost = consumptionResult.totalCost > 0
            ? consumptionResult.totalCost
            : line.totalCost;

        // 2. Create new cost layer in destination warehouse
        await _costLayerService.createLayer(
          CostLayer(
            itemCode: line.itemCode,
            warehouseId: transfer.toWarehouseId,
            movementUuid: line.id,
            movementType: 'transfer_in',
            receivedDate: transfer.transferDate,
            receivedQty: line.quantity,
            unitCost: effectiveUnitCost,
            companyId: transfer.companyId,
          ),
        );

        // 3. Save movement line
        await _db.into(_db.stockMovementLines).insert(
              StockMovementLinesCompanion(
                uuid: Value(line.id),
                movementUuid: Value(transfer.id),
                movementType: const Value('transfer'),
                itemCode: Value(line.itemCode),
                itemName: Value(line.itemName),
                mainQuantity: Value(line.mainQuantity),
                subQuantity: Value(line.subQuantity),
                quantity: Value(line.quantity),
                unitCost: Value(effectiveUnitCost),
                totalCost: Value(effectiveTotalCost),
              ),
            );

        // 4. Deduct from source warehouse stock, add to destination warehouse stock
        await _adjustWhStock(line.itemCode, transfer.fromWarehouseId, -line.quantity);
        await _adjustWhStock(line.itemCode, transfer.toWarehouseId, line.quantity);
      }

      await _enqueueTransfer(
        transfer.copyWith(version: newVersion),
        existing == null ? SyncOperationType.create : SyncOperationType.update,
      );
    });
  }

  @override
  Future<void> deleteTransfer(String id) async {
    await _db.transaction(() async {
      final transfer = await getTransferById(id);
      if (transfer == null) return;

      final now = DateTime.now().toUtc();
      final newVersion = transfer.version + 1;

      // Soft delete header
      await (_db.update(_db.stockTransfers)..where((tbl) => tbl.uuid.equals(id))).write(
        StockTransfersCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(newVersion),
        ),
      );

      // Revert transfer line effects
      for (final line in transfer.lines) {
        await _costLayerService.reverseConsumptions(line.id);
        await _costLayerService.reverseLayer(line.id);
        await _adjustWhStock(line.itemCode, transfer.fromWarehouseId, line.quantity);
        await _adjustWhStock(line.itemCode, transfer.toWarehouseId, -line.quantity);
      }

      await _enqueueTransfer(
        transfer.copyWith(version: newVersion, deletedAt: now),
        SyncOperationType.delete,
      );
    });
  }

  Future<List<StockTransferLine>> _getLinesForTransfer(String transferUuid) async {
    final query = _db.select(_db.stockMovementLines)
      ..where((tbl) => tbl.movementUuid.equals(transferUuid) & tbl.movementType.equals('transfer'));
    final rows = await query.get();

    return rows
        .map(
          (row) => StockTransferLine(
            id: row.uuid,
            transferUuid: row.movementUuid,
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

  Future<void> _adjustWhStock(String itemCode, String warehouseId, double delta) async {
    final existing = await (_db.select(_db.productWarehouseStocks)
          ..where((tbl) => tbl.itemCode.equals(itemCode) & tbl.warehouseId.equals(warehouseId)))
        .getSingleOrNull();

    final now = DateTime.now().toUtc();
    if (existing != null) {
      final newQty = existing.onHandQty + delta;
      await (_db.update(_db.productWarehouseStocks)
            ..where((tbl) => tbl.uuid.equals(existing.uuid)))
          .write(
        ProductWarehouseStocksCompanion(
          onHandQty: Value(newQty),
          updatedAt: Value(now.millisecondsSinceEpoch),
          version: Value(existing.version + 1),
        ),
      );
    } else {
      await _db.into(_db.productWarehouseStocks).insert(
        ProductWarehouseStocksCompanion(
          uuid: Value(DateTime.now().microsecondsSinceEpoch.toString()),
          itemCode: Value(itemCode),
          warehouseId: Value(warehouseId),
          onHandQty: Value(delta),
          createdAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          version: const Value(1),
        ),
      );
    }
  }

  StockTransfer _mapRowToTransfer(StockTransferRow row, List<StockTransferLine> lines) {
    return StockTransfer(
      id: row.uuid,
      transferNumber: row.transferNumber,
      fromWarehouseId: row.fromWarehouseId,
      toWarehouseId: row.toWarehouseId,
      transferDate: DateTime.fromMillisecondsSinceEpoch(row.transferDate, isUtc: true),
      notes: row.notes,
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

  Future<void> _enqueueTransfer(StockTransfer transfer, SyncOperationType type) async {
    if (_syncQueue == null) return;

    final payload = {
      'uuid': transfer.id,
      'transfer_number': transfer.transferNumber,
      'from_warehouse_id': transfer.fromWarehouseId,
      'to_warehouse_id': transfer.toWarehouseId,
      'transfer_date': transfer.transferDate.millisecondsSinceEpoch,
      'notes': transfer.notes,
      'version': transfer.version,
      'company_id': transfer.companyId,
      'lines': transfer.lines
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
      entityType: transferEntityType,
      entityId: transfer.id,
      type: type,
      baseVersion: transfer.version,
      payload: payload,
    );

    await _syncQueue.enqueue(syncOp);
  }
}
