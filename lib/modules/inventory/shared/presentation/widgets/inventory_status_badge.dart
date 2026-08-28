import 'package:flutter/material.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

class InventoryStatusBadge extends StatelessWidget {
  const InventoryStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final InventoryDocumentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;

    switch (status) {
      case InventoryDocumentStatus.posted:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case InventoryDocumentStatus.draft:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.edit_document;
        break;
      case InventoryDocumentStatus.cancelled:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
