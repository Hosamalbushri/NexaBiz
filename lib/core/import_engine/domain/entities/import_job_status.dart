import '../exceptions/import_engine_exception.dart';

/// Represents the explicit lifecycle states of an import job.
enum ImportJobStatus {
  queued,
  preparing,
  processing,
  paused,
  completed,
  completedWithErrors,
  failed,
  cancelled;

  /// Returns true if the job has reached a terminal state.
  bool get isTerminal =>
      this == ImportJobStatus.completed ||
      this == ImportJobStatus.completedWithErrors ||
      this == ImportJobStatus.failed ||
      this == ImportJobStatus.cancelled;

  /// Returns true if the job is actively executing.
  bool get isActive =>
      this == ImportJobStatus.queued ||
      this == ImportJobStatus.preparing ||
      this == ImportJobStatus.processing;

  /// Validates whether transitioning from [this] status to [next] is permitted.
  bool canTransitionTo(ImportJobStatus next) {
    if (this == next) return true;
    if (isTerminal) return false;

    switch (this) {
      case ImportJobStatus.queued:
        return next == ImportJobStatus.preparing ||
            next == ImportJobStatus.processing ||
            next == ImportJobStatus.cancelled;

      case ImportJobStatus.preparing:
        return next == ImportJobStatus.processing ||
            next == ImportJobStatus.failed ||
            next == ImportJobStatus.cancelled;

      case ImportJobStatus.processing:
        return next == ImportJobStatus.paused ||
            next == ImportJobStatus.completed ||
            next == ImportJobStatus.completedWithErrors ||
            next == ImportJobStatus.failed ||
            next == ImportJobStatus.cancelled;

      case ImportJobStatus.paused:
        return next == ImportJobStatus.processing ||
            next == ImportJobStatus.cancelled ||
            next == ImportJobStatus.failed;

      case ImportJobStatus.completed:
      case ImportJobStatus.completedWithErrors:
      case ImportJobStatus.failed:
      case ImportJobStatus.cancelled:
        return false;
    }
  }

  /// Ensures a valid transition to [next] or throws [ImportStatusTransitionException].
  void ensureCanTransitionTo(ImportJobStatus next) {
    if (!canTransitionTo(next)) {
      throw ImportStatusTransitionException(name, next.name);
    }
  }
}
