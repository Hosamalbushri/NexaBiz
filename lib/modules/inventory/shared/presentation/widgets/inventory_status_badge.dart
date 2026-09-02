import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
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
    return AppStatusBadge(
      label: status.displayName,
      tone: _tone(status),
      animate: !compact,
    );
  }

  static AppStatusTone _tone(InventoryDocumentStatus status) {
    return switch (status) {
      InventoryDocumentStatus.posted => AppStatusTone.success,
      InventoryDocumentStatus.draft => AppStatusTone.info,
      InventoryDocumentStatus.cancelled => AppStatusTone.error,
    };
  }
}
