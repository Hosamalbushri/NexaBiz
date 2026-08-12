import '../utils/id_generator.dart';
import 'sync_status.dart';

/// Kind of mutation represented by a queue entry.
enum SyncOperationType { create, update, delete }

/// Persistent sync-queue entry (no feature-specific entities).
class SyncOperation {
  SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.type,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.attemptCount = 0,
    this.lastError,
    this.nextRetryAt,
    this.baseVersion = 0,
  });

  factory SyncOperation.create({
    required String entityType,
    required String entityId,
    required SyncOperationType type,
    required Map<String, dynamic> payload,
    int baseVersion = 0,
    DateTime? now,
  }) {
    final stamp = (now ?? DateTime.now().toUtc());
    return SyncOperation(
      id: generateUuidV4(),
      entityType: entityType,
      entityId: entityId,
      type: type,
      status: SyncStatus.pending,
      payload: Map<String, dynamic>.from(payload),
      createdAt: stamp,
      updatedAt: stamp,
      baseVersion: baseVersion,
    );
  }

  final String id;
  final String entityType;
  final String entityId;
  final SyncOperationType type;
  final SyncStatus status;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attemptCount;
  final String? lastError;
  final DateTime? nextRetryAt;

  /// Local version observed when the mutation was enqueued (conflict base).
  final int baseVersion;

  SyncOperation copyWith({
    SyncStatus? status,
    Map<String, dynamic>? payload,
    DateTime? updatedAt,
    int? attemptCount,
    String? lastError,
    bool clearLastError = false,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    int? baseVersion,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      type: type,
      status: status ?? this.status,
      payload: payload ?? Map<String, dynamic>.from(this.payload),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      baseVersion: baseVersion ?? this.baseVersion,
    );
  }
}
