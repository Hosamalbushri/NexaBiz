// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../../shared/data/database/inventory_database.dart';
import '../../domain/entities/cost_layer.dart';
import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_movement_line.dart';
import '../../domain/entities/stock_receipt.dart';
import '../../domain/enums/cost_valuation_method.dart';
import '../../domain/repositories/stock_movements_repository.dart';
import '../../domain/services/cost_layer_service.dart';
import '../services/cost_layer_service_impl.dart';

class StockMovementsRepositoryImpl implements StockMovementsRepository {
  StockMovementsRepositoryImpl({
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

  static const receiptEntityType = 'stock_receipt';
  static const issueEntityType = 'stock_issue';

  // ---------------------------------------------------------------------------
  // RECEIPTS
  // ---------------------------------------------------------------------------

  @override
  Future<List<StockReceipt>> getAllReceipts() async {
    final query = _db.select(_db.stockReceipts)
      ..where((tbl) => tbl.deletedAt.isNull());
    final rows = await query.get();
    final results = <StockReceipt>[];

    for (final row in rows) {
      final lines = await _getLinesForMovement(row.uuid, 'receipt');
      results.add(_mapRowToReceipt(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockReceipt>> watchAllReceipts() {
    final query = _db.select(_db.stockReceipts)
      ..where((tbl) => tbl.deletedAt.isNull());

    return query.watch().asyncMap((rows) async {
      final results = <StockReceipt>[];
      for (final row in rows) {
        final lines = await _getLinesForMovement(row.uuid, 'receipt');
        results.add(_mapRowToReceipt(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockReceipt?> getReceiptById(String id) async {
    final query = _db.select(_db.stockReceipts)
      ..where((tbl) => tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForMovement(row.uuid, 'receipt');
    return _mapRowToReceipt(row, lines);
  }

  @override
  Future<void> saveReceipt(StockReceipt receipt) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(receipt.id)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? receipt.version) + (existing == null ? 0 : 1);

      // Save header
      if (existing != null) {
        await (_db.update(_db.stockReceipts)..where((tbl) => tbl.uuid.equals(receipt.id))).write(
          StockReceiptsCompanion(
            receiptNumber: Value(receipt.receiptNumber),
            supplier: Value(receipt.supplier),
            currencyCode: Value(receipt.currencyCode),
            exchangeRate: Value(receipt.exchangeRate),
            notes: Value(receipt.notes),
            receiptDate: Value(receipt.receiptDate.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(receipt.companyId),
          ),
        );
      } else {
        await _db.into(_db.stockReceipts).insert(
          StockReceiptsCompanion(
            uuid: Value(receipt.id),
            receiptNumber: Value(receipt.receiptNumber),
            supplier: Value(receipt.supplier),
            currencyCode: Value(receipt.currencyCode),
            exchangeRate: Value(receipt.exchangeRate),
            notes: Value(receipt.notes),
            receiptDate: Value(receipt.receiptDate.millisecondsSinceEpoch),
            createdAt: Value(receipt.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(receipt.companyId),
          ),
        );
      }

      // Manage product stock quantity adjustments & cost layers
      if (existing != null) {
        await _costLayerService.reverseLayer(receipt.id);
        final oldLines = await _getLinesForMovement(receipt.id, 'receipt');
        for (final line in oldLines) {
          await _adjustProductQty(line.itemCode, -line.quantity);
        }
      }

      // Re-insert lines
      await (_db.delete(_db.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(receipt.id)))
          .go();

      for (final line in receipt.lines) {
        await _db.into(_db.stockMovementLines).insert(
              StockMovementLinesCompanion(
                uuid: Value(line.id),
                movementUuid: Value(receipt.id),
                movementType: const Value('receipt'),
                itemCode: Value(line.itemCode),
                itemName: Value(line.itemName),
                mainQuantity: Value(line.mainQuantity),
                subQuantity: Value(line.subQuantity),
                quantity: Value(line.quantity),
                unitCost: Value(line.unitCost),
                totalCost: Value(line.totalCost),
              ),
            );

        // Create cost layer for incoming receipt line
        await _costLayerService.createLayer(
          CostLayer(
            itemCode: line.itemCode,
            movementUuid: receipt.id,
            movementType: 'receipt',
            receivedDate: receipt.receiptDate,
            receivedQty: line.quantity,
            unitCost: line.unitCost,
            companyId: receipt.companyId,
          ),
        );

        // Add quantity to product stock
        await _adjustProductQty(line.itemCode, line.quantity, warehouseId: receipt.warehouse);
      }

      // Sync queue
      await _enqueueReceipt(receipt.copyWith(version: newVersion), existing == null ? SyncOperationType.create : SyncOperationType.update);
    });
  }

  @override
  Future<void> deleteReceipt(String id) async {
    await _db.transaction(() async {
      final receipt = await getReceiptById(id);
      if (receipt == null) return;

      final now = DateTime.now().toUtc();

      // Reverse cost layers created by this receipt
      await _costLayerService.reverseLayer(id);

      // Soft delete header
      await (_db.update(_db.stockReceipts)..where((tbl) => tbl.uuid.equals(id))).write(
        StockReceiptsCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(receipt.version + 1),
        ),
      );

      // Revert product stock quantities
      for (final line in receipt.lines) {
        await _adjustProductQty(line.itemCode, -line.quantity, warehouseId: receipt.warehouse);
      }

      await _enqueueReceipt(receipt.copyWith(version: receipt.version + 1, deletedAt: now), SyncOperationType.delete);
    });
  }

  // ---------------------------------------------------------------------------
  // ISSUES
  // ---------------------------------------------------------------------------

  @override
  Future<List<StockIssue>> getAllIssues() async {
    final query = _db.select(_db.stockIssues)
      ..where((tbl) => tbl.deletedAt.isNull());
    final rows = await query.get();
    final results = <StockIssue>[];

    for (final row in rows) {
      final lines = await _getLinesForMovement(row.uuid, 'issue');
      results.add(_mapRowToIssue(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockIssue>> watchAllIssues() {
    final query = _db.select(_db.stockIssues)
      ..where((tbl) => tbl.deletedAt.isNull());

    return query.watch().asyncMap((rows) async {
      final results = <StockIssue>[];
      for (final row in rows) {
        final lines = await _getLinesForMovement(row.uuid, 'issue');
        results.add(_mapRowToIssue(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockIssue?> getIssueById(String id) async {
    final query = _db.select(_db.stockIssues)
      ..where((tbl) => tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForMovement(row.uuid, 'issue');
    return _mapRowToIssue(row, lines);
  }

  @override
  Future<void> saveIssue(StockIssue issue) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.stockIssues)
            ..where((tbl) => tbl.uuid.equals(issue.id)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? issue.version) + (existing == null ? 0 : 1);

      // Save header
      if (existing != null) {
        await (_db.update(_db.stockIssues)..where((tbl) => tbl.uuid.equals(issue.id))).write(
          StockIssuesCompanion(
            issueNumber: Value(issue.issueNumber),
            destination: Value(issue.destination),
            accountId: Value(issue.accountId),
            accountName: Value(issue.accountName),
            currencyCode: Value(issue.currencyCode),
            exchangeRate: Value(issue.exchangeRate),
            voucherBookId: Value(issue.voucherBookId),
            warehouse: Value(issue.warehouse),
            notes: Value(issue.notes),
            issueDate: Value(issue.issueDate.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(issue.companyId),
          ),
        );
      } else {
        await _db.into(_db.stockIssues).insert(
          StockIssuesCompanion(
            uuid: Value(issue.id),
            issueNumber: Value(issue.issueNumber),
            destination: Value(issue.destination),
            accountId: Value(issue.accountId),
            accountName: Value(issue.accountName),
            currencyCode: Value(issue.currencyCode),
            exchangeRate: Value(issue.exchangeRate),
            voucherBookId: Value(issue.voucherBookId),
            warehouse: Value(issue.warehouse),
            notes: Value(issue.notes),
            issueDate: Value(issue.issueDate.millisecondsSinceEpoch),
            createdAt: Value(issue.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(issue.companyId),
          ),
        );
      }

      // Revert product quantities & cost layer consumptions if modifying existing
      if (existing != null) {
        final oldLines = await _getLinesForMovement(issue.id, 'issue');
        for (final line in oldLines) {
          await _costLayerService.reverseConsumptions(line.id);
          await _adjustProductQty(line.itemCode, line.quantity);
        }
      }

      // Re-insert lines
      await (_db.delete(_db.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(issue.id)))
          .go();

      for (final line in issue.lines) {
        // Consume from active cost layers according to configured valuation method
        final consumptionResult = await _costLayerService.consumeLayers(
          itemCode: line.itemCode,
          quantity: line.quantity,
          method: _valuationMethod,
          issueLineUuid: line.id,
          movementType: 'issue',
          warehouseId: issue.warehouse,
          companyId: issue.companyId,
        );

        final calculatedUnitCost = consumptionResult.effectiveUnitCost > 0
            ? consumptionResult.effectiveUnitCost
            : line.unitCost;
        final calculatedTotalCost = consumptionResult.totalCost > 0
            ? consumptionResult.totalCost
            : line.totalCost;

        await _db.into(_db.stockMovementLines).insert(
              StockMovementLinesCompanion(
                uuid: Value(line.id),
                movementUuid: Value(issue.id),
                movementType: const Value('issue'),
                itemCode: Value(line.itemCode),
                itemName: Value(line.itemName),
                mainQuantity: Value(line.mainQuantity),
                subQuantity: Value(line.subQuantity),
                quantity: Value(line.quantity),
                unitCost: Value(calculatedUnitCost),
                totalCost: Value(calculatedTotalCost),
              ),
            );

        // Deduct quantity from product stock
        await _adjustProductQty(line.itemCode, -line.quantity, warehouseId: issue.warehouse);
      }

      // Sync queue
      await _enqueueIssue(issue.copyWith(version: newVersion), existing == null ? SyncOperationType.create : SyncOperationType.update);
    });
  }

  @override
  Future<void> deleteIssue(String id) async {
    await _db.transaction(() async {
      final issue = await getIssueById(id);
      if (issue == null) return;

      final now = DateTime.now().toUtc();

      // Soft delete header
      await (_db.update(_db.stockIssues)..where((tbl) => tbl.uuid.equals(id))).write(
        StockIssuesCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(issue.version + 1),
        ),
      );

      // Revert product stock quantities and cost layer consumptions
      for (final line in issue.lines) {
        await _costLayerService.reverseConsumptions(line.id);
        await _adjustProductQty(line.itemCode, line.quantity, warehouseId: issue.warehouse);
      }

      await _enqueueIssue(issue.copyWith(version: issue.version + 1, deletedAt: now), SyncOperationType.delete);
    });
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

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

  Future<void> _adjustProductQty(String itemCode, double delta, {String? warehouseId}) async {
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

    if (warehouseId != null && warehouseId.isNotEmpty) {
      final existingWhStock = await (_db.select(_db.productWarehouseStocks)
            ..where((tbl) => tbl.itemCode.equals(itemCode) & tbl.warehouseId.equals(warehouseId)))
          .getSingleOrNull();

      final now = DateTime.now().toUtc();
      if (existingWhStock != null) {
        final newWhQty = existingWhStock.onHandQty + delta;
        await (_db.update(_db.productWarehouseStocks)
              ..where((tbl) => tbl.uuid.equals(existingWhStock.uuid)))
            .write(
          ProductWarehouseStocksCompanion(
            onHandQty: Value(newWhQty),
            updatedAt: Value(now.millisecondsSinceEpoch),
            version: Value(existingWhStock.version + 1),
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
  }

  StockReceipt _mapRowToReceipt(StockReceiptRow row, List<StockMovementLine> lines) {
    return StockReceipt(
      id: row.uuid,
      receiptNumber: row.receiptNumber,
      supplier: row.supplier,
      currencyCode: row.currencyCode,
      exchangeRate: row.exchangeRate,
      notes: row.notes,
      receiptDate: DateTime.fromMillisecondsSinceEpoch(row.receiptDate, isUtc: true),
      lines: lines,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == row.syncStatus,
        orElse: () => SyncStatus.synced,
      ),
      lastSyncedAt: row.lastSyncedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  StockIssue _mapRowToIssue(StockIssueRow row, List<StockMovementLine> lines) {
    return StockIssue(
      id: row.uuid,
      issueNumber: row.issueNumber,
      destination: row.destination,
      accountId: row.accountId,
      accountName: row.accountName,
      currencyCode: row.currencyCode,
      exchangeRate: row.exchangeRate,
      voucherBookId: row.voucherBookId,
      warehouse: row.warehouse,
      notes: row.notes,
      issueDate: DateTime.fromMillisecondsSinceEpoch(row.issueDate, isUtc: true),
      lines: lines,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == row.syncStatus,
        orElse: () => SyncStatus.synced,
      ),
      lastSyncedAt: row.lastSyncedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Future<void> _enqueueReceipt(StockReceipt receipt, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) return;

    await queue.enqueue(
      SyncOperation.create(
        entityType: receiptEntityType,
        entityId: receipt.id,
        type: type,
        baseVersion: receipt.version,
        payload: {
          'id': receipt.id,
          'receiptNumber': receipt.receiptNumber,
          'supplier': receipt.supplier,
          'notes': receipt.notes,
          'receiptDate': receipt.receiptDate.toUtc().millisecondsSinceEpoch,
          'lines': receipt.lines
              .map(
                (l) => {
                  'id': l.id,
                  'itemCode': l.itemCode,
                  'itemName': l.itemName,
                  'quantity': l.quantity,
                  'unitCost': l.unitCost,
                  'totalCost': l.totalCost,
                },
              )
              .toList(),
          'version': receipt.version,
          'updatedAt': receipt.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': receipt.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  Future<void> _enqueueIssue(StockIssue issue, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) return;

    await queue.enqueue(
      SyncOperation.create(
        entityType: issueEntityType,
        entityId: issue.id,
        type: type,
        baseVersion: issue.version,
        payload: {
          'id': issue.id,
          'issueNumber': issue.issueNumber,
          'destination': issue.destination,
          'notes': issue.notes,
          'issueDate': issue.issueDate.toUtc().millisecondsSinceEpoch,
          'lines': issue.lines
              .map(
                (l) => {
                  'id': l.id,
                  'itemCode': l.itemCode,
                  'itemName': l.itemName,
                  'quantity': l.quantity,
                  'unitCost': l.unitCost,
                  'totalCost': l.totalCost,
                },
              )
              .toList(),
          'version': issue.version,
          'updatedAt': issue.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': issue.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }
}
