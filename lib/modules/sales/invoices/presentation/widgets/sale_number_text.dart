import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import '../../domain/services/device_sale_number.dart';

/// Renders a sale / invoice number for humans: short local sequence first,
/// optional muted full reference when multi-device absolute differs.
class SaleNumberText extends StatelessWidget {
  const SaleNumberText(
    this.saleNumber, {
    super.key,
    this.style,
    this.referenceStyle,
    this.showReference = false,
    this.maxLines = 1,
  });

  final String saleNumber;
  final TextStyle? style;
  final TextStyle? referenceStyle;

  /// When true, show the full absolute under/beside the short number.
  final bool showReference;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final view = saleNumberView(saleNumber);
    final primaryStyle =
        style ??
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800);

    if (!showReference || !view.hasSeparateReference) {
      return Text(
        view.primaryLabel,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: primaryStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          view.primaryLabel,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: primaryStyle,
        ),
        const SizedBox(height: 2),
        Text(
          l10n.salesInvoiceReference(view.referenceLabel!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              referenceStyle ??
              theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
