import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 10 — Universal Import Engine Import Job System Tests', () {
    late ImportJobRepository repo;

    setUp(() {
      repo = InMemoryImportJobRepository();
    });

    ImportJob createSampleJob({
      required String jobId,
      required String companyId,
      String userId = 'USR-001',
      ImportJobStatus status = ImportJobStatus.queued,
    }) {
      return ImportJob(
        jobId: jobId,
        companyId: companyId,
        userId: userId,
        source: 'products_import.csv',
        status: status,
        totalRows: 100,
      );
    }

    test('1. Lifecycle: Valid transitions update timestamps and metrics accurately', () async {
      var job = createSampleJob(jobId: 'JOB-101', companyId: 'COMP-A');
      expect(job.status, equals(ImportJobStatus.queued));
      expect(job.startedAt, isNull);
      expect(job.completedAt, isNull);

      // Transition to preparing
      job = job.transitionTo(ImportJobStatus.preparing);
      expect(job.status, equals(ImportJobStatus.preparing));
      expect(job.startedAt, isNotNull);

      // Transition to processing
      job = job.transitionTo(
        ImportJobStatus.processing,
        progress: 0.5,
        processedRows: 50,
        successfulRows: 48,
        failedRows: 2,
      );
      expect(job.status, equals(ImportJobStatus.processing));
      expect(job.progress, equals(0.5));
      expect(job.processedRows, equals(50));

      // Transition to paused
      job = job.transitionTo(ImportJobStatus.paused);
      expect(job.status, equals(ImportJobStatus.paused));

      // Resume processing
      job = job.transitionTo(ImportJobStatus.processing);
      expect(job.status, equals(ImportJobStatus.processing));

      // Transition to completed
      job = job.transitionTo(
        ImportJobStatus.completed,
        progress: 1.0,
        processedRows: 100,
        successfulRows: 98,
        failedRows: 2,
      );
      expect(job.status, equals(ImportJobStatus.completed));
      expect(job.completedAt, isNotNull);
      expect(job.status.isTerminal, isTrue);
    });

    test('2. Invalid Transitions: Rejects invalid transitions with exception', () {
      final completedJob = createSampleJob(
        jobId: 'JOB-102',
        companyId: 'COMP-A',
        status: ImportJobStatus.completed,
      );

      // Terminal state transition rejection
      expect(
        () => completedJob.transitionTo(ImportJobStatus.queued),
        throwsA(isA<ImportStatusTransitionException>()),
      );

      final queuedJob = createSampleJob(
        jobId: 'JOB-103',
        companyId: 'COMP-A',
        status: ImportJobStatus.queued,
      );

      // Direct queued -> completed illegal jump rejection
      expect(
        () => queuedJob.transitionTo(ImportJobStatus.completed),
        throwsA(isA<ImportStatusTransitionException>()),
      );
    });

    test('3. Persistence: Repository CRUD operations work reliably', () async {
      final job = createSampleJob(jobId: 'JOB-201', companyId: 'COMP-A');

      await repo.save(job);

      final fetched = await repo.getById('JOB-201', companyId: 'COMP-A');
      expect(fetched, isNotNull);
      expect(fetched?.jobId, equals('JOB-201'));
      expect(fetched?.totalRows, equals(100));

      await repo.delete('JOB-201', companyId: 'COMP-A');
      final afterDelete = await repo.getById('JOB-201', companyId: 'COMP-A');
      expect(afterDelete, isNull);
    });

    test('4. Restart/Reload: Job state persists across UI navigation simulation', () async {
      // Simulate UI page 1 creating and updating job
      var job = createSampleJob(jobId: 'JOB-301', companyId: 'COMP-A');
      job = job.transitionTo(ImportJobStatus.preparing);
      job = job.transitionTo(
        ImportJobStatus.processing,
        progress: 0.35,
        processedRows: 35,
      );
      await repo.save(job);

      // Simulate UI user navigating away and navigating back (fresh query to repo)
      final reloadedJob = await repo.getById('JOB-301', companyId: 'COMP-A');

      expect(reloadedJob, isNotNull);
      expect(reloadedJob?.status, equals(ImportJobStatus.processing));
      expect(reloadedJob?.progress, equals(0.35));
      expect(reloadedJob?.processedRows, equals(35));
    });

    test('5. Company Isolation: Strictly isolates jobs between companies', () async {
      final jobCompA = createSampleJob(jobId: 'JOB-A1', companyId: 'COMPANY-ALPHA');
      final jobCompB = createSampleJob(jobId: 'JOB-B1', companyId: 'COMPANY-BETA');

      await repo.save(jobCompA);
      await repo.save(jobCompB);

      // Company Alpha attempt to access Company Beta job via getById
      final unauthorizedFetch = await repo.getById('JOB-B1', companyId: 'COMPANY-ALPHA');
      expect(unauthorizedFetch, isNull);

      // Company Alpha list jobs
      final jobsAlpha = await repo.getJobsForCompany('COMPANY-ALPHA');
      expect(jobsAlpha.length, equals(1));
      expect(jobsAlpha.first.jobId, equals('JOB-A1'));

      // Company Beta list jobs
      final jobsBeta = await repo.getJobsForCompany('COMPANY-BETA');
      expect(jobsBeta.length, equals(1));
      expect(jobsBeta.first.jobId, equals('JOB-B1'));

      // Enforce companyId non-empty guard
      expect(
        () => ImportJob(
          jobId: 'INVALID',
          companyId: '   ',
          userId: 'USR',
          source: 'src',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
