import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(importJobRepositoryProvider);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ImportJob>>(
        future: repo.getJobsForCompany(companyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'No import jobs found.',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: jobs.length,
            itemBuilder: (context, idx) {
              final job = jobs[idx];
              return _buildJobCard(context, job, worker, theme);
            },
          );
        },
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
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
                    TextButton.icon(
                      key: Key('job_pause_btn_${job.jobId}'),
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      onPressed: () async =>
                          worker.pause(job.jobId, companyId: job.companyId),
                    ),
                  if (job.status == ImportJobStatus.paused)
                    TextButton.icon(
                      key: Key('job_resume_btn_${job.jobId}'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                      onPressed: () async =>
                          worker.resume(job.jobId, companyId: job.companyId),
                    ),
                  if (job.status == ImportJobStatus.processing ||
                      job.status == ImportJobStatus.queued)
                    TextButton.icon(
                      key: Key('job_cancel_btn_${job.jobId}'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      onPressed: () async =>
                          worker.cancel(job.jobId, companyId: job.companyId),
                    ),
                  if (job.status == ImportJobStatus.failed)
                    TextButton.icon(
                      key: Key('job_retry_btn_${job.jobId}'),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () async =>
                          worker.retry(job.jobId, companyId: job.companyId),
                    ),
                  TextButton.icon(
                    key: Key('job_details_btn_${job.jobId}'),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Details'),
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
