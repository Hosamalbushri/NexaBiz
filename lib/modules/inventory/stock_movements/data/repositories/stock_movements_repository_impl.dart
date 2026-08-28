import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../../../shared/data/database/inventory_database.dart';
import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_movement_line.dart';
import '../../domain/entities/stock_receipt.dart';
import '../../domain/repositories/stock_movements_repository.dart';

class StockMovementsRepositoryImpl implements StockMovementsRepository {
  StockMovementsRepositoryImpl({
    required InventoryDatabase db,
    SyncQueue? syncQueue,
    InventoryAccountingPoster? accountingPoster,
  })  : _db = db,
        _syncQueue = syncQueue,
        _accountingPoster = accountingPoster;

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;
  final InventoryAccountingPoster? _accountingPoster;

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

      // Save header row
      if (existing != null) {
        await (_db.update(_db.stockReceipts)..where((tbl) => tbl.uuid.equals(receipt.id))).write(
          StockReceiptsCompanion(
            receiptNumber: Value(receipt.receiptNumber),
            supplier: Value(receipt.supplier),
            accountId: Value(receipt.accountId),
            accountName: Value(receipt.accountName),
            currencyCode: Value(receipt.currencyCode),
            exchangeRate: Value(receipt.exchangeRate),
            notes: Value(receipt.notes),
            receiptDate: Value(receipt.receiptDate.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(receipt.companyId),
            status: Value(receipt.status.name),
            postedAt: Value(receipt.postedAt?.millisecondsSinceEpoch),
          ),
        );
      } else {
        await _db.into(_db.stockReceipts).insert(
          StockReceiptsCompanion(
            uuid: Value(receipt.id),
            receiptNumber: Value(receipt.receiptNumber),
            supplier: Value(receipt.supplier),
            accountId: Value(receipt.accountId),
            accountName: Value(receipt.accountName),
            currencyCode: Value(receipt.currencyCode),
            exchangeRate: Value(receipt.exchangeRate),
            notes: Value(receipt.notes),
            receiptDate: Value(receipt.receiptDate.millisecondsSinceEpoch),
            createdAt: Value(receipt.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            companyId: Value(receipt.companyId),
            status: Value(receipt.status.name),
            postedAt: Value(receipt.postedAt?.millisecondsSinceEpoch),
          ),
        );
      }

      // Re-insert line items
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
                postedCost: Value(line.postedCost),
                postedAt: Value(line.postedAt?.millisecondsSinceEpoch),
              ),
            );
      }

      await _enqueueReceipt(receipt.copyWith(version: newVersion), existing == null ? SyncOperationType.create : SyncOperationType.update);

      if (_accountingPoster != null) {
        final totalAmount = receipt.lines.fold(0.0, (sum, l) => sum + l.totalCost);
        final docRef = InventoryDocumentRef(
          documentId: receipt.id,
          documentNumber: receipt.receiptNumber,
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: receipt.receiptDate,
          status: receipt.status,
        );
        await _accountingPoster!.postAccountingEntry(
          document: docRef,
          totalAmount: totalAmount,
          accountId: receipt.accountId,
          isPosted: receipt.isPosted,
        );
      }
    });
  }

  @override
  Future<void> deleteReceipt(String id) async {
    await _db.transaction(() async {
      final receipt = await getReceiptById(id);
      if (receipt == null) return;

      if (receipt.isPosted) {
        throw StateError('Cannot delete a posted stock receipt. Unpost it first.');
      }

      final now = DateTime.now().toUtc();

      await (_db.update(_db.stockReceipts)..where((tbl) => tbl.uuid.equals(id))).write(
        StockReceiptsCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(receipt.version + 1),
        ),
      );

      await _enqueueReceipt(receipt.copyWith(version: receipt.version + 1, deletedAt: now), SyncOperationType.delete);

      if (_accountingPoster != null) {
        final docRef = InventoryDocumentRef(
          documentId: id,
          documentNumber: receipt.receiptNumber,
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: receipt.receiptDate,
          status: receipt.status,
        );
        await _accountingPoster!.reverseAccountingEntry(document: docRef);
      }
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

      // Save header row
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
            status: Value(issue.status.name),
            postedAt: Value(issue.postedAt?.millisecondsSinceEpoch),
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
            status: Value(issue.status.name),
            postedAt: Value(issue.postedAt?.millisecondsSinceEpoch),
          ),
        );
      }

      // Re-insert line items
      await (_db.delete(_db.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(issue.id)))
          .go();

      for (final line in issue.lines) {
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
                unitCost: Value(line.unitCost),
                totalCost: Value(line.totalCost),
                postedCost: Value(line.postedCost),
                postedAt: Value(line.postedAt?.millisecondsSinceEpoch),
              ),
            );
      }

      await _enqueueIssue(issue.copyWith(version: newVersion), existing == null ? SyncOperationType.create : SyncOperationType.update);

      if (_accountingPoster != null) {
        final totalAmount = issue.lines.fold(0.0, (sum, l) => sum + l.totalCost);
        final docRef = InventoryDocumentRef(
          documentId: issue.id,
          documentNumber: issue.issueNumber,
          documentType: InventoryDocumentType.stockIssue,
          documentDate: issue.issueDate,
          warehouseId: issue.warehouse,
          status: issue.status,
        );
        await _accountingPoster!.postAccountingEntry(
          document: docRef,
          totalAmount: totalAmount,
          accountId: issue.accountId,
          isPosted: issue.isPosted,
        );
      }
    });
  }

  @override
  Future<void> deleteIssue(String id) async {
    await _db.transaction(() async {
      final issue = await getIssueById(id);
      if (issue == null) return;

      if (issue.isPosted) {
        throw StateError('Cannot delete a posted stock issue. Unpost it first.');
      }

      final now = DateTime.now().toUtc();

      await (_db.update(_db.stockIssues)..where((tbl) => tbl.uuid.equals(id))).write(
        StockIssuesCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(issue.version + 1),
        ),
      );

      await _enqueueIssue(issue.copyWith(version: issue.version + 1, deletedAt: now), SyncOperationType.delete);

      if (_accountingPoster != null) {
        final docRef = InventoryDocumentRef(
          documentId: id,
          documentNumber: issue.issueNumber,
          documentType: InventoryDocumentType.stockIssue,
          documentDate: issue.issueDate,
          warehouseId: issue.warehouse,
          status: issue.status,
        );
        await _accountingPoster!.reverseAccountingEntry(document: docRef);
      }
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
            postedCost: row.postedCost,
            postedAt: row.postedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.postedAt!, isUtc: true),
          ),
        )
        .toList();
  }

  StockReceipt _mapRowToReceipt(StockReceiptRow row, List<StockMovementLine> lines) {
    return StockReceipt(
      id: row.uuid,
      receiptNumber: row.receiptNumber,
      supplier: row.supplier,
      accountId: row.accountId,
      accountName: row.accountName,
      currencyCode: row.currencyCode,
      exchangeRate: row.exchangeRate,
      notes: row.notes,
      receiptDate: DateTime.fromMillisecondsSinceEpoch(row.receiptDate, isUtc: true),
      lines: lines,
      status: InventoryDocumentStatus.fromStorage(row.status),
      postedAt: row.postedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.postedAt!, isUtc: true),
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
      status: InventoryDocumentStatus.fromStorage(row.status),
      postedAt: row.postedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(row.postedAt!, isUtc: true),
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
          'status': receipt.status.name,
          'postedAt': receipt.postedAt?.toUtc().millisecondsSinceEpoch,
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
          'status': issue.status.name,
          'postedAt': issue.postedAt?.toUtc().millisecondsSinceEpoch,
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
