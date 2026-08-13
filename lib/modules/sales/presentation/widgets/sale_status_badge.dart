import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/sale_status.dart';

class SaleStatusBadge extends StatelessWidget {
  const SaleStatusBadge({super.key, required this.status, required this.label});

  final SaleStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      SaleStatus.draft => (scheme.surfaceContainerHighest, scheme.onSurface),
      SaleStatus.pending => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      SaleStatus.confirmed => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      SaleStatus.completed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      SaleStatus.cancelled ||
      SaleStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return _Badge(label: label, background: bg, foreground: fg);
  }
}

class SalePaymentStatusBadge extends StatelessWidget {
  const SalePaymentStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  final PaymentStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      PaymentStatus.paid => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      PaymentStatus.partiallyPaid => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PaymentStatus.unpaid => (scheme.errorContainer, scheme.onErrorContainer),
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
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format(value);
}

class SaleMoneyText extends StatelessWidget {
  const SaleMoneyText(this.value, {super.key, this.style, this.textAlign});

  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatSaleMoney(context, value),
      style: style,
      textAlign: textAlign,
    );
  }
}

Widget saleSectionGap() => const SizedBox(height: AppSpacing.md);
