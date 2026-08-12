import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/services/counting_calculator.dart';

class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({super.key, required this.preview});

  final CountPreview preview;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        children: [
          _row(
            context,
            localization.mainQuantity,
            _format(preview.mainQuantity),
          ),
          _row(context, localization.subQuantity, _format(preview.subQuantity)),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
