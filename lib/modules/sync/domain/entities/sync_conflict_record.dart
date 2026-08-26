import 'dart:convert';

/// Represents a durable conflict record capturing base, local, and remote states.
class SyncConflictRecord {
  const SyncConflictRecord({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.baseVersion,
    required this.serverVersion,
    required this.localPayload,
    required this.createdAt,
    this.remotePayload,
    this.conflictingFields = const [],
    this.mergeStatus = 'unresolved',
    this.resolutionStrategy = 'none',
    this.resolvedOperationId,
  });

  final String operationId;
  final String entityType;
  final String entityId;
  final int baseVersion;
  final int serverVersion;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic>? remotePayload;
  final List<String> conflictingFields;

  /// Merge status: 'unresolved', 'auto_merged', 'server_selected', 'client_selected', 'rejected', 'requires_user_resolution'
  final String mergeStatus;

  final String resolutionStrategy;
  final String? resolvedOperationId;
  final DateTime createdAt;

  SyncConflictRecord copyWith({
    String? operationId,
    String? entityType,
    String? entityId,
    int? baseVersion,
    int? serverVersion,
    Map<String, dynamic>? localPayload,
    Map<String, dynamic>? remotePayload,
    List<String>? conflictingFields,
    String? mergeStatus,
    String? resolutionStrategy,
    String? resolvedOperationId,
    DateTime? createdAt,
  }) {
    return SyncConflictRecord(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      baseVersion: baseVersion ?? this.baseVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      localPayload: localPayload ?? this.localPayload,
      remotePayload: remotePayload ?? this.remotePayload,
      conflictingFields: conflictingFields ?? this.conflictingFields,
      mergeStatus: mergeStatus ?? this.mergeStatus,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
      resolvedOperationId: resolvedOperationId ?? this.resolvedOperationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'entityType': entityType,
      'entityId': entityId,
      'baseVersion': baseVersion,
      'serverVersion': serverVersion,
      'localPayload': localPayload,
      'remotePayload': remotePayload,
      'conflictingFields': conflictingFields,
      'mergeStatus': mergeStatus,
      'resolutionStrategy': resolutionStrategy,
      'resolvedOperationId': resolvedOperationId,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory SyncConflictRecord.fromMap(Map<String, dynamic> map) {
    return SyncConflictRecord(
      operationId: map['operationId'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      baseVersion: (map['baseVersion'] as num?)?.toInt() ?? 0,
      serverVersion: (map['serverVersion'] as num?)?.toInt() ?? 0,
      localPayload: map['localPayload'] is Map
          ? Map<String, dynamic>.from(map['localPayload'] as Map)
          : const {},
      remotePayload: map['remotePayload'] is Map
          ? Map<String, dynamic>.from(map['remotePayload'] as Map)
          : null,
      conflictingFields: map['conflictingFields'] is List
          ? List<String>.from(map['conflictingFields'] as List)
          : const [],
      mergeStatus: map['mergeStatus'] as String? ?? 'unresolved',
      resolutionStrategy: map['resolutionStrategy'] as String? ?? 'none',
      resolvedOperationId: map['resolvedOperationId'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SyncConflictRecord.fromJson(String source) =>
      SyncConflictRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
