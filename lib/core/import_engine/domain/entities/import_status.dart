import '../exceptions/import_engine_exception.dart';

/// Represents the lifecycle states of an import process.
enum ImportStatus {
  draft,
  configured,
  parsing,
  validating,
  resolving,
  persisting,
  completed,
  partiallyCompleted,
  failed,
  cancelled;

  /// Returns true if the import status represents a terminal state.
  bool get isTerminal =>
      this == ImportStatus.completed ||
      this == ImportStatus.partiallyCompleted ||
      this == ImportStatus.failed ||
      this == ImportStatus.cancelled;

  /// Returns true if the import process is currently running.
  bool get isActive =>
      this == ImportStatus.parsing ||
      this == ImportStatus.validating ||
      this == ImportStatus.resolving ||
      this == ImportStatus.persisting;

  /// Validates whether transitioning from [this] status to [next] is permitted.
  bool canTransitionTo(ImportStatus next) {
    if (this == next) return true;
    if (isTerminal) return false;

    switch (this) {
      case ImportStatus.draft:
        return next == ImportStatus.configured ||
            next == ImportStatus.cancelled;
      case ImportStatus.configured:
        return next == ImportStatus.parsing || next == ImportStatus.cancelled;
      case ImportStatus.parsing:
        return next == ImportStatus.validating ||
            next == ImportStatus.failed ||
            next == ImportStatus.cancelled;
      case ImportStatus.validating:
        return next == ImportStatus.resolving ||
            next == ImportStatus.failed ||
            next == ImportStatus.cancelled;
      case ImportStatus.resolving:
        return next == ImportStatus.persisting ||
            next == ImportStatus.failed ||
            next == ImportStatus.cancelled;
      case ImportStatus.persisting:
        return next == ImportStatus.completed ||
            next == ImportStatus.partiallyCompleted ||
            next == ImportStatus.failed ||
            next == ImportStatus.cancelled;
      case ImportStatus.completed:
      case ImportStatus.partiallyCompleted:
      case ImportStatus.failed:
      case ImportStatus.cancelled:
        return false;
    }
  }

  /// Ensures a valid transition to [next] or throws [ImportStatusTransitionException].
  void ensureCanTransitionTo(ImportStatus next) {
    if (!canTransitionTo(next)) {
      throw ImportStatusTransitionException(name, next.name);
    }
  }
}
