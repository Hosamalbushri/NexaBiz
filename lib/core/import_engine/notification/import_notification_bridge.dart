import '../../notifications/app_notification.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/notification_type.dart';
import '../domain/entities/import_job.dart';
import '../domain/entities/import_job_status.dart';

/// Notification bridge linking the Universal Import Engine lifecycle to NexaBiz's canonical NotificationService.
class ImportNotificationBridge {
  const ImportNotificationBridge({required this.notificationService});

  /// The authoritative platform NotificationService instance.
  final NotificationService notificationService;

  /// Helper to extract entity or profile name from an import job.
  String getEntityOrProfileName(ImportJob job) {
    return job.profile?.label ?? job.profile?.entityType ?? job.source;
  }

  /// Emits notification when an import job is queued.
  Future<AppNotification> notifyQueued(ImportJob job) {
    final entityName = getEntityOrProfileName(job);
    return notificationService.showInfo(
      title: 'Import Queued: $entityName',
      message:
          'Job ID: ${job.jobId} | Status: QUEUED | Total rows: ${job.totalRows}',
      category: NotificationCategory.system,
    );
  }

  /// Emits notification when an import job starts processing.
  Future<AppNotification> notifyStarted(ImportJob job) {
    final entityName = getEntityOrProfileName(job);
    return notificationService.showInfo(
      title: 'Import Started: $entityName',
      message:
          'Job ID: ${job.jobId} | Status: PROCESSING | Processing ${job.totalRows} records',
      category: NotificationCategory.system,
    );
  }

  /// Emits notification when a progress milestone (e.g. 25%, 50%, 75%) is reached.
  Future<AppNotification> notifyProgressMilestone(
    ImportJob job,
    double milestoneRatio,
  ) {
    final entityName = getEntityOrProfileName(job);
    final percent = (milestoneRatio * 100).toInt();
    return notificationService.showInfo(
      title: 'Import Progress ($percent%): $entityName',
      message:
          'Job ID: ${job.jobId} | Status: PROCESSING | $percent% completed (${job.processedRows}/${job.totalRows} rows)',
      category: NotificationCategory.system,
    );
  }

  /// Emits notification when an import job completes successfully without errors.
  Future<AppNotification> notifyCompleted(ImportJob job) {
    final entityName = getEntityOrProfileName(job);
    return notificationService.showSuccess(
      title: 'Import Completed: $entityName',
      message:
          'Job ID: ${job.jobId} | Status: COMPLETED | ${job.successfulRows} created/updated, ${job.skippedRows} skipped',
      category: NotificationCategory.system,
    );
  }

  /// Emits notification when an import job completes with non-fatal errors.
  Future<AppNotification> notifyCompletedWithErrors(ImportJob job) {
    final entityName = getEntityOrProfileName(job);
    return notificationService.showWarning(
      title: 'Import Completed with Errors: $entityName',
      message:
          'Job ID: ${job.jobId} | Status: COMPLETED_WITH_ERRORS | ${job.successfulRows} succeeded, ${job.failedRows} failed',
      category: NotificationCategory.system,
    );
  }

  /// Emits notification when an import job fails.
  Future<AppNotification> notifyFailed(ImportJob job, [String? errorMessage]) {
    final entityName = getEntityOrProfileName(job);
    final errorDetail =
        errorMessage ??
        (job.errorSummary.isNotEmpty
            ? job.errorSummary.first
            : 'Unknown execution error');
    return notificationService.showError(
      title: 'Import Failed: $entityName',
      message: 'Job ID: ${job.jobId} | Status: FAILED | $errorDetail',
      category: NotificationCategory.system,
    );
  }

  /// Emits notification when an import job is cancelled.
  Future<AppNotification> notifyCancelled(ImportJob job) {
    final entityName = getEntityOrProfileName(job);
    return notificationService.showWarning(
      title: 'Import Cancelled: $entityName',
      message:
          'Job ID: ${job.jobId} | Status: CANCELLED | Stopped at ${job.processedRows}/${job.totalRows} rows',
      category: NotificationCategory.system,
    );
  }

  /// Automatically evaluates job state and emits corresponding notification.
  Future<AppNotification?> notifyForJobStatus(
    ImportJob job, {
    double? previousProgress,
  }) async {
    switch (job.status) {
      case ImportJobStatus.queued:
        return notifyQueued(job);
      case ImportJobStatus.preparing:
      case ImportJobStatus.processing:
        if (previousProgress == null && job.progress == 0.0) {
          return notifyStarted(job);
        }
        if (previousProgress != null) {
          final oldMilestone = (previousProgress * 4).floor();
          final newMilestone = (job.progress * 4).floor();
          if (newMilestone > oldMilestone && newMilestone < 4) {
            return notifyProgressMilestone(job, newMilestone * 0.25);
          }
        }
        return null;
      case ImportJobStatus.completed:
        return notifyCompleted(job);
      case ImportJobStatus.completedWithErrors:
        return notifyCompletedWithErrors(job);
      case ImportJobStatus.failed:
        return notifyFailed(job);
      case ImportJobStatus.cancelled:
        return notifyCancelled(job);
      case ImportJobStatus.paused:
        return null;
    }
  }
}
