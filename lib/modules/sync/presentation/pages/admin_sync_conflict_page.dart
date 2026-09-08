import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin surface for reviewing and resolving offline-sync conflict records.
class AdminSyncConflictPage extends ConsumerWidget {
  const AdminSyncConflictPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة تعارضات المزامنة (Sync Conflicts)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تظهر هذه الصفحة العمليات التي حدث فيها تعارض بين النسخة المحلية والسيرفر للتصحيح اليدوي.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.sync_problem, color: Colors.orange),
                      title: Text('تعارض فاتورة مبيعات #INV-2026-004'),
                      subtitle: Text('النسخة المحلية: v2 | نسخة السيرفر: v3'),
                      trailing: Chip(
                        label: Text('معلّق'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
