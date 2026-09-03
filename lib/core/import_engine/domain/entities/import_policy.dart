/// Strategy for handling duplicate entity records during import.
enum DuplicateResolutionStrategy {
  /// Skip duplicate rows and continue.
  skip,

  /// Overwrite existing entity with imported values.
  overwrite,

  /// Mark row as error and fail/skip according to policy.
  error,

  /// Create a secondary entity with generated unique code/ID.
  createSecondary,
}

/// Operational policy governing import execution behavior.
class ImportPolicy {
  const ImportPolicy({
    this.duplicateResolution = DuplicateResolutionStrategy.skip,
    this.allowPartialSuccess = false,
    this.stopOnErrorCount,
    this.batchSize = 100,
    this.createMissingRelations = false,
  }) : assert(batchSize > 0, 'Batch size must be greater than zero.');

  final DuplicateResolutionStrategy duplicateResolution;
  final bool allowPartialSuccess;
  final int? stopOnErrorCount;
  final int batchSize;
  final bool createMissingRelations;

  ImportPolicy copyWith({
    DuplicateResolutionStrategy? duplicateResolution,
    bool? allowPartialSuccess,
    int? stopOnErrorCount,
    int? batchSize,
    bool? createMissingRelations,
  }) {
    return ImportPolicy(
      duplicateResolution: duplicateResolution ?? this.duplicateResolution,
      allowPartialSuccess: allowPartialSuccess ?? this.allowPartialSuccess,
      stopOnErrorCount: stopOnErrorCount ?? this.stopOnErrorCount,
      batchSize: batchSize ?? this.batchSize,
      createMissingRelations:
          createMissingRelations ?? this.createMissingRelations,
    );
  }
}
