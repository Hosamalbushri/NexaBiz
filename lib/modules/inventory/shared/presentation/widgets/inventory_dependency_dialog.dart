import 'package:flutter/material.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';

class InventoryDependencyDialog extends StatelessWidget {
  const InventoryDependencyDialog({
    super.key,
    required this.dependentDocuments,
    required this.targetDocument,
  });

  final List<InventoryDocumentRef> dependentDocuments;
  final InventoryDocumentRef targetDocument;

  static Future<void> show(
    BuildContext context, {
    required List<InventoryDocumentRef> dependentDocuments,
    required InventoryDocumentRef targetDocument,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InventoryDependencyDialog(
        dependentDocuments: dependentDocuments,
        targetDocument: targetDocument,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 28),
          const SizedBox(width: 8),
          const Text('تعذر إلغاء الترحيل'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لا يمكن إلغاء ترحيل الحركة (${targetDocument.documentNumber}) بسبب وجود حركات لاحقة مرحّلة تعتمد على رصيد المخزون الخاص بها.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'يجب إلغاء ترحيل الحركات التالية أولاً بالترتيب:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dependentDocuments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = dependentDocuments[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        '${doc.documentType.displayName}: ${doc.documentNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'التاريخ: ${doc.documentDate.toString().substring(0, 10)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'مرحّل',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('حسناً، فهمت'),
        ),
      ],
    );
  }
}
