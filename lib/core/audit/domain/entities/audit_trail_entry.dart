import 'dart:convert';

/// Represents an immutable audit trail event entry.
class AuditTrailEntry {
  const AuditTrailEntry({
    required this.uuid,
    required this.documentId,
    required this.documentType,
    required this.eventType,
    required this.timestamp,
    this.id,
    this.userId,
    this.notes,
    this.metadata,
    this.companyId,
  });

  final int? id;
  final String uuid;
  final String documentId;
  final String documentType;
  final String eventType;
  final String? userId;
  final String? notes;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? companyId;

  String? get metadataJson => metadata != null ? jsonEncode(metadata) : null;

  factory AuditTrailEntry.fromStorage({
    int? id,
    required String uuid,
    required String documentId,
    required String documentType,
    required String eventType,
    String? userId,
    String? notes,
    required int timestampMs,
    String? metadataRaw,
    String? companyId,
  }) {
    Map<String, dynamic>? meta;
    if (metadataRaw != null && metadataRaw.trim().isNotEmpty) {
      try {
        meta = jsonDecode(metadataRaw) as Map<String, dynamic>?;
      } catch (_) {}
    }

    return AuditTrailEntry(
      id: id,
      uuid: uuid,
      documentId: documentId,
      documentType: documentType,
      eventType: eventType,
      userId: userId,
      notes: notes,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true),
      metadata: meta,
      companyId: companyId,
    );
  }
}
