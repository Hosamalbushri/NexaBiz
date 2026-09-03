import 'package:flutter/material.dart';
import '../../import_engine.dart';

/// Reusable Import Report UI screen displaying reproducible audit records and row error breakdown.
class ImportReportPage extends StatelessWidget {
  const ImportReportPage({
    super.key,
    required this.report,
  });

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audit = report.auditRecord;
    final errors = report.errorReports;

    return Scaffold(
      appBar: AppBar(
        title: Text('Import Report: ${audit.jobId}'),
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
                  Text('Audit Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Text('Job ID: ${audit.jobId} | Company: ${audit.companyId}'),
                  Text('Source: ${audit.source} | User: ${audit.userId}'),
                  Text('Started: ${audit.startedAt} | Completed: ${audit.completedAt}'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountBadge('Total', '${audit.totalRows}', Colors.blue),
                      _buildCountBadge('Created', '${audit.createdRows}', Colors.green),
                      _buildCountBadge('Updated', '${audit.updatedRows}', Colors.orange),
                      _buildCountBadge('Failed', '${audit.failedRows}', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text('Errors & Warnings Breakdown (${errors.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          if (errors.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No errors or warnings recorded for this import run.'),
              ),
            )
          else
            ...errors.map((err) {
              return Card(
                color: theme.colorScheme.errorContainer,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text('Row ${err.rowIndex}: ${err.fieldKey ?? "Row"} (${err.errorCode})'),
                  subtitle: Text(err.message),
                  trailing: Text(err.severity.toUpperCase()),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
