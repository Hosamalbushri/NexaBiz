import '../checkpoint/import_checkpoint.dart';
import '../checkpoint/import_checkpoint_repository.dart';
import '../domain/entities/import_job.dart';
import '../domain/entities/import_job_status.dart';
import '../domain/entities/parsed_row.dart';
import '../domain/ports/import_job_repository.dart';

/// Single row processing outcome used during chunked execution.
class ChunkRowOutcome {
  const ChunkRowOutcome({
    required this.rowIndex,
    required this.rowKey,
    required this.isSuccess,
    this.isSkipped = false,
    this.errorMessage,
  });

  final int rowIndex;
  final String rowKey;
  final bool isSuccess;
  final bool isSkipped;
  final String? errorMessage;
}

/// Scalable chunked execution engine.
/// Processes rows in configurable chunks, records periodic checkpoints,
/// and guarantees idempotent resume without duplicating committed records.
class ChunkedExecutionEngine {
  ChunkedExecutionEngine({
    required this.jobRepository,
    required this.checkpointRepository,
    this.defaultChunkSize = 500,
  });

  final ImportJobRepository jobRepository;
  final ImportCheckpointRepository checkpointRepository;
  final int defaultChunkSize;

  /// Executes chunked processing over [rows].
  /// [rowProcessor] processes an individual row and returns a [ChunkRowOutcome].
  /// [idempotencyKeyExtractor] extracts a unique row key (e.g. product code / UUID) for duplicate protection.
  /// [shouldSimulateFailureAtRow] optional callback for failure injection testing.
  Future<ImportJob> executeChunked({
    required ImportJob job,
    required List<ParsedRow> rows,
    required Future<ChunkRowOutcome> Function(ParsedRow row, int index)
    rowProcessor,
    String Function(ParsedRow row, int index)? idempotencyKeyExtractor,
    int? chunkSize,
    bool Function(int index)? shouldSimulateFailureAtRow,
  }) async {
    final activeChunkSize = chunkSize ?? defaultChunkSize;
    final companyId = job.companyId;
    final jobId = job.jobId;

    // 1. Fetch existing checkpoint for resume, if present
    final existingCp = await checkpointRepository.getLatestCheckpoint(
      jobId,
      companyId: companyId,
    );

    final int startIndex = existingCp != null
        ? existingCp.lastProcessedRowIndex + 1
        : 0;
    final Set<String> committedKeys = Set.of(
      existingCp?.committedKeys ?? <String>{},
    );
    int accumulatedSuccess = existingCp?.successfulRows ?? 0;
    int accumulatedFailed = existingCp?.failedRows ?? 0;
    int accumulatedSkipped = existingCp?.skippedRows ?? 0;

    var currentJob = job.status == ImportJobStatus.processing
        ? job
        : job.transitionTo(ImportJobStatus.processing);

    await jobRepository.save(currentJob);

    // 2. Iterate in bounded chunks
    final totalRows = rows.length;

    for (
      var chunkStart = startIndex;
      chunkStart < totalRows;
      chunkStart += activeChunkSize
    ) {
      final chunkEnd = (chunkStart + activeChunkSize < totalRows)
          ? chunkStart + activeChunkSize
          : totalRows;

      for (var i = chunkStart; i < chunkEnd; i++) {
        // Failure injection guard for testing
        if (shouldSimulateFailureAtRow != null &&
            shouldSimulateFailureAtRow(i)) {
          final errorMsg = 'Simulated failure injection at row $i';
          currentJob = currentJob.copyWith(
            status: ImportJobStatus.failed,
            errorSummary: [...currentJob.errorSummary, errorMsg],
          );
          await jobRepository.save(currentJob);
          throw Exception(errorMsg);
        }

        final row = rows[i];
        final rowKey = idempotencyKeyExtractor != null
            ? idempotencyKeyExtractor(row, i)
            : 'row_$i';

        // Idempotency duplicate protection check
        if (committedKeys.contains(rowKey)) {
          accumulatedSkipped++;
          continue;
        }

        final outcome = await rowProcessor(row, i);

        if (outcome.isSkipped) {
          accumulatedSkipped++;
        } else if (outcome.isSuccess) {
          accumulatedSuccess++;
          committedKeys.add(rowKey);
        } else {
          accumulatedFailed++;
          if (outcome.errorMessage != null) {
            currentJob = currentJob.copyWith(
              errorSummary: [...currentJob.errorSummary, outcome.errorMessage!],
            );
          }
        }
      }

      final lastProcessedIndex = chunkEnd - 1;
      final progress = totalRows > 0 ? (chunkEnd / totalRows) : 1.0;

      // 3. Save periodic Checkpoint after each chunk
      final cp = ImportCheckpoint(
        jobId: jobId,
        companyId: companyId,
        lastProcessedRowIndex: lastProcessedIndex,
        chunkSize: activeChunkSize,
        successfulRows: accumulatedSuccess,
        failedRows: accumulatedFailed,
        skippedRows: accumulatedSkipped,
        committedKeys: committedKeys,
      );
      await checkpointRepository.save(cp);

      // 4. Update Job Progress & Metrics
      currentJob = currentJob.copyWith(
        processedRows: chunkEnd,
        successfulRows: accumulatedSuccess,
        failedRows: accumulatedFailed,
        skippedRows: accumulatedSkipped,
        progress: progress,
      );
      await jobRepository.save(currentJob);
    }

    // 5. Finalize Job Completion
    final finalStatus = accumulatedFailed > 0
        ? ImportJobStatus.completedWithErrors
        : ImportJobStatus.completed;

    currentJob = currentJob.transitionTo(finalStatus, progress: 1.0);
    await jobRepository.save(currentJob);

    return currentJob;
  }
}
