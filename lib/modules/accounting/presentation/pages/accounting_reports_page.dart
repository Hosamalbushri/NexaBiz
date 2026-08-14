import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/custom_app_bar.dart';

/// Accounting reports hub — Chart of Accounts statements first.
class AccountingReportsPage extends StatelessWidget {
  const AccountingReportsPage({super.key});

  /// Deep-link into Reports module account-statement form (no module import).
  static const String _accountStatementPath =
      '/module-reports/account-statement';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final entries = <_ReportEntry>[
      _ReportEntry(
        icon: Icons.menu_book_outlined,
        title: l10n.reportsAccountStatementTitle,
        subtitle: l10n.reportsAccountStatementSubtitle,
        path: _accountStatementPath,
        available: true,
      ),
      _ReportEntry(
        icon: Icons.balance_outlined,
        title: l10n.accountingReportTrialBalanceTitle,
        subtitle: l10n.accountingReportComingSoonSubtitle,
        available: false,
      ),
      _ReportEntry(
        icon: Icons.receipt_long_outlined,
        title: l10n.accountingReportJournalTitle,
        subtitle: l10n.accountingReportComingSoonSubtitle,
        available: false,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.accountingReportsTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            l10n.accountingReportsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _ReportTile(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _ReportEntry {
  const _ReportEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.available,
    this.path,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool available;
  final String? path;
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.entry});

  final _ReportEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = entry.available;

    return Material(
      color: available
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: available && entry.path != null
            ? () => context.push(entry.path!)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (available
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    entry.icon,
                    color: available
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: available
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(height: 8),
                        AppStatusBadge(
                          label: l10n.accountingReportComingSoonBadge,
                          tone: AppStatusTone.neutral,
                          animate: false,
                        ),
                      ],
                    ],
                  ),
                ),
                if (available)
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
