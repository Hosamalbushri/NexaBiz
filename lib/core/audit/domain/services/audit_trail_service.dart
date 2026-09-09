import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/sync/sync.dart';

import '../entities/audit_trail_entry.dart';
import '../ports/audit_repository_port.dart';

/// Centralized, append-only service for recording and retrieving audit trail events.
///
/// Audit logs recorded through this service are strictly immutable.
/// Decoupled from database implementation drivers via [AuditRepositoryPort].
class AuditTrailService {
  /// Creates an [AuditTrailService] with the provided repository, session context, and optional sync queue.
  AuditTrailService({
    required this.repository,
    required this.sessionContext,
    this.syncQueue,
  });

  final AuditRepositoryPort repository;
  final SessionContextPort sessionContext;
  final SyncQueue? syncQueue;

  /// Record an audit entry using domain [AuditEntry].
  Future<void> recordAudit(AuditEntry entry) async {
    await repository.record(entry);

    final effectiveCompanyId =
        entry.companyId ?? sessionContext.currentCompanyId;
    if (syncQueue != null && effectiveCompanyId != null) {
      await syncQueue!.enqueue(
        SyncOperation.create(
          entityType: 'audit_event',
          entityId: entry.id,
          type: SyncOperationType.create,
          companyId: effectiveCompanyId,
          payload: {
            'uuid': entry.id,
            'documentId': entry.entityId,
            'documentType': entry.entityType,
            'eventType': entry.action,
            'userId': entry.userId,
            'notes': entry.metadata?['notes'],
            'timestamp': entry.timestamp.millisecondsSinceEpoch,
            'metadata': entry.metadata,
            'companyId': effectiveCompanyId,
          },
        ),
      );
    }
  }

  /// Append-only audit record creation (legacy helper returning [AuditTrailEntry]).
  Future<AuditTrailEntry> recordEvent({
    required String documentId,
    required String documentType,
    required String eventType,
    String? userId,
    String? notes,
    Map<String, dynamic>? metadata,
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? sessionContext.currentCompanyId;
    final effectiveUserId = userId ?? sessionContext.userId ?? 'system';
    final eventUuid = generateUuidV4();
    final now = DateTime.now().toUtc();

    final Map<String, dynamic> meta = <String, dynamic>{
      ...?notes != null ? {'notes': notes} : null,
      ...?metadata,
    };

    final entry = AuditEntry(
      id: eventUuid,
      companyId: effectiveCompanyId,
      userId: effectiveUserId,
      action: eventType,
      entityType: documentType,
      entityId: documentId,
      metadata: meta.isNotEmpty ? meta : null,
      timestamp: now,
    );

    await recordAudit(entry);

    return AuditTrailEntry(
      uuid: eventUuid,
      documentId: documentId,
      documentType: documentType,
      eventType: eventType,
      userId: effectiveUserId,
      notes: notes,
      timestamp: now,
      metadata: metadata,
      companyId: effectiveCompanyId,
    );
  }

  /// Retrieve all audit events for a specific document, ordered chronologically.
  Future<List<AuditTrailEntry>> getAuditTrail({
    required String documentId,
    String? companyId,
    String? documentType,
  }) async {
    final effectiveCompanyId = companyId ?? sessionContext.currentCompanyId;
    final entries = await repository.getForEntity(
      documentType ?? '',
      documentId,
      companyId: effectiveCompanyId,
    );

    return entries.map(_toAuditTrailEntry).toList();
  }

  /// Query audit events by event type and company ID.
  Future<List<AuditTrailEntry>> getAuditTrailByCompany({
    required String companyId,
    String? eventType,
    int limit = 100,
  }) async {
    final entries = await repository.getForCompany(companyId, limit: limit);

    final filtered = eventType != null
        ? entries.where((e) => e.action == eventType)
        : entries;

    return filtered.map(_toAuditTrailEntry).toList();
  }

  /// Query system-level audit events where companyId IS NULL.
  Future<List<AuditTrailEntry>> getSystemAudits({int limit = 100}) async {
    final entries = await repository.getSystemAudits(limit: limit);
    return entries.map(_toAuditTrailEntry).toList();
  }

  AuditTrailEntry _toAuditTrailEntry(AuditEntry entry) {
    return AuditTrailEntry(
      uuid: entry.id,
      documentId: entry.entityId,
      documentType: entry.entityType,
      eventType: entry.action,
      userId: entry.userId,
      notes: entry.metadata?['notes'] as String?,
      timestamp: entry.timestamp,
      metadata: entry.metadata,
      companyId: entry.companyId,
    );
  }
}
