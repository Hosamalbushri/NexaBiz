import 'dart:async';
import '../domain/entities/import_job.dart';
import '../domain/entities/import_job_status.dart';
import '../domain/ports/import_job_repository.dart';

/// Worker execution handler callback signature for processing job batches.
typedef ImportJobExecutor =
    Future<void> Function(
      ImportJob job,
      Future<void> Function({
        required int processedRows,
        required int successfulRows,
        required int failedRows,
        required int skippedRows,
        required double progress,
      })
      reportProgress,
      bool Function() isCancelledOrPaused,
    );

/// Decoupled Background Execution Worker for [ImportJob] instances.
/// Runs independently from UI widgets, periodically persisting progress to [ImportJobRepository].
class ImportBackgroundWorker {
  ImportBackgroundWorker({required this.repository});

  final ImportJobRepository repository;

  final Set<String> _pausedJobIds = {};
  final Set<String> _cancelledJobIds = {};
  final Map<String, Completer<void>> _activeJobCompleters = {};

  final StreamController<ImportJob> _updatesController =
      StreamController<ImportJob>.broadcast();

  /// Stream of real-time job update events for optional UI subscriptions.
  Stream<ImportJob> get jobUpdatesStream => _updatesController.stream;

  void _notifyUpdate(ImportJob job) {
    if (!_updatesController.isClosed) {
      _updatesController.add(job);
    }
  }

  /// Enqueues an [ImportJob] for background execution.
  Future<void> enqueue(
    ImportJob job, {
    ImportJobExecutor? customExecutor,
  }) async {
    _cancelledJobIds.remove(job.jobId);
    _pausedJobIds.remove(job.jobId);

    // Save job in repository with QUEUED status
    final queuedJob = job.status == ImportJobStatus.queued
        ? job
        : job.copyWith(status: ImportJobStatus.queued);

    await repository.save(queuedJob);
    _notifyUpdate(queuedJob);

    // Trigger background execution without awaiting (decoupled from caller)
    unawaited(_runBackgroundJob(queuedJob, customExecutor: customExecutor));
  }

  /// Internal worker process executing job steps.
  Future<void> _runBackgroundJob(
    ImportJob initialJob, {
    ImportJobExecutor? customExecutor,
  }) async {
    final jobId = initialJob.jobId;
    final companyId = initialJob.companyId;

    // Await any existing execution completer for clean sequence
    if (_activeJobCompleters.containsKey(jobId)) {
      final existingCompleter = _activeJobCompleters[jobId];
      if (existingCompleter != null && !existingCompleter.isCompleted) {
        await existingCompleter.future;
      }
    }

    final completer = Completer<void>();
    _activeJobCompleters[jobId] = completer;

    try {
      // 1. Transition to PREPARING if QUEUED
      var currentJob =
          await repository.getById(jobId, companyId: companyId) ?? initialJob;
      if (currentJob.status == ImportJobStatus.queued) {
        currentJob = currentJob.transitionTo(ImportJobStatus.preparing);
        await repository.save(currentJob);
        _notifyUpdate(currentJob);
      }

      if (_isAborted(jobId)) {
        await _handleAbortedState(jobId, companyId);
        return;
      }

      // 2. Transition to PROCESSING if PREPARING or PAUSED
      if (currentJob.status == ImportJobStatus.preparing ||
          currentJob.status == ImportJobStatus.paused) {
        currentJob = currentJob.transitionTo(ImportJobStatus.processing);
        await repository.save(currentJob);
        _notifyUpdate(currentJob);
      }

      // 3. Process Execution Loop
      if (customExecutor != null) {
        await customExecutor(currentJob, ({
          required processedRows,
          required successfulRows,
          required failedRows,
          required skippedRows,
          required progress,
        }) async {
          if (_isAborted(jobId)) return;

          final latest = await repository.getById(jobId, companyId: companyId);
          if (latest == null) return;

          final updated = latest.copyWith(
            processedRows: processedRows,
            successfulRows: successfulRows,
            failedRows: failedRows,
            skippedRows: skippedRows,
            progress: progress,
          );
          await repository.save(updated);
          _notifyUpdate(updated);
        }, () => _isAborted(jobId));
      } else {
        // Default simulated processing loop for standalone execution
        final total = currentJob.totalRows > 0 ? currentJob.totalRows : 10;
        for (var i = 1; i <= total; i++) {
          if (_isAborted(jobId)) break;

          await Future<void>.delayed(const Duration(milliseconds: 10));

          final latest = await repository.getById(jobId, companyId: companyId);
          if (latest == null || _isAborted(jobId)) break;

          final progress = i / total;
          final updated = latest.copyWith(
            processedRows: i,
            successfulRows: i,
            progress: progress,
          );
          await repository.save(updated);
          _notifyUpdate(updated);
        }
      }

      // 4. Finalize Status
      if (_isAborted(jobId)) {
        await _handleAbortedState(jobId, companyId);
      } else {
        final finalJob = await repository.getById(jobId, companyId: companyId);
        if (finalJob != null && finalJob.status == ImportJobStatus.processing) {
          final completedStatus = finalJob.failedRows > 0
              ? ImportJobStatus.completedWithErrors
              : ImportJobStatus.completed;
          final completed = finalJob.transitionTo(
            completedStatus,
            progress: 1.0,
          );
          await repository.save(completed);
          _notifyUpdate(completed);
        }
      }
    } catch (e) {
      final errorJob = await repository.getById(jobId, companyId: companyId);
      if (errorJob != null) {
        final failed = errorJob.transitionTo(
          ImportJobStatus.failed,
          errorSummary: [...errorJob.errorSummary, e.toString()],
        );
        await repository.save(failed);
        _notifyUpdate(failed);
      }
    } finally {
      if (_activeJobCompleters[jobId] == completer) {
        _activeJobCompleters.remove(jobId);
      }
      completer.complete();
    }
  }

  Future<void> _handleAbortedState(String jobId, String companyId) async {
    final finalJob = await repository.getById(jobId, companyId: companyId);
    if (finalJob == null) return;

    if (_cancelledJobIds.contains(jobId) &&
        finalJob.status.canTransitionTo(ImportJobStatus.cancelled)) {
      final cancelled = finalJob.transitionTo(ImportJobStatus.cancelled);
      await repository.save(cancelled);
      _notifyUpdate(cancelled);
    } else if (_pausedJobIds.contains(jobId) &&
        finalJob.status.canTransitionTo(ImportJobStatus.paused)) {
      final paused = finalJob.transitionTo(ImportJobStatus.paused);
      await repository.save(paused);
      _notifyUpdate(paused);
    }
  }

  /// Pauses processing for an active job.
  Future<void> pause(String jobId, {required String companyId}) async {
    _pausedJobIds.add(jobId);
    final job = await repository.getById(jobId, companyId: companyId);
    if (job != null && job.status.canTransitionTo(ImportJobStatus.paused)) {
      final paused = job.transitionTo(ImportJobStatus.paused);
      await repository.save(paused);
      _notifyUpdate(paused);
    }
  }

  /// Resumes processing for a paused job.
  Future<void> resume(
    String jobId, {
    required String companyId,
    ImportJobExecutor? customExecutor,
  }) async {
    _pausedJobIds.remove(jobId);
    final job = await repository.getById(jobId, companyId: companyId);
    if (job != null && job.status == ImportJobStatus.paused) {
      final resumed = job.transitionTo(ImportJobStatus.processing);
      await repository.save(resumed);
      _notifyUpdate(resumed);
      await _runBackgroundJob(resumed, customExecutor: customExecutor);
    }
  }

  /// Cancels processing for an active or queued job.
  Future<void> cancel(String jobId, {required String companyId}) async {
    _cancelledJobIds.add(jobId);
    final job = await repository.getById(jobId, companyId: companyId);
    if (job != null && job.status.canTransitionTo(ImportJobStatus.cancelled)) {
      final cancelled = job.transitionTo(ImportJobStatus.cancelled);
      await repository.save(cancelled);
      _notifyUpdate(cancelled);
    }
  }

  /// Resets a failed or cancelled job and re-enqueues for processing.
  Future<void> retry(
    String jobId, {
    required String companyId,
    ImportJobExecutor? customExecutor,
  }) async {
    final job = await repository.getById(jobId, companyId: companyId);
    if (job != null &&
        (job.status == ImportJobStatus.failed ||
            job.status == ImportJobStatus.cancelled)) {
      final resetJob = job.copyWith(
        status: ImportJobStatus.queued,
        processedRows: 0,
        successfulRows: 0,
        failedRows: 0,
        skippedRows: 0,
        createdRows: 0,
        updatedRows: 0,
        progress: 0.0,
        errorSummary: [],
      );
      await enqueue(resetJob, customExecutor: customExecutor);
    }
  }

  bool _isAborted(String jobId) {
    return _pausedJobIds.contains(jobId) || _cancelledJobIds.contains(jobId);
  }

  void dispose() {
    _updatesController.close();
  }
}
