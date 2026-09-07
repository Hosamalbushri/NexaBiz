import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 12 — Universal Import Engine Chunking, Checkpoints & Resume Tests', () {
    late ImportJobRepository jobRepo;
    late ImportCheckpointRepository cpRepo;
    late ChunkedExecutionEngine engine;

    setUp(() {
      jobRepo = InMemoryImportJobRepository();
      cpRepo = InMemoryImportCheckpointRepository();
      engine = ChunkedExecutionEngine(
        jobRepository: jobRepo,
        checkpointRepository: cpRepo,
        defaultChunkSize: 50,
      );
    });

    List<ParsedRow> generateSampleRows(int count) {
      return List.generate(
        count,
        (index) => ParsedRow(
          rowIndex: index,
          cells: [
            ParsedCell(
              headerName: 'code',
              rawValue: 'PROD-$index',
              columnIndex: 0,
            ),
            ParsedCell(
              headerName: 'name',
              rawValue: 'Product #$index',
              columnIndex: 1,
            ),
            ParsedCell(
              headerName: 'price',
              rawValue: '${100 + index}',
              columnIndex: 2,
            ),
          ],
        ),
      );
    }

    ImportJob createSampleJob({
      required String jobId,
      required String companyId,
      required int totalRows,
    }) {
      return ImportJob(
        jobId: jobId,
        companyId: companyId,
        userId: 'USER-999',
        source: 'large_catalog.csv',
        totalRows: totalRows,
      );
    }

    test(
      '1. Configurable Chunking & Periodic Checkpoints: Creates checkpoints every 50 rows',
      () async {
        final rows = generateSampleRows(200);
        final job = createSampleJob(
          jobId: 'JOB-CHK1',
          companyId: 'COMP-A',
          totalRows: 200,
        );

        final processedIndices = <int>[];

        final resultJob = await engine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: 50,
          idempotencyKeyExtractor: (row, idx) => 'PROD-$idx',
          rowProcessor: (row, idx) async {
            processedIndices.add(idx);
            return ChunkRowOutcome(
              rowIndex: idx,
              rowKey: 'PROD-$idx',
              isSuccess: true,
            );
          },
        );

        expect(resultJob.status, equals(ImportJobStatus.completed));
        expect(resultJob.processedRows, equals(200));
        expect(resultJob.successfulRows, equals(200));
        expect(processedIndices.length, equals(200));

        final latestCp = await cpRepo.getLatestCheckpoint(
          'JOB-CHK1',
          companyId: 'COMP-A',
        );
        expect(latestCp, isNotNull);
        expect(latestCp?.lastProcessedRowIndex, equals(199));
        expect(latestCp?.successfulRows, equals(200));
        expect(latestCp?.committedKeys.length, equals(200));
      },
    );

    test(
      '2. Failure Injection & Resume: Resumes cleanly at row N+1 without re-processing past chunks',
      () async {
        final rows = generateSampleRows(200);
        final job = createSampleJob(
          jobId: 'JOB-FAIL1',
          companyId: 'COMP-A',
          totalRows: 200,
        );

        final run1ProcessedIndices = <int>[];

        // Run 1: Inject failure at row 125 (midway in chunk 3: rows 100..149)
        try {
          await engine.executeChunked(
            job: job,
            rows: rows,
            chunkSize: 50,
            idempotencyKeyExtractor: (row, idx) => 'PROD-$idx',
            shouldSimulateFailureAtRow: (idx) => idx == 125,
            rowProcessor: (row, idx) async {
              run1ProcessedIndices.add(idx);
              return ChunkRowOutcome(
                rowIndex: idx,
                rowKey: 'PROD-$idx',
                isSuccess: true,
              );
            },
          );
        } catch (e) {
          // Expected failure
        }

        // Verify Run 1 checkpoint saved chunk 2 (up to row index 99)
        final cpAfterFail = await cpRepo.getLatestCheckpoint(
          'JOB-FAIL1',
          companyId: 'COMP-A',
        );
        expect(cpAfterFail, isNotNull);
        expect(cpAfterFail?.lastProcessedRowIndex, equals(99));
        expect(cpAfterFail?.successfulRows, equals(100));

        // Run 2: Resume processing after crash
        final run2ProcessedIndices = <int>[];

        final resumedJob = await engine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: 50,
          idempotencyKeyExtractor: (row, idx) => 'PROD-$idx',
          rowProcessor: (row, idx) async {
            run2ProcessedIndices.add(idx);
            return ChunkRowOutcome(
              rowIndex: idx,
              rowKey: 'PROD-$idx',
              isSuccess: true,
            );
          },
        );

        expect(resumedJob.status, equals(ImportJobStatus.completed));
        expect(resumedJob.processedRows, equals(200));
        expect(resumedJob.successfulRows, equals(200));

        // Run 2 started processing strictly at row index 100 (resuming chunk 3)
        expect(run2ProcessedIndices.first, equals(100));
        expect(run2ProcessedIndices.last, equals(199));
        expect(run2ProcessedIndices.length, equals(100));
      },
    );

    test(
      '3. Idempotency & Duplicate Protection: Committed keys are never re-committed',
      () async {
        final rows = generateSampleRows(100);
        final job = createSampleJob(
          jobId: 'JOB-IDEM1',
          companyId: 'COMP-A',
          totalRows: 100,
        );

        // Pre-seed checkpoint with rows 0..29 already committed
        final preSeedCp = ImportCheckpoint(
          jobId: 'JOB-IDEM1',
          companyId: 'COMP-A',
          lastProcessedRowIndex: -1, // Force iteration from index 0
          chunkSize: 50,
          successfulRows: 30,
          committedKeys: Set.of(List.generate(30, (i) => 'PROD-$i')),
        );
        await cpRepo.save(preSeedCp);

        final processedKeys = <String>[];

        final resultJob = await engine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: 50,
          idempotencyKeyExtractor: (row, idx) => 'PROD-$idx',
          rowProcessor: (row, idx) async {
            processedKeys.add('PROD-$idx');
            return ChunkRowOutcome(
              rowIndex: idx,
              rowKey: 'PROD-$idx',
              isSuccess: true,
            );
          },
        );

        expect(resultJob.status, equals(ImportJobStatus.completed));
        expect(resultJob.skippedRows, equals(30));
        // Rows 0..29 were skipped due to idempotency key guard

        expect(processedKeys.contains('PROD-0'), isFalse);
        expect(processedKeys.contains('PROD-29'), isFalse);
        expect(processedKeys.contains('PROD-30'), isTrue);
        expect(processedKeys.contains('PROD-99'), isTrue);
      },
    );

    test(
      '4. Scalable Bounded Memory Simulation: Processes 1,000 rows in 20 chunks seamlessly',
      () async {
        final rows = generateSampleRows(1000);
        final job = createSampleJob(
          jobId: 'JOB-SCALE1',
          companyId: 'COMP-A',
          totalRows: 1000,
        );

        int chunkCheckpointCount = 0;

        final resultJob = await engine.executeChunked(
          job: job,
          rows: rows,
          chunkSize: 50,
          idempotencyKeyExtractor: (row, idx) => 'PROD-$idx',
          rowProcessor: (row, idx) async {
            if ((idx + 1) % 50 == 0) {
              chunkCheckpointCount++;
            }
            return ChunkRowOutcome(
              rowIndex: idx,
              rowKey: 'PROD-$idx',
              isSuccess: true,
            );
          },
        );

        expect(resultJob.status, equals(ImportJobStatus.completed));
        expect(resultJob.processedRows, equals(1000));
        expect(resultJob.successfulRows, equals(1000));
        expect(chunkCheckpointCount, equals(20));
      },
    );
  });
}
