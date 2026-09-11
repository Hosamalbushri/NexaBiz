import 'package:flutter/material.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

class InventoryShortageDialog extends StatelessWidget {
  const InventoryShortageDialog({super.key, required this.shortages});

  final List<StockShortageItem> shortages;

  static Future<void> show(
    BuildContext context, {
    required List<StockShortageItem> shortages,
  }) {
    return AppDialog.show<void>(
      context: context,
      title: 'عجز في كمية المخزون',
      description: 'لا يمكن ترحيل المستند بسبب عدم توفر كميات كافية في المخزون المرحّل للأصناف التالية:',
      icon: Icons.inventory_2_outlined,
      isDestructive: true,
      size: AppDialogSize.medium,
      confirmLabel: 'حسناً',
      showCloseButton: true,
      child: InventoryShortageDialog(shortages: shortages),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: shortages.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = shortages[index];
          return ListTile(
            dense: true,
            title: Text(
              '${item.itemName} (${item.itemCode})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'المطلوب: ${item.requested} | المتاح: ${item.available}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              'عجز: -${item.shortage}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}
