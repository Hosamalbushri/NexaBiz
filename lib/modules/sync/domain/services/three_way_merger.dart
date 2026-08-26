import 'conflict_strategy.dart';

/// Result of a 3-way merge evaluation.
class ThreeWayMergeResult {
  const ThreeWayMergeResult({
    required this.isSuccess,
    required this.mergeStatus,
    this.mergedPayload,
    this.conflictingFields = const [],
    this.message,
  });

  final bool isSuccess;

  /// Status string: 'auto_merged', 'requires_user_resolution', 'rejected'.
  final String mergeStatus;

  final Map<String, dynamic>? mergedPayload;
  final List<String> conflictingFields;
  final String? message;
}

/// Deterministic 3-way payload merger (BASE, LOCAL, REMOTE).
class ThreeWayMerger {
  const ThreeWayMerger();

  ThreeWayMergeResult merge({
    required Map<String, dynamic> basePayload,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> remotePayload,
    required EntityConflictPolicy policy,
  }) {
    if (policy.strategy == ConflictStrategy.immutableReject) {
      return const ThreeWayMergeResult(
        isSuccess: false,
        mergeStatus: 'rejected',
        message: 'Entity is immutable and cannot be merged',
      );
    }

    final merged = <String, dynamic>{};
    final conflictingFields = <String>[];

    final allKeys = <String>{
      ...basePayload.keys,
      ...localPayload.keys,
      ...remotePayload.keys,
    };

    for (final key in allKeys) {
      final baseVal = basePayload[key];
      final localVal = localPayload[key];
      final remoteVal = remotePayload[key];

      // Never-merge fields check
      if (policy.neverMergeFields.contains(key)) {
        if (!_equals(localVal, remoteVal)) {
          conflictingFields.add(key);
        } else {
          merged[key] = remoteVal ?? localVal;
        }
        continue;
      }

      final localChanged = !_equals(localVal, baseVal);
      final remoteChanged = !_equals(remoteVal, baseVal);

      if (!localChanged && remoteChanged) {
        if (remoteVal != null) {
          merged[key] = remoteVal;
        }
      } else if (localChanged && !remoteChanged) {
        if (localVal != null) {
          merged[key] = localVal;
        }
      } else if (!localChanged && !remoteChanged) {
        if (baseVal != null) {
          merged[key] = baseVal;
        } else if (remoteVal != null) {
          merged[key] = remoteVal;
        } else if (localVal != null) {
          merged[key] = localVal;
        }
      } else {
        // Both local and remote changed
        if (_equals(localVal, remoteVal)) {
          if (localVal != null) {
            merged[key] = localVal;
          }
        } else {
          // True field conflict
          conflictingFields.add(key);
        }
      }
    }

    if (conflictingFields.isNotEmpty) {
      return ThreeWayMergeResult(
        isSuccess: false,
        mergeStatus: 'requires_user_resolution',
        conflictingFields: conflictingFields,
        message: 'True field conflict detected in fields: ${conflictingFields.join(', ')}',
      );
    }

    return ThreeWayMergeResult(
      isSuccess: true,
      mergeStatus: 'auto_merged',
      mergedPayload: merged,
      message: 'Successfully merged non-overlapping changes',
    );
  }

  bool _equals(Object? a, Object? b) {
    if (a == b) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.toString() == b.toString();
  }
}
