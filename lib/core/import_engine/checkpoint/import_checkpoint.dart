/// Value object recording a progress snapshot for an import job.
/// Enables deterministic checkpointing, crash recovery, resume, and idempotency protection.
class ImportCheckpoint {
  ImportCheckpoint({
    required this.jobId,
    required this.companyId,
    required this.lastProcessedRowIndex,
    required this.chunkSize,
    this.successfulRows = 0,
    this.failedRows = 0,
    this.skippedRows = 0,
    Set<String>? committedKeys,
    DateTime? timestamp,
  })  : committedKeys = Set.unmodifiable(committedKeys ?? {}),
        timestamp = timestamp ?? DateTime.now().toUtc();

  /// Target import job identifier.
  final String jobId;

  /// Mandatory multi-tenant isolation company identifier.
  final String companyId;

  /// Index of the last successfully processed and committed row (0-indexed).
  final int lastProcessedRowIndex;

  /// Number of rows processed per batch.
  final int chunkSize;

  /// Cumulative count of successful rows up to this checkpoint.
  final int successfulRows;

  /// Cumulative count of failed rows up to this checkpoint.
  final int failedRows;

  /// Cumulative count of skipped rows up to this checkpoint.
  final int skippedRows;

  /// Set of unique entity/row idempotency keys committed to the database.
  final Set<String> committedKeys;

  /// Timestamp when checkpoint was recorded.
  final DateTime timestamp;

  /// Returns true if a given idempotency key has already been committed.
  bool hasCommittedKey(String key) => committedKeys.contains(key);

  ImportCheckpoint copyWith({
    String? jobId,
    String? companyId,
    int? lastProcessedRowIndex,
    int? chunkSize,
    int? successfulRows,
    int? failedRows,
    int? skippedRows,
    Set<String>? committedKeys,
    DateTime? timestamp,
  }) {
    return ImportCheckpoint(
      jobId: jobId ?? this.jobId,
      companyId: companyId ?? this.companyId,
      lastProcessedRowIndex: lastProcessedRowIndex ?? this.lastProcessedRowIndex,
      chunkSize: chunkSize ?? this.chunkSize,
      successfulRows: successfulRows ?? this.successfulRows,
      failedRows: failedRows ?? this.failedRows,
      skippedRows: skippedRows ?? this.skippedRows,
      committedKeys: committedKeys ?? this.committedKeys,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
