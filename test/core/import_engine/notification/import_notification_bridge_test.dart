import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';
import 'package:stock_count/core/notifications/app_notification.dart';
import 'package:stock_count/core/notifications/notification_service.dart';
import 'package:stock_count/core/notifications/notification_type.dart';

/// Test implementation of NexaBiz NotificationService capturing emitted notifications.
class TestNotificationService extends NotificationService {
  final List<AppNotification> emitted = [];

  @override
  Future<AppNotification> show({
    required NotificationType type,
    required String title,
    String? message,
    NotificationCategory category = NotificationCategory.general,
    Duration? duration,
    bool isPersistent = false,
    bool persistToHistory = true,
    String? actionLabel,
    String? actionRoute,
  }) async {
    final notification = AppNotification(
      id: 'NOTIF-${emitted.length + 1}',
      type: type,
      category: category,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      isPersistent: isPersistent,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );
    emitted.add(notification);
    return notification;
  }

  @override
  void dismiss(String id) {}

  @override
  void dismissAll() {}

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> clearHistory() async {
    emitted.clear();
  }
}

void main() {
  group('Phase 16 — Universal Import Engine Import Notification System Tests', () {
    late TestNotificationService notificationService;
    late ImportNotificationBridge bridge;

    setUp(() {
      notificationService = TestNotificationService();
      bridge = ImportNotificationBridge(
        notificationService: notificationService,
      );
    });

    ImportJob createTestJob({
      required String jobId,
      ImportJobStatus status = ImportJobStatus.queued,
      int totalRows = 100,
      int processedRows = 0,
      int successfulRows = 0,
      int failedRows = 0,
      int skippedRows = 0,
      double progress = 0.0,
      List<String> errorSummary = const [],
    }) {
      return ImportJob(
        jobId: jobId,
        companyId: 'COMP-ALPHA',
        userId: 'USER-101',
        source: 'products_catalogue.csv',
        profile: ImportProfile(
          profileId: 'PROF-PROD',
          label: 'Products Catalogue Profile',
          entityType: 'Product',
          fields: const [],
        ),
        status: status,
        totalRows: totalRows,
        processedRows: processedRows,
        successfulRows: successfulRows,
        failedRows: failedRows,
        skippedRows: skippedRows,
        progress: progress,
        errorSummary: errorSummary,
      );
    }

    test(
      '1. notifyQueued emits info notification with Job ID, profile name, and status QUEUED',
      () async {
        final job = createTestJob(
          jobId: 'JOB-Q1',
          status: ImportJobStatus.queued,
        );
        final notif = await bridge.notifyQueued(job);

        expect(notif.type, equals(NotificationType.info));
        expect(notif.title, contains('Products Catalogue Profile'));
        expect(notif.message, contains('JOB-Q1'));
        expect(notif.message, contains('QUEUED'));
        expect(notif.message, contains('Total rows: 100'));
      },
    );

    test(
      '2. notifyStarted emits info notification with Job ID, profile name, and status PROCESSING',
      () async {
        final job = createTestJob(
          jobId: 'JOB-S1',
          status: ImportJobStatus.processing,
          totalRows: 500,
        );
        final notif = await bridge.notifyStarted(job);

        expect(notif.type, equals(NotificationType.info));
        expect(notif.title, contains('Import Started'));
        expect(notif.message, contains('JOB-S1'));
        expect(notif.message, contains('PROCESSING'));
        expect(notif.message, contains('500 records'));
      },
    );

    test(
      '3. notifyProgressMilestone emits progress notification with ratio and row counts',
      () async {
        final job = createTestJob(
          jobId: 'JOB-P1',
          status: ImportJobStatus.processing,
          totalRows: 100,
          processedRows: 50,
          progress: 0.50,
        );
        final notif = await bridge.notifyProgressMilestone(job, 0.50);

        expect(notif.type, equals(NotificationType.info));
        expect(notif.title, contains('50%'));
        expect(notif.message, contains('JOB-P1'));
        expect(notif.message, contains('50/100 rows'));
      },
    );

    test(
      '4. notifyCompleted emits success notification with success metrics',
      () async {
        final job = createTestJob(
          jobId: 'JOB-C1',
          status: ImportJobStatus.completed,
          totalRows: 100,
          processedRows: 100,
          successfulRows: 95,
          skippedRows: 5,
        );
        final notif = await bridge.notifyCompleted(job);

        expect(notif.type, equals(NotificationType.success));
        expect(notif.title, contains('Import Completed'));
        expect(notif.message, contains('JOB-C1'));
        expect(notif.message, contains('COMPLETED'));
        expect(notif.message, contains('95 created/updated'));
        expect(notif.message, contains('5 skipped'));
      },
    );

    test(
      '5. notifyCompletedWithErrors emits warning notification with error counts',
      () async {
        final job = createTestJob(
          jobId: 'JOB-CE1',
          status: ImportJobStatus.completedWithErrors,
          totalRows: 100,
          processedRows: 100,
          successfulRows: 90,
          failedRows: 10,
        );
        final notif = await bridge.notifyCompletedWithErrors(job);

        expect(notif.type, equals(NotificationType.warning));
        expect(notif.title, contains('Completed with Errors'));
        expect(notif.message, contains('JOB-CE1'));
        expect(notif.message, contains('COMPLETED_WITH_ERRORS'));
        expect(notif.message, contains('90 succeeded, 10 failed'));
      },
    );

    test(
      '6. notifyFailed emits error notification with error message summary',
      () async {
        final job = createTestJob(
          jobId: 'JOB-F1',
          status: ImportJobStatus.failed,
          errorSummary: ['Database lock timeout'],
        );
        final notif = await bridge.notifyFailed(job);

        expect(notif.type, equals(NotificationType.error));
        expect(notif.title, contains('Import Failed'));
        expect(notif.message, contains('JOB-F1'));
        expect(notif.message, contains('FAILED'));
        expect(notif.message, contains('Database lock timeout'));
      },
    );

    test(
      '7. notifyCancelled emits warning notification with stopped row count',
      () async {
        final job = createTestJob(
          jobId: 'JOB-CAN1',
          status: ImportJobStatus.cancelled,
          totalRows: 100,
          processedRows: 42,
        );
        final notif = await bridge.notifyCancelled(job);

        expect(notif.type, equals(NotificationType.warning));
        expect(notif.title, contains('Import Cancelled'));
        expect(notif.message, contains('JOB-CAN1'));
        expect(notif.message, contains('CANCELLED'));
        expect(notif.message, contains('Stopped at 42/100 rows'));
      },
    );

    test(
      '8. notifyForJobStatus automatically evaluates status changes and emits milestone notifications',
      () async {
        final queuedJob = createTestJob(
          jobId: 'JOB-AUTO1',
          status: ImportJobStatus.queued,
        );
        await bridge.notifyForJobStatus(queuedJob);
        expect(notificationService.emitted.length, equals(1));
        expect(notificationService.emitted.last.message, contains('QUEUED'));

        final startedJob = createTestJob(
          jobId: 'JOB-AUTO1',
          status: ImportJobStatus.processing,
          progress: 0.0,
        );
        await bridge.notifyForJobStatus(startedJob);
        expect(notificationService.emitted.length, equals(2));
        expect(
          notificationService.emitted.last.message,
          contains('PROCESSING'),
        );

        final milestoneJob = createTestJob(
          jobId: 'JOB-AUTO1',
          status: ImportJobStatus.processing,
          totalRows: 100,
          processedRows: 30,
          progress: 0.30,
        );
        await bridge.notifyForJobStatus(milestoneJob, previousProgress: 0.10);
        expect(notificationService.emitted.length, equals(3));
        expect(notificationService.emitted.last.title, contains('25%'));

        final completedJob = createTestJob(
          jobId: 'JOB-AUTO1',
          status: ImportJobStatus.completed,
          successfulRows: 100,
        );
        await bridge.notifyForJobStatus(completedJob);
        expect(notificationService.emitted.length, equals(4));
        expect(notificationService.emitted.last.message, contains('COMPLETED'));
      },
    );
  });
}
