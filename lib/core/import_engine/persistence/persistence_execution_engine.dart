import 'dart:math';

import '../checkpoint/import_checkpoint_repository.dart';
import '../domain/entities/import_job.dart';
import '../domain/entities/parsed_row.dart';
import '../domain/ports/import_job_repository.dart';
import '../pipeline/chunked_execution_engine.dart';
import 'import_persistence_handler.dart';
import 'import_persistence_mode.dart';
import 'import_transaction_runner.dart';

/// Orchestrates domain entity persistence across configured [ImportPersistenceMode] transaction boundaries.
class PersistenceExecutionEngine {
  PersistenceExecutionEngine({
    required this.transactionRunner,
    required this.jobRepository,
    required this.checkpointRepository,
    this.defaultChunkSize = 500,
  }) : chunkedEngine = ChunkedExecutionEngine(
         jobRepository: jobRepository,
         checkpointRepository: checkpointRepository,
         defaultChunkSize: defaultChunkSize,
       );

  final ImportTransactionRunner transactionRunner;
  final ImportJobRepository jobRepository;
  final ImportCheckpointRepository checkpointRepository;
  final ChunkedExecutionEngine chunkedEngine;
  final int defaultChunkSize;

  /// Executes domain persistence over [rows] using [persistenceHandler] and [persistenceMode].
  Future<ImportJob> executeWithPersistence<T>({
    required ImportJob job,
    required List<ParsedRow> rows,
    required ImportPersistenceMode persistenceMode,
    required ImportPersistenceHandler<T> persistenceHandler,
    required Future<T?> Function(ParsedRow row, int index) rowTransformer,
    String Function(ParsedRow row, int index)? idempotencyKeyExtractor,
    int? chunkSize,
    bool Function(int index)? shouldSimulateFailureAtRow,
  }) async {
    final companyId = job.companyId;

    switch (persistenceMode) {
      case ImportPersistenceMode.allOrNothing:
        // Transaction covers the ENTIRE job execution
        return await transactionRunner.runInTransaction(() async {
          return await chunkedEngine.executeChunked(
            job: job,
            rows: rows,
            chunkSize: chunkSize,
            idempotencyKeyExtractor: idempotencyKeyExtractor,
            shouldSimulateFailureAtRow: shouldSimulateFailureAtRow,
            rowProcessor: (row, index) async {
              final entity = await rowTransformer(row, index);
              if (entity == null) {
                return ChunkRowOutcome(
                  rowIndex: index,
                  rowKey:
                      idempotencyKeyExtractor?.call(row, index) ?? 'row_$index',
                  isSuccess: false,
                  isSkipped: true,
                );
              }
              await persistenceHandler.persistRow(entity, companyId: companyId);
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey:
                    idempotencyKeyExtractor?.call(row, index) ?? 'row_$index',
                isSuccess: true,
              );
            },
          );
        });

      case ImportPersistenceMode.perChunk:
        // Each chunk transaction is atomic. If any row in chunk fails, entire chunk rolls back.
        final activeChunkSize = chunkSize ?? defaultChunkSize;
        final failedChunkIndices = <int>{};
        final pendingChunkOutcomes = <int, ChunkRowOutcome>{};

        return await chunkedEngine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: activeChunkSize,
          idempotencyKeyExtractor: idempotencyKeyExtractor,
          rowProcessor: (row, index) async {
            final key =
                idempotencyKeyExtractor?.call(row, index) ?? 'row_$index';
            final chunkIndex = index ~/ activeChunkSize;

            if (failedChunkIndices.contains(chunkIndex)) {
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: false,
                errorMessage: 'Chunk $chunkIndex rolled back due to error',
              );
            }

            if (!pendingChunkOutcomes.containsKey(index)) {
              final latestCp = await checkpointRepository.getLatestCheckpoint(
                job.jobId,
                companyId: companyId,
              );
              final committedKeys = latestCp?.committedKeys ?? <String>{};

              // Execute the entire chunk transaction block starting at chunk boundary
              final chunkStart = chunkIndex * activeChunkSize;
              final chunkEnd = min(
                (chunkIndex + 1) * activeChunkSize,
                rows.length,
              );

              try {
                await transactionRunner.runInTransaction(() async {
                  for (var i = chunkStart; i < chunkEnd; i++) {
                    final cRow = rows[i];
                    final cKey =
                        idempotencyKeyExtractor?.call(cRow, i) ?? 'row_$i';

                    if (committedKeys.contains(cKey)) {
                      pendingChunkOutcomes[i] = ChunkRowOutcome(
                        rowIndex: i,
                        rowKey: cKey,
                        isSuccess: false,
                        isSkipped: true,
                      );
                      continue;
                    }

                    if (shouldSimulateFailureAtRow != null &&
                        shouldSimulateFailureAtRow(i)) {
                      throw Exception('Simulated chunk failure at row $i');
                    }

                    final entity = await rowTransformer(cRow, i);
                    if (entity != null) {
                      await persistenceHandler.persistRow(
                        entity,
                        companyId: companyId,
                      );
                      pendingChunkOutcomes[i] = ChunkRowOutcome(
                        rowIndex: i,
                        rowKey: cKey,
                        isSuccess: true,
                      );
                    } else {
                      pendingChunkOutcomes[i] = ChunkRowOutcome(
                        rowIndex: i,
                        rowKey: cKey,
                        isSuccess: false,
                        isSkipped: true,
                      );
                    }
                  }
                });
              } catch (e) {
                // Entire chunk failed and rolled back
                failedChunkIndices.add(chunkIndex);
                for (var i = chunkStart; i < chunkEnd; i++) {
                  final cKey =
                      idempotencyKeyExtractor?.call(rows[i], i) ?? 'row_$i';
                  pendingChunkOutcomes[i] = ChunkRowOutcome(
                    rowIndex: i,
                    rowKey: cKey,
                    isSuccess: false,
                    errorMessage: e.toString(),
                  );
                }
              }
            }

            return pendingChunkOutcomes[index] ??
                ChunkRowOutcome(
                  rowIndex: index,
                  rowKey: key,
                  isSuccess: false,
                  errorMessage: 'Chunk error',
                );
          },
        );

      case ImportPersistenceMode.perRow:
        // Each row is wrapped in an isolated transaction
        return await chunkedEngine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: chunkSize,
          idempotencyKeyExtractor: idempotencyKeyExtractor,
          rowProcessor: (row, index) async {
            final key =
                idempotencyKeyExtractor?.call(row, index) ?? 'row_$index';

            if (shouldSimulateFailureAtRow != null &&
                shouldSimulateFailureAtRow(index)) {
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: false,
                errorMessage: 'Simulated row failure at $index',
              );
            }

            try {
              final entity = await transactionRunner.runInTransaction(() async {
                final transformed = await rowTransformer(row, index);
                if (transformed != null) {
                  await persistenceHandler.persistRow(
                    transformed,
                    companyId: companyId,
                  );
                }
                return transformed;
              });

              if (entity == null) {
                return ChunkRowOutcome(
                  rowIndex: index,
                  rowKey: key,
                  isSuccess: false,
                  isSkipped: true,
                );
              }

              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: true,
              );
            } catch (e) {
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: false,
                errorMessage: e.toString(),
              );
            }
          },
        );

      case ImportPersistenceMode.bestEffort:
        // Best effort safely commits valid rows, logging failures without stopping
        return await chunkedEngine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: chunkSize,
          idempotencyKeyExtractor: idempotencyKeyExtractor,
          rowProcessor: (row, index) async {
            final key =
                idempotencyKeyExtractor?.call(row, index) ?? 'row_$index';

            if (shouldSimulateFailureAtRow != null &&
                shouldSimulateFailureAtRow(index)) {
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: false,
                errorMessage: 'Best-effort skipped failing row $index',
              );
            }

            try {
              final entity = await rowTransformer(row, index);
              if (entity == null) {
                return ChunkRowOutcome(
                  rowIndex: index,
                  rowKey: key,
                  isSuccess: false,
                  isSkipped: true,
                );
              }
              await persistenceHandler.persistRow(entity, companyId: companyId);
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: true,
              );
            } catch (e) {
              return ChunkRowOutcome(
                rowIndex: index,
                rowKey: key,
                isSuccess: false,
                errorMessage: e.toString(),
              );
            }
          },
        );
    }
  }
}
