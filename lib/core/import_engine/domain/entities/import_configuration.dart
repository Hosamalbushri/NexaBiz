import 'import_assignment.dart';
import 'import_execution_mode.dart';
import 'import_policy.dart';
import 'import_sync_mode.dart';

/// Resolved mapping configuration and operational parameters for an import run.
class ImportConfiguration {
  const ImportConfiguration({
    required this.profileId,
    required this.assignments,
    this.policy = const ImportPolicy(),
    this.executionMode = ImportExecutionMode.commit,
    this.syncMode = ImportSyncMode.local,
  });

  final String profileId;
  final List<ImportAssignment> assignments;
  final ImportPolicy policy;
  final ImportExecutionMode executionMode;
  final ImportSyncMode syncMode;

  /// Returns true if an assignment exists for the specified [fieldKey].
  bool hasAssignmentFor(String fieldKey) {
    return assignments.any(
      (assignment) => assignment.targetFieldKey == fieldKey,
    );
  }

  /// Retrieves the assignment for [fieldKey] or null if unmapped.
  ImportAssignment? getAssignmentFor(String fieldKey) {
    for (final assignment in assignments) {
      if (assignment.targetFieldKey == fieldKey) return assignment;
    }
    return null;
  }
}
