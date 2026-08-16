import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_amount_field.dart';
import '../../domain/entities/sale_status.dart';

class SaleStatusBadge extends StatelessWidget {
  const SaleStatusBadge({super.key, required this.status, required this.label});

  final SaleStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      SaleStatus.unposted => (scheme.surfaceContainerHighest, scheme.onSurface),
      SaleStatus.posted => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return _Badge(label: label, background: bg, foreground: fg);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String formatSaleMoney(BuildContext context, double value) {
  return formatAppAmount(context, value);
}

class SaleMoneyText extends StatelessWidget {
  const SaleMoneyText(this.value, {super.key, this.style, this.textAlign});

  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AppAmountText(value, style: style, textAlign: textAlign);
  }
}

Widget saleSectionGap() => const SizedBox(height: AppSpacing.md);
