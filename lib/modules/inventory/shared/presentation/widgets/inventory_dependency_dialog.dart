import 'package:flutter/material.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

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
    return AppDialog.show<void>(
      context: context,
      title: 'تعذر إلغاء الترحيل',
      description: 'لا يمكن إلغاء ترحيل الحركة (${targetDocument.documentNumber}) بسبب وجود حركات لاحقة مرحّلة تعتمد عليها.',
      icon: Icons.warning_amber_rounded,
      isDestructive: true,
      size: AppDialogSize.medium,
      confirmLabel: 'حسناً، فهمت',
      showCloseButton: true,
      child: InventoryDependencyDialog(
        dependentDocuments: dependentDocuments,
        targetDocument: targetDocument,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'يجب إلغاء ترحيل الحركات التالية أولاً بالترتيب:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: dependentDocuments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = dependentDocuments[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red.withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${doc.documentType.displayName}: ${doc.documentNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'التاريخ: ${doc.documentDate.toString().substring(0, 10)}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
