import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/inventory_item.dart';
import 'status_badge.dart';

class ReportItemCard extends StatelessWidget {
  const ReportItemCard({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${localization.codeLabel}: ${item.itemCode}'),
          Text('${localization.mainQuantity}: ${_format(item.mainQuantity)}'),
          Text('${localization.subQuantity}: ${_format(item.subQuantity)}'),
        ],
      ),
    );
  }

  String _format(double? value) {
    if (value == null) {
      return '-';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
