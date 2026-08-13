import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/sale_settlement_type.dart';

/// Professional cash / credit invoice-type picker.
class SaleSettlementTypeSelector extends StatelessWidget {
  const SaleSettlementTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SaleSettlementType value;
  final ValueChanged<SaleSettlementType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.salesSettlementType,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _SettlementOptionCard(
                selected: value.isCash,
                icon: Icons.payments_outlined,
                title: l10n.salesSettlementCash,
                onTap: () => onChanged(SaleSettlementType.cash),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _SettlementOptionCard(
                selected: value.isCredit,
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.salesSettlementCredit,
                onTap: () => onChanged(SaleSettlementType.credit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettlementOptionCard extends StatelessWidget {
  const _SettlementOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final background = selected
        ? scheme.primaryContainer.withValues(alpha: 0.55)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final borderColor = selected
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: 0.55);
    final iconColor = selected ? scheme.primary : scheme.onSurfaceVariant;
    final titleColor = selected ? scheme.primary : scheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 14, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
