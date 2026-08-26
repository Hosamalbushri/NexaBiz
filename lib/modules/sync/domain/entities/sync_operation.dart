import 'package:stock_count/core/utils/id_generator.dart';
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
    this.companyId,
    this.deviceId,
    this.firstFailureAt,
    this.lastFailureAt,
    this.quarantinedAt,
  });

  factory SyncOperation.create({
    required String entityType,
    required String entityId,
    required SyncOperationType type,
    required Map<String, dynamic> payload,
    int baseVersion = 0,
    DateTime? now,
    String? companyId,
    String? deviceId,
  }) {
    final stamp = (now ?? DateTime.now().toUtc());
    // Creates are "ensure exists" — never based on a prior server version.
    // Passing entity.version here used to trip getMeta conflicts on dual seeds.
    final resolvedBase =
        type == SyncOperationType.create ? 0 : baseVersion;
    return SyncOperation(
      id: generateUuidV4(),
      entityType: entityType,
      entityId: entityId,
      type: type,
      status: SyncStatus.pending,
      payload: Map<String, dynamic>.from(payload),
      createdAt: stamp,
      updatedAt: stamp,
      baseVersion: resolvedBase,
      companyId: companyId,
      deviceId: deviceId,
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
  final String? companyId;
  final String? deviceId;
  final DateTime? firstFailureAt;
  final DateTime? lastFailureAt;
  final DateTime? quarantinedAt;

  /// Version this mutation was based on (conflict base for update/delete).
  /// Always `0` for [SyncOperationType.create] (ensure-exists, not a rebase).
  final int baseVersion;

  SyncOperation copyWith({
    SyncOperationType? type,
    SyncStatus? status,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? attemptCount,
    String? lastError,
    bool clearLastError = false,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    int? baseVersion,
    String? companyId,
    String? deviceId,
    DateTime? firstFailureAt,
    DateTime? lastFailureAt,
    DateTime? quarantinedAt,
    bool clearQuarantine = false,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      type: type ?? this.type,
      status: status ?? this.status,
      payload: payload ?? Map<String, dynamic>.from(this.payload),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      baseVersion: baseVersion ?? this.baseVersion,
      companyId: companyId ?? this.companyId,
      deviceId: deviceId ?? this.deviceId,
      firstFailureAt: firstFailureAt ?? this.firstFailureAt,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
      quarantinedAt: clearQuarantine ? null : (quarantinedAt ?? this.quarantinedAt),
    );
  }
}
