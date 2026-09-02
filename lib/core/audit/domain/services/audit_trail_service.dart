import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../entities/audit_trail_entry.dart';

/// Centralized, append-only service for recording and retrieving audit trail events.
///
/// Audit logs recorded through this service are strictly immutable: no delete or
/// update interfaces exist.
class AuditTrailService {
  AuditTrailService({
    required this._db,
    this._syncQueue,
    this._readCompanyId,
  });

  final InventoryDatabase _db;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  /// Append-only audit record creation.
  Future<AuditTrailEntry> recordEvent({
    required String documentId,
    required String documentType,
    required String eventType,
    String? userId,
    String? notes,
    Map<String, dynamic>? metadata,
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;
    final eventUuid = generateUuidV4();
    final now = DateTime.now().toUtc();
    final timestampMs = now.millisecondsSinceEpoch;

    final entry = AuditTrailEntry(
      uuid: eventUuid,
      documentId: documentId,
      documentType: documentType,
      eventType: eventType,
      userId: userId,
      notes: notes,
      timestamp: now,
      metadata: metadata,
      companyId: effectiveCompanyId,
    );

    await _db.into(_db.inventoryAuditTrail).insert(
          InventoryAuditTrailCompanion(
            uuid: Value(eventUuid),
            documentId: Value(documentId),
            documentType: Value(documentType),
            eventType: Value(eventType),
            userId: Value(userId),
            notes: Value(notes),
            timestamp: Value(timestampMs),
            metadata: Value(entry.metadataJson),
            companyId: Value(effectiveCompanyId),
          ),
        );

    if (_syncQueue != null) {
      await _syncQueue.enqueue(
        SyncOperation.create(
          entityType: 'audit_event',
          entityId: eventUuid,
          type: SyncOperationType.create,
          companyId: effectiveCompanyId,
          payload: {
            'uuid': eventUuid,
            'documentId': documentId,
            'documentType': documentType,
            'eventType': eventType,
            'userId': userId,
            'notes': notes,
            'timestamp': timestampMs,
            'metadata': metadata,
            'companyId': effectiveCompanyId,
          },
        ),
      );
    }

    return entry;
  }

  /// Retrieve all audit events for a specific document, ordered chronologically.
  Future<List<AuditTrailEntry>> getAuditTrail({
    required String documentId,
    String? companyId,
  }) async {
    final query = _db.select(_db.inventoryAuditTrail)
      ..where((tbl) => tbl.documentId.equals(documentId));

    final targetCompany = companyId ?? _currentCompanyId;
    query.where((tbl) => tbl.companyId.equals(targetCompany) | tbl.companyId.isNull());
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]);

    final rows = await query.get();
    return rows
        .map((r) => AuditTrailEntry.fromStorage(
              id: r.id,
              uuid: r.uuid,
              documentId: r.documentId,
              documentType: r.documentType,
              eventType: r.eventType,
              userId: r.userId,
              notes: r.notes,
              timestampMs: r.timestamp,
              metadataRaw: r.metadata,
              companyId: r.companyId,
            ))
        .toList();
  }

  /// Query audit events by event type and company ID.
  Future<List<AuditTrailEntry>> getAuditTrailByCompany({
    required String companyId,
    String? eventType,
    int limit = 100,
  }) async {
    final query = _db.select(_db.inventoryAuditTrail)
      ..where((tbl) => tbl.companyId.equals(companyId));

    if (eventType != null) {
      query.where((tbl) => tbl.eventType.equals(eventType));
    }

    query.orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]);
    query.limit(limit);

    final rows = await query.get();
    return rows
        .map((r) => AuditTrailEntry.fromStorage(
              id: r.id,
              uuid: r.uuid,
              documentId: r.documentId,
              documentType: r.documentType,
              eventType: r.eventType,
              userId: r.userId,
              notes: r.notes,
              timestampMs: r.timestamp,
              metadataRaw: r.metadata,
              companyId: r.companyId,
            ))
        .toList();
  }
}
