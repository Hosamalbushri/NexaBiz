import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import '../../import_engine.dart';

/// Reusable Import Jobs overview screen displaying active and past import jobs.
class ImportJobsListPage extends ConsumerWidget {
  const ImportJobsListPage({super.key, required this.companyId, this.onJobTap});

  final String companyId;
  final void Function(ImportJob job)? onJobTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(importJobRepositoryProvider);
    final worker = ref.watch(importBackgroundWorkerProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<ImportJob>>(
      future: repo.getJobsForCompany(companyId),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final jobs = snapshot.data;
        return AppListPage<ImportJob>(
          title: 'Import Jobs',
          headerActions: [
            AppIconButton(
              icon: Icons.refresh,
              onPressed: () {
                ref.invalidate(importJobRepositoryProvider);
              },
            ),
          ],
          isLoading: isLoading && (jobs == null),
          errorText: snapshot.error?.toString(),
          onRetry: () => ref.invalidate(importJobRepositoryProvider),
          emptyTitle: 'No import jobs found.',
          items: jobs ?? const [],
          contentBuilder: (context, itemList) {
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: itemList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12.0),
              itemBuilder: (context, idx) {
                return _buildJobCard(context, itemList[idx], worker, theme);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    ImportJob job,
    ImportBackgroundWorker worker,
    ThemeData theme,
  ) {
    final statusColor = _getStatusColor(job.status);
    final profileId = job.profile?.profileId ?? 'generic';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.jobId,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    job.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text('Profile: $profileId | Source: ${job.source}'),
            const SizedBox(height: 8.0),
            LinearProgressIndicator(
              value: job.progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: statusColor,
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rows: ${job.processedRows} / ${job.totalRows} (${(job.progress * 100).toStringAsFixed(1)}%)',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Success: ${job.successfulRows} | Failed: ${job.failedRows}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (job.status == ImportJobStatus.processing)
                    AppButton(
                      key: Key('job_pause_btn_${job.jobId}'),
                      icon: Icons.pause,
                      label: 'Pause',
                      variant: AppButtonVariant.text,
                      onPressed: () async =>
                          worker.pause(job.jobId, companyId: job.companyId),
                    ),
                  if (job.status == ImportJobStatus.paused)
                    AppButton(
                      key: Key('job_resume_btn_${job.jobId}'),
                      icon: Icons.play_arrow,
                      label: 'Resume',
                      variant: AppButtonVariant.text,
                      onPressed: () async =>
                          worker.resume(job.jobId, companyId: job.companyId),
                    ),
                  if (job.status == ImportJobStatus.processing ||
                      job.status == ImportJobStatus.queued)
                    AppButton(
                      key: Key('job_cancel_btn_${job.jobId}'),
                      icon: Icons.cancel_outlined,
                      label: 'Cancel',
                      variant: AppButtonVariant.text,
                      onPressed: () async =>
                          worker.cancel(job.jobId, companyId: job.companyId),
                    ),
                  if (job.status == ImportJobStatus.failed)
                    AppButton(
                      key: Key('job_retry_btn_${job.jobId}'),
                      icon: Icons.refresh,
                      label: 'Retry',
                      variant: AppButtonVariant.text,
                      onPressed: () async =>
                          worker.retry(job.jobId, companyId: job.companyId),
                    ),
                  AppButton(
                    key: Key('job_details_btn_${job.jobId}'),
                    icon: Icons.visibility_outlined,
                    label: 'Details',
                    variant: AppButtonVariant.text,
                    onPressed: () => onJobTap?.call(job),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ImportJobStatus status) {
    switch (status) {
      case ImportJobStatus.completed:
        return Colors.green;
      case ImportJobStatus.processing:
        return Colors.blue;
      case ImportJobStatus.completedWithErrors:
        return Colors.orange;
      case ImportJobStatus.failed:
        return Colors.red;
      case ImportJobStatus.cancelled:
        return Colors.grey;
      case ImportJobStatus.paused:
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }
}
