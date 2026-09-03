import 'package:flutter/material.dart';
import '../../import_engine.dart';

/// Reusable Import Job Details UI screen displaying full metrics, timing, and error summary.
class ImportJobDetailsPage extends StatelessWidget {
  const ImportJobDetailsPage({
    super.key,
    required this.job,
  });

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileId = job.profile?.profileId ?? 'generic';

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details: ${job.jobId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job ID: ${job.jobId}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Company: ${job.companyId} | User: ${job.userId}'),
                  Text('Profile: $profileId | Source: ${job.source}'),
                  const SizedBox(height: 12.0),
                  LinearProgressIndicator(value: job.progress),
                  const SizedBox(height: 8.0),
                  Text('Status: ${job.status.name.toUpperCase()}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metrics & Statistics', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildMetricRow('Total Rows', '${job.totalRows}'),
                  _buildMetricRow('Processed Rows', '${job.processedRows}'),
                  _buildMetricRow('Successful Rows', '${job.successfulRows}'),
                  _buildMetricRow('Created Rows', '${job.createdRows}'),
                  _buildMetricRow('Updated Rows', '${job.updatedRows}'),
                  _buildMetricRow('Skipped Rows', '${job.skippedRows}'),
                  _buildMetricRow('Failed Rows', '${job.failedRows}'),
                ],
              ),
            ),
          ),
          if (job.errorSummary.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Error Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    Text(job.errorSummary.join('\n')),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
