// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/core/sync/sync_core.dart';

import '../../domain/entities/stock_transfer.dart';
import '../../domain/repositories/stock_transfer_repository.dart';

import 'package:stock_count/core/setup/setup_core.dart';

class StockTransferRepositoryImpl implements StockTransferRepository {
  StockTransferRepositoryImpl({
    required NexabizDatabase db,
    SyncQueue? syncQueue,
    String Function()? readCompanyId,
    InitializationGuard? initializationGuard,
  })  : _db = db,
        _syncQueue = syncQueue,
        _readCompanyId = readCompanyId,
        _initializationGuard = initializationGuard;

  final NexabizDatabase _db;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;
  final InitializationGuard? _initializationGuard;

  String get _currentCompanyId {
    final raw = _readCompanyId?.call();
    final cid = raw?.trim();
    if (cid == null || cid.isEmpty) {
      throw MissingCompanyContextException(
        'StockTransferRepository operation failed: missing company context.',
      );
    }
    return cid;
  }

  Expression<bool> _scoped($StockTransfersTable tbl) {
    return tbl.companyId.equals(_currentCompanyId);
  }

  static const transferEntityType = 'stock_transfer';

  @override
  Future<List<StockTransfer>> getAllTransfers() async {
    final query = _db.select(_db.stockTransfers)
      ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull());
    final rows = await query.get();
    final results = <StockTransfer>[];

    for (final row in rows) {
      final lines = await _getLinesForTransfer(row.id);
      results.add(_mapRowToTransfer(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockTransfer>> watchAllTransfers() {
    final query = _db.select(_db.stockTransfers)
      ..where((tbl) => _scoped(tbl) & tbl.deletedAt.isNull());

    return query.watch().asyncMap((rows) async {
      final results = <StockTransfer>[];
      for (final row in rows) {
        final lines = await _getLinesForTransfer(row.id);
        results.add(_mapRowToTransfer(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockTransfer?> getTransferById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final query = _db.select(_db.stockTransfers)
      ..where(
        (tbl) => _scoped(tbl) & tbl.id.equals(trimmed) & tbl.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForTransfer(row.id);
    return _mapRowToTransfer(row, lines);
  }

  @override
  Future<void> saveTransfer(StockTransfer transfer) async {
    await _initializationGuard?.assertInitialized();
    if (transfer.fromWarehouseId == transfer.toWarehouseId) {
      throw StateError(
        'لا يمكن إجراء تحويل بين نفس المستودع (${transfer.fromWarehouseId}).',
      );
    }

    await _db.transaction(() async {
      final effectiveCompanyId = transfer.companyId ?? _currentCompanyId;

      // Multi-tenant warehouse ownership validation
      final whs =
          await (_db.select(_db.warehouses)..where(
                (tbl) => tbl.id.isIn([
                  transfer.fromWarehouseId,
                  transfer.toWarehouseId,
                ]),
              ))
              .get();

      for (final wh in whs) {
        if (wh.companyId.isNotEmpty && wh.companyId != effectiveCompanyId) {
          throw StateError(
            'لا يمكن نقل المخزون بين مستودعات تابعة لشركات مختلفة.',
          );
        }
      }

      final existing =
          await (_db.select(_db.stockTransfers)
                ..where((tbl) => _scoped(tbl) & tbl.id.equals(transfer.id)))
              .getSingleOrNull();

      if (existing != null) {
        if (existing.status == 'posted' || existing.postedAt != null) {
          throw const JournalException(JournalException.postedImmutable);
        }
        if (existing.status == 'cancelled') {
          throw const JournalException(
            JournalException.cancelledImmutable,
            'لا يمكن تعديل مستند تحويل ملغي.',
          );
        }
      }

      final now = DateTime.now().toUtc();
      final newVersion =
          (existing?.version ?? transfer.version) + (existing == null ? 0 : 1);

      if (existing != null) {
        await (_db.update(
          _db.stockTransfers,
        )..where((tbl) => _scoped(tbl) & tbl.id.equals(transfer.id))).write(
          StockTransfersCompanion(
            transferNumber: Value(transfer.transferNumber),
            fromWarehouseId: Value(transfer.fromWarehouseId),
            toWarehouseId: Value(transfer.toWarehouseId),
            transferDate: Value(transfer.transferDate.millisecondsSinceEpoch),
            notes: Value(transfer.notes),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(effectiveCompanyId),
            status: Value(transfer.status.name),
            postedAt: Value(transfer.postedAt?.millisecondsSinceEpoch),
          ),
        );

        // Re-insert lines only for existing transfer owned by this tenant
        await (_db.delete(
          _db.stockMovementLines,
        )..where((tbl) => tbl.transferId.equals(transfer.id))).go();
      } else {
        await _db
            .into(_db.stockTransfers)
            .insert(
              StockTransfersCompanion(
                id: Value(transfer.id),
                transferNumber: Value(transfer.transferNumber),
                fromWarehouseId: Value(transfer.fromWarehouseId),
                toWarehouseId: Value(transfer.toWarehouseId),
                transferDate: Value(
                  transfer.transferDate.millisecondsSinceEpoch,
                ),
                notes: Value(transfer.notes),
                createdAt: Value(transfer.createdAt.millisecondsSinceEpoch),
                updatedAt: Value(now.millisecondsSinceEpoch),
                syncStatus: const Value('pending'),
                version: Value(newVersion),
                companyId: Value(effectiveCompanyId),
                status: Value(transfer.status.name),
                postedAt: Value(transfer.postedAt?.millisecondsSinceEpoch),
              ),
            );
      }

      for (final line in transfer.lines) {
        // Save movement line
        await _db
            .into(_db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                id: Value(line.id),
                transferId: Value(transfer.id),
                movementType: const Value('transfer'),
                itemCode: Value(line.itemCode),
                itemName: Value(line.itemName),
                mainQuantity: Value(line.mainQuantity),
                subQuantity: Value(line.subQuantity),
                quantity: Value(line.quantity),
                unitCost: Value(line.unitCost),
                totalCost: Value(line.totalCost),
                companyId: Value(effectiveCompanyId),
              ),
            );
      }

      await _enqueueTransfer(
        transfer.copyWith(version: newVersion, companyId: effectiveCompanyId),
        existing == null ? SyncOperationType.create : SyncOperationType.update,
      );
    });
  }

  @override
  Future<void> deleteTransfer(String id) async {
    await _initializationGuard?.assertInitialized();
    await _db.transaction(() async {
      final transfer = await getTransferById(id);
      if (transfer == null) return;

      if (transfer.isPosted) {
        throw const JournalException(JournalException.postedImmutable);
      }
      if (transfer.status == InventoryDocumentStatus.cancelled) {
        throw const JournalException(
          JournalException.cancelledImmutable,
          'لا يمكن حذف مستند تحويل ملغي.',
        );
      }

      final now = DateTime.now().toUtc();
      final newVersion = transfer.version + 1;

      // Soft delete header with strict company scoping
      await (_db.update(
        _db.stockTransfers,
      )..where((tbl) => _scoped(tbl) & tbl.id.equals(id))).write(
        StockTransfersCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(newVersion),
        ),
      );

      await _enqueueTransfer(
        transfer.copyWith(version: newVersion, deletedAt: now),
        SyncOperationType.delete,
      );
    });
  }

  Future<List<StockTransferLine>> _getLinesForTransfer(
    String transferId,
  ) async {
    final query = _db.select(_db.stockMovementLines)
      ..where(
        (tbl) =>
            tbl.transferId.equals(transferId) &
            tbl.movementType.equals('transfer'),
      );
    final rows = await query.get();

    return rows
        .map(
          (row) => StockTransferLine(
            id: row.id,
            transferUuid: row.transferId ?? transferId,
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

  StockTransfer _mapRowToTransfer(
    StockTransferRow row,
    List<StockTransferLine> lines,
  ) {
    return StockTransfer(
      id: row.id,
      transferNumber: row.transferNumber,
      fromWarehouseId: row.fromWarehouseId,
      toWarehouseId: row.toWarehouseId,
      transferDate: DateTime.fromMillisecondsSinceEpoch(
        row.transferDate,
        isUtc: true,
      ),
      notes: row.notes,
      lines: lines,
      status: InventoryDocumentStatus.fromStorage(row.status),
      postedAt: row.postedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.postedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Future<void> _enqueueTransfer(
    StockTransfer transfer,
    SyncOperationType type,
  ) async {
    if (_syncQueue == null) return;

    final payload = {
      'id': transfer.id,
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
              'id': line.id,
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
