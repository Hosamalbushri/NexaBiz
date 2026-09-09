/// Immutable domain entity representing a single audit log entry in Core.
class AuditEntry {
  const AuditEntry({
    required this.id,
    this.companyId,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.metadata,
    required this.timestamp,
  });

  /// Unique identifier of the audit entry (e.g. UUID).
  final String id;

  /// Optional company ID associated with the audit event.
  /// Null indicates a system-level or unassigned audit log.
  final String? companyId;

  /// User ID of the actor who performed the action.
  final String userId;

  /// Action or event type (e.g. 'post', 'unpost', 'create', 'delete').
  final String action;

  /// Type of entity affected (e.g. 'stock_receipt', 'journal_entry', 'branch').
  final String entityType;

  /// ID or UUID of the entity affected.
  final String entityId;

  /// Optional metadata payload associated with the audit record.
  final Map<String, dynamic>? metadata;

  /// Timestamp when the audit event occurred.
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          companyId == other.companyId &&
          userId == other.userId &&
          action == other.action &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      companyId.hashCode ^
      userId.hashCode ^
      action.hashCode ^
      entityType.hashCode ^
      entityId.hashCode ^
      timestamp.hashCode;
}

/// Abstract repository port for storing and querying audit records.
///
/// Decouples Core domain audit tracking from specific database drivers (e.g. Drift).
abstract class AuditRepositoryPort {
  /// Record a new append-only audit entry.
  Future<void> record(AuditEntry entry);

  /// Retrieve audit entries for a specific company, ordered newest first.
  Future<List<AuditEntry>> getForCompany(String companyId, {int limit = 100});

  /// Retrieve system-level audit entries where [companyId] IS NULL.
  Future<List<AuditEntry>> getSystemAudits({int limit = 100});

  /// Retrieve audit entries for a specific entity.
  Future<List<AuditEntry>> getForEntity(
    String entityType,
    String entityId, {
    String? companyId,
    int limit = 100,
  });
}
