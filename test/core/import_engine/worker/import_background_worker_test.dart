import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 11 — Universal Import Engine Background Execution Tests', () {
    late ImportJobRepository repo;
    late ImportBackgroundWorker worker;

    setUp(() {
      repo = InMemoryImportJobRepository();
      worker = ImportBackgroundWorker(repository: repo);
    });

    tearDown(() {
      worker.dispose();
    });

    ImportJob createSampleJob({
      required String jobId,
      required String companyId,
      int totalRows = 20,
    }) {
      return ImportJob(
        jobId: jobId,
        companyId: companyId,
        userId: 'USER-101',
        source: 'sales_records.csv',
        totalRows: totalRows,
      );
    }

    test('1. Queueing: Job is saved with QUEUED status and enqueued', () async {
      final job = createSampleJob(jobId: 'JOB-Q1', companyId: 'COMP-1');

      await worker.enqueue(
        job,
        customExecutor: (j, report, isAborted) async {
          // No-op executor for queue test
        },
      );

      final fetched = await repo.getById('JOB-Q1', companyId: 'COMP-1');
      expect(fetched, isNotNull);
      expect(fetched?.status, equals(ImportJobStatus.queued));
    });

    test(
      '2. Execution & Progress Persistence: Worker runs independently and persists metrics',
      () async {
        final job = createSampleJob(
          jobId: 'JOB-EX1',
          companyId: 'COMP-1',
          totalRows: 10,
        );

        await worker.enqueue(
          job,
          customExecutor: (j, report, isAborted) async {
            for (var i = 1; i <= 10; i++) {
              if (isAborted()) break;
              await report(
                processedRows: i,
                successfulRows: i,
                failedRows: 0,
                skippedRows: 0,
                progress: i / 10.0,
              );
            }
          },
        );

        // Wait brief moment for background async loop completion
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final completedJob = await repo.getById('JOB-EX1', companyId: 'COMP-1');
        expect(completedJob, isNotNull);
        expect(completedJob?.status, equals(ImportJobStatus.completed));
        expect(completedJob?.processedRows, equals(10));
        expect(completedJob?.successfulRows, equals(10));
        expect(completedJob?.progress, equals(1.0));
        expect(completedJob?.completedAt, isNotNull);
      },
    );

    test(
      '3. Cancellation: Aborts processing and updates status to CANCELLED',
      () async {
        final job = createSampleJob(
          jobId: 'JOB-CAN1',
          companyId: 'COMP-1',
          totalRows: 100,
        );

        await worker.enqueue(
          job,
          customExecutor: (j, report, isAborted) async {
            for (var i = 1; i <= 100; i++) {
              if (isAborted()) break;
              await Future<void>.delayed(const Duration(milliseconds: 10));
              await report(
                processedRows: i,
                successfulRows: i,
                failedRows: 0,
                skippedRows: 0,
                progress: i / 100.0,
              );
            }
          },
        );

        // Give worker a moment to start, then cancel
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await worker.cancel('JOB-CAN1', companyId: 'COMP-1');

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final cancelledJob = await repo.getById(
          'JOB-CAN1',
          companyId: 'COMP-1',
        );
        expect(cancelledJob, isNotNull);
        expect(cancelledJob?.status, equals(ImportJobStatus.cancelled));
        expect(cancelledJob?.processedRows, lessThan(100));
      },
    );

    test(
      '4. Pause, Resume & Restart: Worker supports pause and resume lifecycle',
      () async {
        final job = createSampleJob(
          jobId: 'JOB-PR1',
          companyId: 'COMP-1',
          totalRows: 50,
        );

        await worker.enqueue(
          job,
          customExecutor: (j, report, isAborted) async {
            for (var i = 1; i <= 50; i++) {
              if (isAborted()) break;
              await Future<void>.delayed(const Duration(milliseconds: 5));
              await report(
                processedRows: i,
                successfulRows: i,
                failedRows: 0,
                skippedRows: 0,
                progress: i / 50.0,
              );
            }
          },
        );

        await Future<void>.delayed(const Duration(milliseconds: 15));
        await worker.pause('JOB-PR1', companyId: 'COMP-1');

        final pausedJob = await repo.getById('JOB-PR1', companyId: 'COMP-1');
        expect(pausedJob?.status, equals(ImportJobStatus.paused));

        // Resume job
        await worker.resume(
          'JOB-PR1',
          companyId: 'COMP-1',
          customExecutor: (j, report, isAborted) async {
            await report(
              processedRows: 50,
              successfulRows: 50,
              failedRows: 0,
              skippedRows: 0,
              progress: 1.0,
            );
          },
        );

        await Future<void>.delayed(const Duration(milliseconds: 30));

        final resumedJob = await repo.getById('JOB-PR1', companyId: 'COMP-1');
        expect(resumedJob?.status, equals(ImportJobStatus.completed));
        expect(resumedJob?.progress, equals(1.0));
      },
    );

    test(
      '5. UI Detachment & Reopen Simulation: Worker finishes without UI dependency',
      () async {
        final job = createSampleJob(
          jobId: 'JOB-DET1',
          companyId: 'COMP-1',
          totalRows: 5,
        );

        // UI enqueues job and immediately "disposes / navigates away"
        await worker.enqueue(job);

        // Simulate complete UI detachment and time passage
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Reopen UI and reconstruct state from repository
        final reconstructedJob = await repo.getById(
          'JOB-DET1',
          companyId: 'COMP-1',
        );

        expect(reconstructedJob, isNotNull);
        expect(reconstructedJob?.status, equals(ImportJobStatus.completed));
        expect(reconstructedJob?.processedRows, equals(5));
        expect(reconstructedJob?.progress, equals(1.0));
      },
    );
  });
}
