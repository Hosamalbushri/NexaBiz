import 'package:flutter/material.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';

class InventoryShortageDialog extends StatelessWidget {
  const InventoryShortageDialog({
    super.key,
    required this.shortages,
  });

  final List<StockShortageItem> shortages;

  static Future<void> show(
    BuildContext context, {
    required List<StockShortageItem> shortages,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InventoryShortageDialog(shortages: shortages),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 8),
          const Text('عجز في كمية المخزون'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لا يمكن ترحيل المستند بسبب عدم توفر كميات كافية في المخزون المرحّل للأصناف التالية:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
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
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
          child: const Text('حسناً'),
        ),
      ],
    );
  }
}
