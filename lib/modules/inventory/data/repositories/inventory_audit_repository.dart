import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:stock_count/core/audit/domain/ports/audit_repository_port.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';

/// Drift-based implementation of [AuditRepositoryPort] using [InventoryDatabase].
class InventoryAuditRepository implements AuditRepositoryPort {
  /// Creates an [InventoryAuditRepository] backed by [InventoryDatabase].
  InventoryAuditRepository(this._db);

  final InventoryDatabase _db;

  @override
  Future<void> record(AuditEntry entry) async {
    final String? notes = entry.metadata != null
        ? entry.metadata!['notes'] as String?
        : null;
    final String? metadataJson = entry.metadata != null
        ? jsonEncode(entry.metadata)
        : null;

    await _db
        .into(_db.inventoryAuditTrail)
        .insert(
          InventoryAuditTrailCompanion(
            uuid: Value(entry.id),
            documentId: Value(entry.entityId),
            documentType: Value(entry.entityType),
            eventType: Value(entry.action),
            userId: Value(entry.userId),
            notes: Value(notes),
            timestamp: Value(entry.timestamp.millisecondsSinceEpoch),
            metadata: Value(metadataJson),
            companyId: Value(entry.companyId),
          ),
        );
  }

  @override
  Future<List<AuditEntry>> getForCompany(
    String companyId, {
    int limit = 100,
  }) async {
    final query = _db.select(_db.inventoryAuditTrail)
      ..where((tbl) => tbl.companyId.equals(companyId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_mapRowToEntry).toList();
  }

  @override
  Future<List<AuditEntry>> getSystemAudits({int limit = 100}) async {
    final query = _db.select(_db.inventoryAuditTrail)
      ..where((tbl) => tbl.companyId.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_mapRowToEntry).toList();
  }

  @override
  Future<List<AuditEntry>> getForEntity(
    String entityType,
    String entityId, {
    String? companyId,
    int limit = 100,
  }) async {
    final query = _db.select(_db.inventoryAuditTrail)
      ..where((tbl) => tbl.documentId.equals(entityId));

    if (entityType.isNotEmpty) {
      query.where((tbl) => tbl.documentType.equals(entityType));
    }

    if (companyId != null) {
      query.where(
        (tbl) => tbl.companyId.equals(companyId) | tbl.companyId.isNull(),
      );
    }

    query.orderBy([(tbl) => OrderingTerm.asc(tbl.timestamp)]);
    query.limit(limit);

    final rows = await query.get();
    return rows.map(_mapRowToEntry).toList();
  }

  AuditEntry _mapRowToEntry(InventoryAuditTrailRow row) {
    Map<String, dynamic>? meta;
    if (row.metadata != null && row.metadata!.trim().isNotEmpty) {
      try {
        meta = jsonDecode(row.metadata!) as Map<String, dynamic>?;
      } catch (_) {}
    }
    if (row.notes != null && row.notes!.isNotEmpty) {
      meta = <String, dynamic>{
        ...?meta,
        if (row.notes != null) 'notes': row.notes,
      };
    }

    return AuditEntry(
      id: row.uuid,
      companyId: row.companyId,
      userId: row.userId ?? '',
      action: row.eventType,
      entityType: row.documentType,
      entityId: row.documentId,
      metadata: meta,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        row.timestamp,
        isUtc: true,
      ),
    );
  }
}
