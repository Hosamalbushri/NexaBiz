import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../core/widgets/app_amount_field.dart';
import '../../domain/entities/transaction_status.dart';

class TransactionStatusBadge extends StatelessWidget {
  const TransactionStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  final TransactionStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      TransactionStatus.unposted => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
      TransactionStatus.posted => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String formatRpMoney(BuildContext context, double value) {
  return formatAppAmount(context, value, decimalPlaces: 0);
}

class RpMoneyText extends StatelessWidget {
  const RpMoneyText(this.value, {super.key, this.style, this.textAlign});

  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AppAmountText(
      value,
      decimalPlaces: 0,
      style: style,
      textAlign: textAlign,
    );
  }
}
