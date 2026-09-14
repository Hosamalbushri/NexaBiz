import 'package:drift/drift.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/core/sync/sync_core.dart';

import 'package:stock_count/core/database/nexabiz_database.dart';
import '../../domain/entities/stock_issue.dart';
import '../../domain/entities/stock_movement_line.dart';
import '../../domain/entities/stock_receipt.dart';
import '../../domain/repositories/stock_movements_repository.dart';

import 'package:stock_count/core/setup/setup_core.dart';

class StockMovementsRepositoryImpl implements StockMovementsRepository {
  StockMovementsRepositoryImpl({
    required this._db,
    this._syncQueue,
    this._accountingPoster,
    this._readCompanyId,
    this._initializationGuard,
  });

  final NexabizDatabase _db;
  final SyncQueue? _syncQueue;
  final InventoryAccountingPoster? _accountingPoster;
  final String Function()? _readCompanyId;
  final InitializationGuard? _initializationGuard;

  String get _currentCompanyId {
    final cid = _readCompanyId?.call().trim();
    if (cid == null || cid.isEmpty) {
      throw MissingCompanyContextException(
        'StockMovementsRepository operation failed: missing company context.',
      );
    }
    return cid;
  }

  Expression<bool> _tenantScopedReceipt($StockReceiptsTable tbl) =>
      tbl.companyId.equals(_currentCompanyId);

  Expression<bool> _scopedReceipt($StockReceiptsTable tbl) =>
      tbl.deletedAt.isNull() & _tenantScopedReceipt(tbl);

  Expression<bool> _tenantScopedIssue($StockIssuesTable tbl) =>
      tbl.companyId.equals(_currentCompanyId);

  Expression<bool> _scopedIssue($StockIssuesTable tbl) =>
      tbl.deletedAt.isNull() & _tenantScopedIssue(tbl);

  static const receiptEntityType = 'stock_receipt';
  static const issueEntityType = 'stock_issue';

  // ---------------------------------------------------------------------------
  // RECEIPTS
  // ---------------------------------------------------------------------------

  @override
  Future<List<StockReceipt>> getAllReceipts() async {
    final query = _db.select(_db.stockReceipts)
      ..where((tbl) => _scopedReceipt(tbl));
    final rows = await query.get();
    final results = <StockReceipt>[];

    for (final row in rows) {
      final lines = await _getLinesForMovement(row.id, 'receipt');
      results.add(_mapRowToReceipt(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockReceipt>> watchAllReceipts() {
    final query = _db.select(_db.stockReceipts)
      ..where((tbl) => _scopedReceipt(tbl));

    return query.watch().asyncMap((rows) async {
      final results = <StockReceipt>[];
      for (final row in rows) {
        final lines = await _getLinesForMovement(row.id, 'receipt');
        results.add(_mapRowToReceipt(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockReceipt?> getReceiptById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final query = _db.select(_db.stockReceipts)
      ..where((tbl) => tbl.id.equals(trimmed) & _scopedReceipt(tbl));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForMovement(row.id, 'receipt');
    return _mapRowToReceipt(row, lines);
  }

  @override
  Future<void> saveReceipt(StockReceipt receipt) async {
    await _initializationGuard?.assertInitialized();
    if (receipt.companyId != null &&
        receipt.companyId!.isNotEmpty &&
        receipt.companyId != _currentCompanyId) {
      throw ArgumentError(
        'Cross-tenant operation rejected: receipt companyId (${receipt.companyId}) does not match current tenant ($_currentCompanyId)',
      );
    }

    for (final line in receipt.lines) {
      if (line.unitCost <= 0 || line.totalCost <= 0) {
        throw ArgumentError(
          'لا يمكن حفظ أمر التوريد بتكلفة صفرية للصنف (${line.itemName})',
        );
      }
    }
    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.stockReceipts)..where(
                (tbl) =>
                    tbl.id.equals(receipt.id) & _tenantScopedReceipt(tbl),
              ))
              .getSingleOrNull();

      if (existing != null &&
          (existing.status == 'posted' || existing.postedAt != null)) {
        throw const JournalException(JournalException.postedImmutable);
      }

      final now = DateTime.now().toUtc();
      final newVersion =
          (existing?.version ?? receipt.version) + (existing == null ? 0 : 1);
      final targetCompanyId = receipt.companyId ?? _currentCompanyId;

      // Save header row
      if (existing != null) {
        await (_db.update(_db.stockReceipts)..where(
              (tbl) => tbl.id.equals(receipt.id) & _tenantScopedReceipt(tbl),
            ))
            .write(
              StockReceiptsCompanion(
                receiptNumber: Value(receipt.receiptNumber),
                supplier: Value(receipt.supplier),
                accountId: Value(receipt.accountId),
                accountName: Value(receipt.accountName),
                currencyCode: Value(receipt.currencyCode),
                exchangeRate: Value(receipt.exchangeRate),
                warehouse: Value(receipt.warehouse),
                notes: Value(receipt.notes),
                receiptDate: Value(receipt.receiptDate.millisecondsSinceEpoch),
                updatedAt: Value(now.millisecondsSinceEpoch),
                syncStatus: const Value('pending'),
                version: Value(newVersion),
                companyId: Value(targetCompanyId),
                status: Value(receipt.status.name),
                postedAt: Value(receipt.postedAt?.millisecondsSinceEpoch),
              ),
            );
      } else {
        await _db
            .into(_db.stockReceipts)
            .insert(
              StockReceiptsCompanion(
                id: Value(receipt.id),
                receiptNumber: Value(receipt.receiptNumber),
                supplier: Value(receipt.supplier),
                accountId: Value(receipt.accountId),
                accountName: Value(receipt.accountName),
                currencyCode: Value(receipt.currencyCode),
                exchangeRate: Value(receipt.exchangeRate),
                warehouse: Value(receipt.warehouse),
                notes: Value(receipt.notes),
                receiptDate: Value(receipt.receiptDate.millisecondsSinceEpoch),
                createdAt: Value(receipt.createdAt.millisecondsSinceEpoch),
                updatedAt: Value(now.millisecondsSinceEpoch),
                syncStatus: const Value('pending'),
                version: Value(newVersion),
                companyId: Value(targetCompanyId),
                status: Value(receipt.status.name),
                postedAt: Value(receipt.postedAt?.millisecondsSinceEpoch),
              ),
            );
      }

      // Re-insert line items
      await (_db.delete(
        _db.stockMovementLines,
      )..where((tbl) => tbl.receiptId.equals(receipt.id))).go();

      for (final line in receipt.lines) {
        await _db
            .into(_db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                id: Value(line.id),
                receiptId: Value(receipt.id),
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
                companyId: Value(targetCompanyId),
              ),
            );
      }

      await _enqueueReceipt(
        receipt.copyWith(version: newVersion, companyId: targetCompanyId),
        existing == null ? SyncOperationType.create : SyncOperationType.update,
      );

      final poster = _accountingPoster;
      if (poster != null) {
        final totalAmount = receipt.lines.fold(
          0.0,
          (sum, l) => sum + l.totalCost,
        );
        final docRef = InventoryDocumentRef(
          documentId: receipt.id,
          documentNumber: receipt.receiptNumber,
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: receipt.receiptDate,
          warehouseId: receipt.warehouse,
          status: receipt.status,
          currencyCode: receipt.currencyCode,
          exchangeRate: receipt.exchangeRate,
        );
        await poster.postAccountingEntry(
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
    await _initializationGuard?.assertInitialized();
    await _db.transaction(() async {
      final receipt = await getReceiptById(id);
      if (receipt == null) return;

      if (receipt.isPosted) {
        throw StateError(
          'Cannot delete a posted stock receipt. Unpost it first.',
        );
      }

      final now = DateTime.now().toUtc();

      await (_db.update(
        _db.stockReceipts,
      )..where((tbl) => tbl.id.equals(id) & _tenantScopedReceipt(tbl))).write(
        StockReceiptsCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(receipt.version + 1),
        ),
      );

      await _enqueueReceipt(
        receipt.copyWith(version: receipt.version + 1, deletedAt: now),
        SyncOperationType.delete,
      );

      final poster = _accountingPoster;
      if (poster != null) {
        final docRef = InventoryDocumentRef(
          documentId: id,
          documentNumber: receipt.receiptNumber,
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: receipt.receiptDate,
          warehouseId: receipt.warehouse,
          status: receipt.status,
          currencyCode: receipt.currencyCode,
          exchangeRate: receipt.exchangeRate,
        );
        await poster.reverseAccountingEntry(document: docRef);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // ISSUES
  // ---------------------------------------------------------------------------

  @override
  Future<List<StockIssue>> getAllIssues() async {
    final query = _db.select(_db.stockIssues)
      ..where((tbl) => _scopedIssue(tbl));
    final rows = await query.get();
    final results = <StockIssue>[];

    for (final row in rows) {
      final lines = await _getLinesForMovement(row.id, 'issue');
      results.add(_mapRowToIssue(row, lines));
    }
    return results;
  }

  @override
  Stream<List<StockIssue>> watchAllIssues() {
    final query = _db.select(_db.stockIssues)
      ..where((tbl) => _scopedIssue(tbl));

    return query.watch().asyncMap((rows) async {
      final results = <StockIssue>[];
      for (final row in rows) {
        final lines = await _getLinesForMovement(row.id, 'issue');
        results.add(_mapRowToIssue(row, lines));
      }
      return results;
    });
  }

  @override
  Future<StockIssue?> getIssueById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final query = _db.select(_db.stockIssues)
      ..where((tbl) => tbl.id.equals(trimmed) & _scopedIssue(tbl));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final lines = await _getLinesForMovement(row.id, 'issue');
    return _mapRowToIssue(row, lines);
  }

  @override
  Future<void> saveIssue(StockIssue issue) async {
    await _initializationGuard?.assertInitialized();
    if (issue.companyId != null &&
        issue.companyId!.isNotEmpty &&
        issue.companyId != _currentCompanyId) {
      throw ArgumentError(
        'Cross-tenant operation rejected: issue companyId (${issue.companyId}) does not match current tenant ($_currentCompanyId)',
      );
    }

    for (final line in issue.lines) {
      if (line.unitCost <= 0 || line.totalCost <= 0) {
        throw ArgumentError(
          'لا يمكن حفظ أمر الصرف بتكلفة صفرية للصنف (${line.itemName})',
        );
      }
    }
    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.stockIssues)..where(
                (tbl) => tbl.id.equals(issue.id) & _tenantScopedIssue(tbl),
              ))
              .getSingleOrNull();

      if (existing != null &&
          (existing.status == 'posted' || existing.postedAt != null)) {
        throw const JournalException(JournalException.postedImmutable);
      }

      final now = DateTime.now().toUtc();
      final newVersion =
          (existing?.version ?? issue.version) + (existing == null ? 0 : 1);
      final targetCompanyId = issue.companyId ?? _currentCompanyId;

      // Save header row
      if (existing != null) {
        await (_db.update(_db.stockIssues)..where(
              (tbl) => tbl.id.equals(issue.id) & _tenantScopedIssue(tbl),
            ))
            .write(
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
                companyId: Value(targetCompanyId),
                status: Value(issue.status.name),
                postedAt: Value(issue.postedAt?.millisecondsSinceEpoch),
              ),
            );
      } else {
        await _db
            .into(_db.stockIssues)
            .insert(
              StockIssuesCompanion(
                id: Value(issue.id),
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
                companyId: Value(targetCompanyId),
                status: Value(issue.status.name),
                postedAt: Value(issue.postedAt?.millisecondsSinceEpoch),
              ),
            );
      }

      // Re-insert line items
      await (_db.delete(
        _db.stockMovementLines,
      )..where((tbl) => tbl.issueId.equals(issue.id))).go();

      for (final line in issue.lines) {
        await _db
            .into(_db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                id: Value(line.id),
                issueId: Value(issue.id),
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
                companyId: Value(targetCompanyId),
              ),
            );
      }

      await _enqueueIssue(
        issue.copyWith(version: newVersion, companyId: targetCompanyId),
        existing == null ? SyncOperationType.create : SyncOperationType.update,
      );

      final poster = _accountingPoster;
      if (poster != null) {
        final totalAmount = issue.lines.fold(
          0.0,
          (sum, l) => sum + l.totalCost,
        );
        final docRef = InventoryDocumentRef(
          documentId: issue.id,
          documentNumber: issue.issueNumber,
          documentType: InventoryDocumentType.stockIssue,
          documentDate: issue.issueDate,
          warehouseId: issue.warehouse,
          status: issue.status,
          currencyCode: issue.currencyCode,
          exchangeRate: issue.exchangeRate,
        );
        await poster.postAccountingEntry(
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
    await _initializationGuard?.assertInitialized();
    await _db.transaction(() async {
      final issue = await getIssueById(id);
      if (issue == null) return;

      if (issue.isPosted) {
        throw StateError(
          'Cannot delete a posted stock issue. Unpost it first.',
        );
      }

      final now = DateTime.now().toUtc();

      await (_db.update(
        _db.stockIssues,
      )..where((tbl) => tbl.id.equals(id) & _tenantScopedIssue(tbl))).write(
        StockIssuesCompanion(
          deletedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
          syncStatus: const Value('pending'),
          version: Value(issue.version + 1),
        ),
      );

      await _enqueueIssue(
        issue.copyWith(version: issue.version + 1, deletedAt: now),
        SyncOperationType.delete,
      );

      final poster = _accountingPoster;
      if (poster != null) {
        final docRef = InventoryDocumentRef(
          documentId: id,
          documentNumber: issue.issueNumber,
          documentType: InventoryDocumentType.stockIssue,
          documentDate: issue.issueDate,
          warehouseId: issue.warehouse,
          status: issue.status,
          currencyCode: issue.currencyCode,
          exchangeRate: issue.exchangeRate,
        );
        await poster.reverseAccountingEntry(document: docRef);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Future<List<StockMovementLine>> _getLinesForMovement(
    String movementId,
    String type,
  ) async {
    final query = _db.select(_db.stockMovementLines)
      ..where(
        (tbl) {
          final Expression<bool> fkMatch;
          switch (type) {
            case 'receipt':
              fkMatch = tbl.receiptId.equals(movementId);
              break;
            case 'issue':
              fkMatch = tbl.issueId.equals(movementId);
              break;
            case 'return':
              fkMatch = tbl.returnId.equals(movementId);
              break;
            case 'transfer':
              fkMatch = tbl.transferId.equals(movementId);
              break;
            default:
              fkMatch = tbl.receiptId.equals(movementId) |
                  tbl.issueId.equals(movementId) |
                  tbl.returnId.equals(movementId) |
                  tbl.transferId.equals(movementId);
          }
          return fkMatch & tbl.movementType.equals(type);
        },
      );
    final rows = await query.get();

    return rows
        .map(
          (row) => StockMovementLine(
            id: row.id,
            movementUuid: movementId,
            movementType: row.movementType,
            itemCode: row.itemCode,
            itemName: row.itemName,
            mainQuantity: row.mainQuantity,
            subQuantity: row.subQuantity,
            quantity: row.quantity,
            unitCost: row.unitCost,
            totalCost: row.totalCost,
            postedCost: row.postedCost,
            postedAt: row.postedAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    row.postedAt!,
                    isUtc: true,
                  ),
          ),
        )
        .toList();
  }

  StockReceipt _mapRowToReceipt(
    StockReceiptRow row,
    List<StockMovementLine> lines,
  ) {
    return StockReceipt(
      id: row.id,
      receiptNumber: row.receiptNumber,
      supplier: row.supplier,
      accountId: row.accountId,
      accountName: row.accountName,
      currencyCode: row.currencyCode,
      exchangeRate: row.exchangeRate,
      warehouse: row.warehouse,
      notes: row.notes,
      receiptDate: DateTime.fromMillisecondsSinceEpoch(
        row.receiptDate,
        isUtc: true,
      ),
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
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == row.syncStatus,
        orElse: () => SyncStatus.synced,
      ),
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  StockIssue _mapRowToIssue(StockIssueRow row, List<StockMovementLine> lines) {
    return StockIssue(
      id: row.id,
      issueNumber: row.issueNumber,
      destination: row.destination,
      accountId: row.accountId,
      accountName: row.accountName,
      currencyCode: row.currencyCode,
      exchangeRate: row.exchangeRate,
      voucherBookId: row.voucherBookId,
      warehouse: row.warehouse,
      notes: row.notes,
      issueDate: DateTime.fromMillisecondsSinceEpoch(
        row.issueDate,
        isUtc: true,
      ),
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
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == row.syncStatus,
        orElse: () => SyncStatus.synced,
      ),
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      companyId: row.companyId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Future<void> _enqueueReceipt(
    StockReceipt receipt,
    SyncOperationType type,
  ) async {
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
          'warehouse': receipt.warehouse,
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
          'voucherBookId': issue.voucherBookId,
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

  @override
  Future<void> saveMovementLines({
    required String movementUuid,
    required String movementType,
    required List<StockMovementLine> lines,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.stockMovementLines,
      )..where((tbl) {
          switch (movementType) {
            case 'receipt':
              return tbl.receiptId.equals(movementUuid);
            case 'issue':
              return tbl.issueId.equals(movementUuid);
            case 'return':
              return tbl.returnId.equals(movementUuid);
            case 'transfer':
              return tbl.transferId.equals(movementUuid);
            default:
              return tbl.receiptId.equals(movementUuid);
          }
      })).go();

      for (final line in lines) {
        await _db
            .into(_db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion(
                id: Value(line.id),
                receiptId: movementType == 'receipt' ? Value(movementUuid) : const Value.absent(),
                issueId: movementType == 'issue' ? Value(movementUuid) : const Value.absent(),
                returnId: movementType == 'return' ? Value(movementUuid) : const Value.absent(),
                transferId: movementType == 'transfer' ? Value(movementUuid) : const Value.absent(),
                movementType: Value(movementType),
                itemCode: Value(line.itemCode),
                itemName: Value(line.itemName),
                mainQuantity: Value(line.mainQuantity),
                subQuantity: Value(line.subQuantity),
                quantity: Value(line.quantity),
                unitCost: Value(line.unitCost),
                totalCost: Value(line.totalCost),
                postedCost: Value(line.postedCost),
                postedAt: Value(line.postedAt?.millisecondsSinceEpoch),
                companyId: Value(_currentCompanyId),
              ),
            );
      }
    });
  }
}
