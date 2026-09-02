import 'package:drift/drift.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/inventory/stock_count/data/repositories/inventory_movement_ledger.dart';
import 'package:stock_count/modules/inventory/stock_count/data/repositories/inventory_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';

String _normalizeUuid(String raw) {
  if (raw.length == 36) return raw;
  if (raw.length < 36) return raw.padLeft(36, '0');
  return raw.substring(0, 36);
}

/// Inventory products adapter for the shared SyncManager.
class ProductSyncHandler implements SyncEntityHandler {
  ProductSyncHandler({
    required this._repository,
    required this._remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  });

  final ProductRepositoryImpl _repository;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => ProductRepositoryImpl.entityType;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: preferServerWhenLocalSynced,
      remotePayload: meta.payload,
    );
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    final payload = Map<String, dynamic>.from(change.payload);
    payload['uuid'] = change.entityId;
    payload['version'] = change.version;
    payload['updatedAt'] = change.updatedAt.millisecondsSinceEpoch;
    if (change.deleted) {
      payload['deletedAt'] =
          payload['deletedAt'] ?? change.updatedAt.millisecondsSinceEpoch;
    }
    await _repository.applyRemotePayload(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) {
    return _repository.markSynced(
      uuid: entityId,
      remoteVersion: remoteVersion,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) {
    return _repository.markConflict(entityId);
  }
}

/// Stock-count lines — divergent quantities are never auto-overwritten.
class InventoryItemSyncHandler implements SyncEntityHandler {
  InventoryItemSyncHandler({
    required this._repository,
    required this._remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  });

  final InventoryRepositoryImpl _repository;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => InventoryRepositoryImpl.entityType;

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    if (meta.version > operation.baseVersion) {
      final remoteQty = meta.payload?['actualQuantity']?.toString();
      final localQty = operation.payload['actualQuantity']?.toString();
      if (remoteQty != localQty) {
        return ConflictDecision.markConflict;
      }
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: false,
      remotePayload: meta.payload,
    );
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    final payload = Map<String, dynamic>.from(change.payload);
    payload['id'] = change.entityId;
    payload['version'] = change.version;
    payload['updatedAt'] = change.updatedAt.millisecondsSinceEpoch;
    if (change.deleted) {
      payload['deletedAt'] =
          payload['deletedAt'] ?? change.updatedAt.millisecondsSinceEpoch;
    }
    await _repository.applyRemotePayload(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) {
    return _repository.markSynced(
      id: entityId,
      remoteVersion: remoteVersion,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) {
    return _repository.markConflict(entityId);
  }
}

/// Append-only movement events adapter for the shared SyncManager.
class InventoryMovementSyncHandler implements SyncEntityHandler {
  InventoryMovementSyncHandler({
    required this._ledger,
    required this._remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  });

  final InventoryMovementLedger _ledger;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => InventoryMovementLedger.entityType;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    // Append-only events never conflict on create
    return ConflictDecision.uploadLocal;
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    final payload = Map<String, dynamic>.from(change.payload);
    payload['uuid'] = change.entityId;
    payload['version'] = change.version;
    await _ledger.applyRemoteMovement(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {}
}

/// Generic handler for inventory documents (Receipts, Issues, Transfers, Returns, Reversals)
class InventoryDocumentSyncHandler implements SyncEntityHandler {
  InventoryDocumentSyncHandler({
    required this.entityType,
    required this._remoteProvider,
    this._db,
    this._postingCoordinator,
    this._postingEngine,
    this._readCompanyId,
    this.conflictResolver = const ConflictResolver(),
    this.preferServerWhenLocalSynced = true,
  });

  @override
  final String entityType;
  @override
  final bool preferServerWhenLocalSynced;
  final RemoteSyncApi Function() _remoteProvider;
  final InventoryDatabase? _db;
  final PostingCoordinator? _postingCoordinator;
  final PostingEngine? _postingEngine;
  final String Function()? _readCompanyId;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: preferServerWhenLocalSynced,
      remotePayload: meta.payload,
    );
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    final db = _db;
    if (db == null) return;

    final payload = Map<String, dynamic>.from(change.payload);
    final payloadCompanyId = payload['companyId']?.toString() ??
        payload['company_id']?.toString() ??
        payload['tenantId']?.toString();

    // 1. TENANT SECURITY GUARD: Reject cross-tenant sync payload
    if (payloadCompanyId != null &&
        payloadCompanyId.isNotEmpty &&
        payloadCompanyId != _currentCompanyId) {
      throw ArgumentError(
        'Cross-tenant sync change rejected: payload companyId ($payloadCompanyId) does not match current tenant ($_currentCompanyId)',
      );
    }

    final entityId = _normalizeUuid(change.entityId);
    final now = DateTime.now().toUtc();
    final effectiveCompanyId = payloadCompanyId ?? _currentCompanyId;

    switch (entityType) {
      case 'stock_receipt':
        await _applyStockReceipt(db, entityId, change, payload, effectiveCompanyId, now);
        break;
      case 'stock_issue':
        await _applyStockIssue(db, entityId, change, payload, effectiveCompanyId, now);
        break;
      case 'stock_transfer':
        await _applyStockTransfer(db, entityId, change, payload, effectiveCompanyId, now);
        break;
      case 'stock_return':
        await _applyStockReturn(db, entityId, change, payload, effectiveCompanyId, now);
        break;
      case 'inventory_reversal':
        await _applyInventoryReversal(db, entityId, change, payload, effectiveCompanyId, now);
        break;
      default:
        break;
    }
  }

  Future<void> _applyStockReceipt(
    InventoryDatabase db,
    String entityId,
    SyncRemoteChange change,
    Map<String, dynamic> payload,
    String companyId,
    DateTime now,
  ) async {
    int? deletedAt;
    await db.transaction(() async {
      final existing = await (db.select(db.stockReceipts)
            ..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId)))
          .getSingleOrNull();

      final remoteVersion = change.version;
      if (existing != null && existing.version >= remoteVersion) {
        return;
      }

      if (existing != null && existing.status == 'posted') {
        final remoteStatus = payload['status']?.toString();
        final isRemoteDelete = change.deleted || payload['deletedAt'] != null;
        if (remoteStatus != 'posted' || isRemoteDelete) {
          throw StateError('Sync conflict: Cannot overwrite or unpost posted financial document ($entityId)');
        }
      }

      deletedAt = change.deleted || payload['deletedAt'] != null
          ? (payload['deletedAt'] as int? ?? change.updatedAt.millisecondsSinceEpoch)
          : null;

      final companion = StockReceiptsCompanion(
        uuid: Value(entityId),
        receiptNumber: Value(payload['receiptNumber']?.toString() ?? payload['receipt_number']?.toString() ?? ''),
        supplier: Value(payload['supplier']?.toString() ?? ''),
        accountId: Value(payload['accountId']?.toString() ?? payload['account_id']?.toString()),
        accountName: Value(payload['accountName']?.toString() ?? payload['account_name']?.toString()),
        currencyCode: Value(payload['currencyCode']?.toString() ?? payload['currency_code']?.toString() ?? 'YER'),
        exchangeRate: Value((payload['exchangeRate'] as num?)?.toDouble() ?? (payload['exchange_rate'] as num?)?.toDouble() ?? 1.0),
        notes: Value(payload['notes']?.toString()),
        receiptDate: Value((payload['receiptDate'] as int?) ?? (payload['receipt_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch),
        createdAt: Value(existing?.createdAt ?? change.updatedAt.millisecondsSinceEpoch),
        updatedAt: Value(change.updatedAt.millisecondsSinceEpoch),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(now.millisecondsSinceEpoch),
        version: Value(remoteVersion),
        companyId: Value(companyId),
        status: Value(_postingCoordinator != null && payload['status']?.toString() == 'posted' && (existing == null || existing.status != 'posted') ? 'draft' : (payload['status']?.toString() ?? 'draft')),
        postedAt: Value((payload['postedAt'] as int?) ?? (payload['posted_at'] as int?)),
        deletedAt: Value(deletedAt),
      );

      if (existing != null) {
        await (db.update(db.stockReceipts)..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId))).write(companion);
      } else {
        await db.into(db.stockReceipts).insert(companion);
      }

      await (db.delete(db.stockMovementLines)..where((t) => t.movementUuid.equals(entityId))).go();
      final rawLines = payload['lines'];
      if (rawLines is List) {
        for (final raw in rawLines) {
          if (raw is! Map) continue;
          final l = Map<String, dynamic>.from(raw);
          final rawLineUuid = l['id']?.toString() ?? l['uuid']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
          await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(_normalizeUuid(rawLineUuid)),
              movementUuid: Value(entityId),
              movementType: const Value('receipt'),
              itemCode: Value(l['itemCode']?.toString() ?? l['item_code']?.toString() ?? ''),
              itemName: Value((l['itemName']?.toString() ?? l['item_name']?.toString() ?? l['itemCode']?.toString() ?? l['item_code']?.toString() ?? '').isNotEmpty ? (l['itemName']?.toString() ?? l['item_name']?.toString() ?? l['itemCode']?.toString() ?? l['item_code']?.toString() ?? '') : 'Item'),
              mainQuantity: Value((l['mainQuantity'] as num?)?.toDouble() ?? (l['quantity'] as num?)?.toDouble() ?? 0.0),
              subQuantity: Value((l['subQuantity'] as num?)?.toDouble() ?? 0.0),
              quantity: Value((l['quantity'] as num?)?.toDouble() ?? 0.0),
              unitCost: Value((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0),
              totalCost: Value(
                (l['totalCost'] as num?)?.toDouble() ??
                (l['total_cost'] as num?)?.toDouble() ??
                (((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0) *
                 ((l['quantity'] as num?)?.toDouble() ?? (l['mainQuantity'] as num?)?.toDouble() ?? 0.0)),
              ),
              postedCost: Value((l['postedCost'] as num?)?.toDouble() ?? (l['posted_cost'] as num?)?.toDouble()),
              postedAt: Value((l['postedAt'] as int?) ?? (l['posted_at'] as int?)),
            ),
          );
        }
      }
    });

    if (payload['status'] == 'posted' && deletedAt == null && _postingCoordinator != null) {
      final ref = InventoryDocumentRef(
        documentId: entityId,
        documentNumber: payload['receiptNumber']?.toString() ?? payload['receipt_number']?.toString() ?? '',
        documentType: InventoryDocumentType.stockReceipt,
        warehouseId: payload['warehouseId']?.toString() ?? payload['warehouse_id']?.toString() ?? payload['warehouse']?.toString(),
        documentDate: DateTime.fromMillisecondsSinceEpoch(
          (payload['receiptDate'] as int?) ?? (payload['receipt_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch,
        ),
        status: InventoryDocumentStatus.posted,
      );
      final postResult = await _postingCoordinator.post(document: ref);
      if (postResult is! PostSuccess) {
        throw StateError('Remote sync stock receipt posting failed: $postResult');
      }
    }
  }

  Future<void> _applyStockIssue(
    InventoryDatabase db,
    String entityId,
    SyncRemoteChange change,
    Map<String, dynamic> payload,
    String companyId,
    DateTime now,
  ) async {
    int? deletedAt;
    await db.transaction(() async {
      final existing = await (db.select(db.stockIssues)
            ..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId)))
          .getSingleOrNull();

      final remoteVersion = change.version;
      if (existing != null && existing.version >= remoteVersion) {
        return;
      }

      if (existing != null && existing.status == 'posted') {
        final remoteStatus = payload['status']?.toString();
        final isRemoteDelete = change.deleted || payload['deletedAt'] != null;
        if (remoteStatus != 'posted' || isRemoteDelete) {
          throw StateError('Sync conflict: Cannot overwrite or unpost posted financial document ($entityId)');
        }
      }

      deletedAt = change.deleted || payload['deletedAt'] != null
          ? (payload['deletedAt'] as int? ?? change.updatedAt.millisecondsSinceEpoch)
          : null;

      final rawVoucherBookId = payload['voucherBookId'] ?? payload['voucher_book_id'];
      final voucherBookIdInt = rawVoucherBookId != null ? int.tryParse(rawVoucherBookId.toString()) : null;

      final companion = StockIssuesCompanion(
        uuid: Value(entityId),
        issueNumber: Value(payload['issueNumber']?.toString() ?? payload['issue_number']?.toString() ?? ''),
        destination: Value(payload['destination']?.toString()),
        accountId: Value(payload['accountId']?.toString() ?? payload['account_id']?.toString()),
        accountName: Value(payload['accountName']?.toString() ?? payload['account_name']?.toString()),
        currencyCode: Value(payload['currencyCode']?.toString() ?? payload['currency_code']?.toString() ?? 'YER'),
        exchangeRate: Value((payload['exchangeRate'] as num?)?.toDouble() ?? (payload['exchange_rate'] as num?)?.toDouble() ?? 1.0),
        voucherBookId: Value(voucherBookIdInt),
        warehouse: Value(payload['warehouse']?.toString()),
        notes: Value(payload['notes']?.toString()),
        issueDate: Value((payload['issueDate'] as int?) ?? (payload['issue_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch),
        createdAt: Value(existing?.createdAt ?? change.updatedAt.millisecondsSinceEpoch),
        updatedAt: Value(change.updatedAt.millisecondsSinceEpoch),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(now.millisecondsSinceEpoch),
        version: Value(remoteVersion),
        companyId: Value(companyId),
        status: Value(_postingCoordinator != null && payload['status']?.toString() == 'posted' && (existing == null || existing.status != 'posted') ? 'draft' : (payload['status']?.toString() ?? 'draft')),
        postedAt: Value((payload['postedAt'] as int?) ?? (payload['posted_at'] as int?)),
        deletedAt: Value(deletedAt),
      );

      if (existing != null) {
        await (db.update(db.stockIssues)..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId))).write(companion);
      } else {
        await db.into(db.stockIssues).insert(companion);
      }

      await (db.delete(db.stockMovementLines)..where((t) => t.movementUuid.equals(entityId))).go();
      final rawLines = payload['lines'];
      if (rawLines is List) {
        for (final raw in rawLines) {
          if (raw is! Map) continue;
          final l = Map<String, dynamic>.from(raw);
          final rawLineUuid = l['id']?.toString() ?? l['uuid']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
          await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(_normalizeUuid(rawLineUuid)),
              movementUuid: Value(entityId),
              movementType: const Value('issue'),
              itemCode: Value(l['itemCode']?.toString() ?? l['item_code']?.toString() ?? ''),
              itemName: Value((l['itemName']?.toString() ?? l['item_name']?.toString() ?? l['itemCode']?.toString() ?? l['item_code']?.toString() ?? '').isNotEmpty ? (l['itemName']?.toString() ?? l['item_name']?.toString() ?? l['itemCode']?.toString() ?? l['item_code']?.toString() ?? '') : 'Item'),
              mainQuantity: Value((l['mainQuantity'] as num?)?.toDouble() ?? (l['quantity'] as num?)?.toDouble() ?? 0.0),
              subQuantity: Value((l['subQuantity'] as num?)?.toDouble() ?? 0.0),
              quantity: Value((l['quantity'] as num?)?.toDouble() ?? 0.0),
              unitCost: Value((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0),
              totalCost: Value(
                (l['totalCost'] as num?)?.toDouble() ??
                (l['total_cost'] as num?)?.toDouble() ??
                (((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0) *
                 ((l['quantity'] as num?)?.toDouble() ?? (l['mainQuantity'] as num?)?.toDouble() ?? 0.0)),
              ),
              postedCost: Value((l['postedCost'] as num?)?.toDouble() ?? (l['posted_cost'] as num?)?.toDouble()),
              postedAt: Value((l['postedAt'] as int?) ?? (l['posted_at'] as int?)),
            ),
          );
        }
      }
    });

    if (payload['status'] == 'posted' && deletedAt == null && _postingCoordinator != null) {
      final ref = InventoryDocumentRef(
        documentId: entityId,
        documentNumber: payload['issueNumber']?.toString() ?? payload['issue_number']?.toString() ?? '',
        documentType: InventoryDocumentType.stockIssue,
        warehouseId: payload['warehouseId']?.toString() ?? payload['warehouse_id']?.toString() ?? payload['warehouse']?.toString(),
        documentDate: DateTime.fromMillisecondsSinceEpoch(
          (payload['issueDate'] as int?) ?? (payload['issue_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch,
        ),
        status: InventoryDocumentStatus.posted,
      );
      final postResult = await _postingCoordinator.post(document: ref);
      if (postResult is! PostSuccess) {
        throw StateError('Remote sync stock issue posting failed: $postResult');
      }
    }
  }

  Future<void> _applyStockTransfer(
    InventoryDatabase db,
    String entityId,
    SyncRemoteChange change,
    Map<String, dynamic> payload,
    String companyId,
    DateTime now,
  ) async {
    int? deletedAt;
    await db.transaction(() async {
      final existing = await (db.select(db.stockTransfers)
            ..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId)))
          .getSingleOrNull();

      final remoteVersion = change.version;
      if (existing != null && existing.version >= remoteVersion) {
        return;
      }

      if (existing != null && existing.status == 'posted') {
        final remoteStatus = payload['status']?.toString();
        final isRemoteDelete = change.deleted || payload['deletedAt'] != null;
        if (remoteStatus != 'posted' || isRemoteDelete) {
          throw StateError('Sync conflict: Cannot overwrite or unpost posted financial document ($entityId)');
        }
      }

      deletedAt = change.deleted || payload['deletedAt'] != null
          ? (payload['deletedAt'] as int? ?? change.updatedAt.millisecondsSinceEpoch)
          : null;

      final companion = StockTransfersCompanion(
        uuid: Value(entityId),
        transferNumber: Value(payload['transferNumber']?.toString() ?? payload['transfer_number']?.toString() ?? ''),
        fromWarehouseId: Value(payload['fromWarehouseId']?.toString() ?? payload['from_warehouse_id']?.toString() ?? ''),
        toWarehouseId: Value(payload['toWarehouseId']?.toString() ?? payload['to_warehouse_id']?.toString() ?? ''),
        transferDate: Value((payload['transferDate'] as int?) ?? (payload['transfer_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch),
        notes: Value(payload['notes']?.toString()),
        createdAt: Value(existing?.createdAt ?? change.updatedAt.millisecondsSinceEpoch),
        updatedAt: Value(change.updatedAt.millisecondsSinceEpoch),
        syncStatus: const Value('synced'),
        version: Value(remoteVersion),
        companyId: Value(companyId),
        status: Value(_postingCoordinator != null && payload['status']?.toString() == 'posted' && (existing == null || existing.status != 'posted') ? 'draft' : (payload['status']?.toString() ?? 'draft')),
        deletedAt: Value(deletedAt),
      );

      if (existing != null) {
        await (db.update(db.stockTransfers)..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId))).write(companion);
      } else {
        await db.into(db.stockTransfers).insert(companion);
      }

      await (db.delete(db.stockMovementLines)..where((t) => t.movementUuid.equals(entityId))).go();
      final rawLines = payload['lines'];
      if (rawLines is List) {
        for (final raw in rawLines) {
          if (raw is! Map) continue;
          final l = Map<String, dynamic>.from(raw);
          final rawLineUuid = l['id']?.toString() ?? l['uuid']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
          await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(_normalizeUuid(rawLineUuid)),
              movementUuid: Value(entityId),
              movementType: const Value('transfer'),
              itemCode: Value(l['itemCode']?.toString() ?? l['item_code']?.toString() ?? ''),
              itemName: Value((l['itemName']?.toString() ?? l['item_name']?.toString() ?? l['itemCode']?.toString() ?? l['item_code']?.toString() ?? '').isNotEmpty ? (l['itemName']?.toString() ?? l['item_name']?.toString() ?? l['itemCode']?.toString() ?? l['item_code']?.toString() ?? '') : 'Item'),
              mainQuantity: Value((l['mainQuantity'] as num?)?.toDouble() ?? (l['quantity'] as num?)?.toDouble() ?? 0.0),
              subQuantity: Value((l['subQuantity'] as num?)?.toDouble() ?? 0.0),
              quantity: Value((l['quantity'] as num?)?.toDouble() ?? 0.0),
              unitCost: Value((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0),
              totalCost: Value(
                (l['totalCost'] as num?)?.toDouble() ??
                (l['total_cost'] as num?)?.toDouble() ??
                (((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0) *
                 ((l['quantity'] as num?)?.toDouble() ?? (l['mainQuantity'] as num?)?.toDouble() ?? 0.0)),
              ),
            ),
          );
        }
      }
    });

    if (payload['status'] == 'posted' && deletedAt == null && _postingCoordinator != null) {
      final ref = InventoryDocumentRef(
        documentId: entityId,
        documentNumber: payload['transferNumber']?.toString() ?? payload['transfer_number']?.toString() ?? '',
        documentType: InventoryDocumentType.stockTransfer,
        warehouseId: payload['fromWarehouseId']?.toString() ?? payload['from_warehouse_id']?.toString(),
        documentDate: DateTime.fromMillisecondsSinceEpoch(
          (payload['transferDate'] as int?) ?? (payload['transfer_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch,
        ),
        status: InventoryDocumentStatus.posted,
      );
      final postResult = await _postingCoordinator.post(document: ref);
      if (postResult is! PostSuccess) {
        throw StateError('Remote sync stock transfer posting failed: $postResult');
      }
    }
  }

  Future<void> _applyStockReturn(
    InventoryDatabase db,
    String entityId,
    SyncRemoteChange change,
    Map<String, dynamic> payload,
    String companyId,
    DateTime now,
  ) async {
    int? deletedAt;
    String returnTypeStr = 'sales_return';
    await db.transaction(() async {
      final existing = await (db.select(db.stockReturns)
            ..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId)))
          .getSingleOrNull();

      final remoteVersion = change.version;
      if (existing != null && existing.version >= remoteVersion) {
        return;
      }

      if (existing != null && existing.status == 'posted') {
        final remoteStatus = payload['status']?.toString();
        final isRemoteDelete = change.deleted || payload['deletedAt'] != null;
        if (remoteStatus != 'posted' || isRemoteDelete) {
          throw StateError('Sync conflict: Cannot overwrite or unpost posted financial document ($entityId)');
        }
      }

      deletedAt = change.deleted || payload['deletedAt'] != null
          ? (payload['deletedAt'] as int? ?? change.updatedAt.millisecondsSinceEpoch)
          : null;

      returnTypeStr = payload['returnType']?.toString() ?? payload['return_type']?.toString() ?? 'sales_return';

      final companion = StockReturnsCompanion(
        uuid: Value(entityId),
        returnNumber: Value(payload['returnNumber']?.toString() ?? payload['return_number']?.toString() ?? ''),
        returnType: Value(returnTypeStr),
        originalMovementUuid: Value(payload['originalMovementUuid']?.toString() ?? payload['original_movement_uuid']?.toString()),
        partyName: Value(payload['partyName']?.toString() ?? payload['party_name']?.toString()),
        warehouse: Value(payload['warehouse']?.toString()),
        notes: Value(payload['notes']?.toString()),
        returnDate: Value((payload['returnDate'] as int?) ?? (payload['return_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch),
        createdAt: Value(existing?.createdAt ?? change.updatedAt.millisecondsSinceEpoch),
        updatedAt: Value(change.updatedAt.millisecondsSinceEpoch),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(now.millisecondsSinceEpoch),
        version: Value(remoteVersion),
        companyId: Value(companyId),
        status: Value(_postingCoordinator != null && payload['status']?.toString() == 'posted' && (existing == null || existing.status != 'posted') ? 'draft' : (payload['status']?.toString() ?? 'draft')),
        postedAt: Value((payload['postedAt'] as int?) ?? (payload['posted_at'] as int?)),
        deletedAt: Value(deletedAt),
      );

      if (existing != null) {
        await (db.update(db.stockReturns)..where((t) => t.uuid.equals(entityId) & t.companyId.equals(companyId))).write(companion);
      } else {
        await db.into(db.stockReturns).insert(companion);
      }

      await (db.delete(db.stockMovementLines)..where((t) => t.movementUuid.equals(entityId))).go();
      final rawLines = payload['lines'];
      if (rawLines is List) {
        for (final raw in rawLines) {
          if (raw is! Map) continue;
          final l = Map<String, dynamic>.from(raw);
          final rawLineUuid = l['id']?.toString() ?? l['uuid']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();
          await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion(
              uuid: Value(_normalizeUuid(rawLineUuid)),
              movementUuid: Value(entityId),
              movementType: Value(returnTypeStr),
              itemCode: Value(l['itemCode']?.toString() ?? l['item_code']?.toString() ?? ''),
              itemName: Value(l['itemName']?.toString() ?? l['item_name']?.toString() ?? ''),
              mainQuantity: Value((l['mainQuantity'] as num?)?.toDouble() ?? (l['quantity'] as num?)?.toDouble() ?? 0.0),
              subQuantity: Value((l['subQuantity'] as num?)?.toDouble() ?? 0.0),
              quantity: Value((l['quantity'] as num?)?.toDouble() ?? 0.0),
              unitCost: Value((l['unitCost'] as num?)?.toDouble() ?? (l['unit_cost'] as num?)?.toDouble() ?? 0.0),
              totalCost: Value((l['totalCost'] as num?)?.toDouble() ?? (l['total_cost'] as num?)?.toDouble() ?? 0.0),
              postedCost: Value((l['postedCost'] as num?)?.toDouble() ?? (l['posted_cost'] as num?)?.toDouble()),
              postedAt: Value((l['postedAt'] as int?) ?? (l['posted_at'] as int?)),
            ),
          );
        }
      }
    });

    if (payload['status'] == 'posted' && deletedAt == null && _postingCoordinator != null) {
      final ref = InventoryDocumentRef(
        documentId: entityId,
        documentNumber: payload['returnNumber']?.toString() ?? payload['return_number']?.toString() ?? '',
        documentType: InventoryDocumentType.stockReturn,
        warehouseId: payload['warehouseId']?.toString() ?? payload['warehouse_id']?.toString() ?? payload['warehouse']?.toString(),
        documentDate: DateTime.fromMillisecondsSinceEpoch(
          (payload['returnDate'] as int?) ?? (payload['return_date'] as int?) ?? change.updatedAt.millisecondsSinceEpoch,
        ),
        status: InventoryDocumentStatus.posted,
      );
      final postResult = await _postingCoordinator.post(document: ref);
      if (postResult is! PostSuccess) {
        throw StateError('Remote sync stock return posting failed: $postResult');
      }
    }
  }

  Future<void> _applyInventoryReversal(
    InventoryDatabase db,
    String entityId,
    SyncRemoteChange change,
    Map<String, dynamic> payload,
    String companyId,
    DateTime now,
  ) async {
    final targetDocumentId = payload['documentId']?.toString() ?? payload['document_id']?.toString() ?? entityId;
    final docTypeStr = payload['documentType']?.toString() ?? payload['document_type']?.toString() ?? '';

    final docType = InventoryDocumentType.values.firstWhere(
      (e) => e.name == docTypeStr || e.storageValue == docTypeStr,
      orElse: () => InventoryDocumentType.stockReceipt,
    );
    final ref = InventoryDocumentRef(
      documentId: targetDocumentId,
      documentNumber: payload['documentNumber']?.toString() ?? '',
      documentType: docType,
      documentDate: DateTime.now(),
      status: InventoryDocumentStatus.posted,
    );

    if (_postingCoordinator != null) {
      final unpostResult = await _postingCoordinator.unpost(
        document: ref,
        reason: payload['reason']?.toString() ?? 'Remote sync reversal',
      );
      if (unpostResult is! UnpostSuccess) {
        throw StateError('Remote sync inventory reversal failed: $unpostResult');
      }
    } else if (_postingEngine != null) {
      await _postingEngine.reversePosting(
        document: ref,
      );
    }
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final db = _db;
    if (db == null) return;
    final nowMs = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    final normEntityId = _normalizeUuid(entityId);

    await db.transaction(() async {
      switch (entityType) {
        case 'stock_receipt':
          await (db.update(db.stockReceipts)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            StockReceiptsCompanion(
              syncStatus: const Value('synced'),
              version: Value(remoteVersion),
              lastSyncedAt: Value(nowMs),
            ),
          );
          break;
        case 'stock_issue':
          await (db.update(db.stockIssues)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            StockIssuesCompanion(
              syncStatus: const Value('synced'),
              version: Value(remoteVersion),
              lastSyncedAt: Value(nowMs),
            ),
          );
          break;
        case 'stock_transfer':
          await (db.update(db.stockTransfers)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            StockTransfersCompanion(
              syncStatus: const Value('synced'),
              version: Value(remoteVersion),
              updatedAt: Value(nowMs),
            ),
          );
          break;
        case 'stock_return':
          await (db.update(db.stockReturns)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            StockReturnsCompanion(
              syncStatus: const Value('synced'),
              version: Value(remoteVersion),
              lastSyncedAt: Value(nowMs),
            ),
          );
          break;
      }
    });
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {
    final db = _db;
    if (db == null) return;
    final normEntityId = _normalizeUuid(entityId);

    await db.transaction(() async {
      switch (entityType) {
        case 'stock_receipt':
          await (db.update(db.stockReceipts)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            const StockReceiptsCompanion(syncStatus: Value('conflict')),
          );
          break;
        case 'stock_issue':
          await (db.update(db.stockIssues)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            const StockIssuesCompanion(syncStatus: Value('conflict')),
          );
          break;
        case 'stock_transfer':
          await (db.update(db.stockTransfers)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            const StockTransfersCompanion(syncStatus: Value('conflict')),
          );
          break;
        case 'stock_return':
          await (db.update(db.stockReturns)..where((t) => t.uuid.equals(normEntityId) & t.companyId.equals(_currentCompanyId))).write(
            const StockReturnsCompanion(syncStatus: Value('conflict')),
          );
          break;
      }
    });
  }
}
