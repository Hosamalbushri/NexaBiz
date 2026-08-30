import 'package:drift/drift.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/sync/sync.dart';

import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import '../../../shared/data/database/inventory_database.dart';
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
    String Function()? readCompanyId,
  })  : _db = db,
        _syncQueue = syncQueue,
        _costLayerService = costLayerService ?? CostLayerServiceImpl(db: db, readCompanyId: readCompanyId),
        _valuationMethod = valuationMethod,
        _readCompanyId = readCompanyId;

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;
  final CostLayerService _costLayerService;
  final CostValuationMethod _valuationMethod;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Expression<bool> _scoped($StockReturnsTable tbl) {
    return tbl.companyId.equals(_currentCompanyId);
  }

  static const returnEntityType = 'stock_return';

  @override
  Future<List<StockReturn>> getAllReturns() async {
    final query = _db.select(_db.stockReturns)
      ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull());
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
      ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull());

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
      ..where((tbl) => _scoped(tbl) & tbl.uuid.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForMovement(row.uuid, row.returnType);
    return _mapRowToReturn(row, lines);
  }

  @override
  Future<void> saveReturn(StockReturn returnDoc) async {
    await _db.transaction(() async {
      // 1. Cross-tenant modification rejection
      if (returnDoc.companyId != null &&
          returnDoc.companyId!.isNotEmpty &&
          returnDoc.companyId != _currentCompanyId) {
        throw const JournalException(JournalException.notFound);
      }

      final existing = await (_db.select(_db.stockReturns)
            ..where((tbl) => _scoped(tbl) & tbl.uuid.equals(returnDoc.id)))
          .getSingleOrNull();

      // Prevent cross-tenant record overwrite
      if (existing == null) {
        final crossTenantCheck = await (_db.select(_db.stockReturns)
              ..where((tbl) => tbl.uuid.equals(returnDoc.id)))
            .getSingleOrNull();
        if (crossTenantCheck != null) {
          throw const JournalException(JournalException.notFound);
        }
      }

      // 2. POSTED IMMUTABILITY GUARD: Reject edits to posted returns
      if (existing != null && (existing.status == 'posted' || existing.postedAt != null)) {
        throw const JournalException(JournalException.postedImmutable);
      }
      if (returnDoc.isPosted && existing != null && existing.status == 'posted') {
        throw const JournalException(JournalException.postedImmutable);
      }

      final now = DateTime.now().toUtc();
      final newVersion = (existing?.version ?? returnDoc.version) + (existing == null ? 0 : 1);
      final returnTypeStr = returnDoc.isPurchaseReturn ? 'purchase_return' : 'sales_return';
      final effectiveCompanyId = returnDoc.companyId ?? _currentCompanyId;

      // Save header
      if (existing != null) {
        await (_db.update(_db.stockReturns)..where((tbl) => _scoped(tbl) & tbl.uuid.equals(returnDoc.id))).write(
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
            companyId: Value(effectiveCompanyId),
            status: Value(returnDoc.status.name),
            postedAt: Value(returnDoc.postedAt?.millisecondsSinceEpoch),
          ),
        );

        // Reverse prior draft effects if editing existing draft
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
            companyId: Value(effectiveCompanyId),
            status: Value(returnDoc.status.name),
            postedAt: Value(returnDoc.postedAt?.millisecondsSinceEpoch),
          ),
        );
      }

      // Re-insert lines
      await (_db.delete(_db.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(returnDoc.id)))
          .go();

      for (final line in returnDoc.lines) {
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
      }

      if (returnDoc.isPosted) {
        if (returnDoc.isSalesReturn) {
          for (final line in returnDoc.lines) {
            final layer = CostLayer(
              id: generateUuidV4(),
              itemCode: line.itemCode,
              movementUuid: returnDoc.id,
              movementType: 'sales_return',
              receivedDate: returnDoc.returnDate,
              receivedQty: line.quantity,
              unitCost: line.unitCost,
              totalCost: line.totalCost,
              companyId: effectiveCompanyId,
            );
            await _costLayerService.createLayer(layer);
            await _adjustProductQty(line.itemCode, line.quantity);
          }
        } else {
          for (final line in returnDoc.lines) {
            await _costLayerService.consumeLayers(
              itemCode: line.itemCode,
              quantity: line.quantity,
              method: _valuationMethod,
              issueLineUuid: line.id,
              movementType: 'purchase_return',
              companyId: effectiveCompanyId,
            );
            await _adjustProductQty(line.itemCode, -line.quantity);
          }
        }
      }

      await _enqueueReturn(returnDoc.copyWith(version: newVersion, companyId: effectiveCompanyId), existing == null ? SyncOperationType.create : SyncOperationType.update);
    });
  }

  @override
  Future<void> deleteReturn(String id) async {
    await _db.transaction(() async {
      final returnDoc = await getReturnById(id);
      if (returnDoc == null) {
        throw const JournalException(JournalException.notFound);
      }

      // POSTED IMMUTABILITY GUARD: Reject soft-deletion of posted stock returns
      if (returnDoc.isPosted) {
        throw const JournalException(JournalException.postedImmutable);
      }

      final now = DateTime.now().toUtc();
      final returnTypeStr = returnDoc.isPurchaseReturn ? 'purchase_return' : 'sales_return';

      // Soft delete header with scoped query
      await (_db.update(_db.stockReturns)..where((tbl) => _scoped(tbl) & tbl.uuid.equals(id))).write(
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
    final product = await (_db.select(_db.products)
          ..where((tbl) =>
              tbl.itemCode.equals(itemCode) &
              (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull())))
        .getSingleOrNull();

    if (product != null) {
      final newQty = product.onHandQty + delta;
      final updatedUnitCost = await _costLayerService.getWeightedAverageCost(itemCode);
      await (_db.update(_db.products)
            ..where((tbl) =>
                tbl.itemCode.equals(itemCode) &
                (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull())))
          .write(
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
      status: InventoryDocumentStatus.fromStorage(row.status),
      postedAt: row.postedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.postedAt!, isUtc: true),
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
