import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_shadows.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/services/account_labels.dart';
import 'account_type_style.dart';

/// Compact browse toolbar for Chart of Accounts (filters + tree actions).
class AccountBrowseToolbar extends StatelessWidget {
  const AccountBrowseToolbar({
    super.key,
    required this.accountsCount,
    required this.typeFilter,
    required this.includeInactive,
    required this.onTypeFilterChanged,
    required this.onIncludeInactiveChanged,
    required this.onExpandAll,
    required this.onCollapseAll,
    this.showSubtitle = true,
  });

  final int? accountsCount;
  final AccountType? typeFilter;
  final bool includeInactive;
  final ValueChanged<AccountType?> onTypeFilterChanged;
  final ValueChanged<bool> onIncludeInactiveChanged;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: AppShadows.card(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountingChartOfAccounts,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accountsCount == null
                            ? '…'
                            : l10n.accountingAccountsCount(accountsCount!),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _ActionCluster(
                  children: [
                    _ActionIcon(
                      tooltip: includeInactive
                          ? l10n.accountingHideInactive
                          : l10n.accountingShowInactive,
                      icon: includeInactive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      selected: includeInactive,
                      onPressed: () =>
                          onIncludeInactiveChanged(!includeInactive),
                    ),
                    _ActionIcon(
                      tooltip: l10n.accountingExpandAll,
                      icon: Icons.unfold_more_rounded,
                      onPressed: onExpandAll,
                    ),
                    _ActionIcon(
                      tooltip: l10n.accountingCollapseAll,
                      icon: Icons.unfold_less_rounded,
                      onPressed: onCollapseAll,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showSubtitle) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.accountingChartOfAccountsDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.accountingFilterByType,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypePill(
                        label: l10n.accountingFilterAll,
                        selected: typeFilter == null,
                        color: scheme.primary,
                        icon: Icons.apps_rounded,
                        onTap: () => onTypeFilterChanged(null),
                      ),
                      for (final type in AccountType.values) ...[
                        const SizedBox(width: 8),
                        _TypePill(
                          label: AccountLabels.typeLabel(l10n, type),
                          selected: typeFilter == type,
                          color: accountTypeColor(scheme, type),
                          icon: accountTypeIcon(type),
                          onTap: () => onTypeFilterChanged(type),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 18,
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
      style: IconButton.styleFrom(
        foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
        backgroundColor: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? color.withValues(alpha: 0.14)
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? color : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
