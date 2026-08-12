import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../models/report_entry_definition.dart';

/// Lists service reports for one module (e.g. Inventory → stock count report).
class ModuleReportsPage extends StatelessWidget {
  const ModuleReportsPage({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final module = findReportModule(moduleId);
    final entries = reportsForModule(moduleId);

    if (module == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: l10n.platformReportsTitle,
          showBackButton: true,
        ),
        body: AppEmptyState(
          title: l10n.somethingWentWrong,
          subtitle: l10n.platformReportsComingSoon,
          icon: Icons.assessment_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: module.title(l10n),
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            module.subtitle(l10n),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            AppEmptyState(
              title: l10n.platformReportsComingSoon,
              subtitle: l10n.platformReportsServiceComingSoon,
              icon: Icons.assessment_outlined,
            )
          else
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _ServiceReportTile(entry: entries[i]),
            ],
        ],
      ),
    );
  }
}

class _ServiceReportTile extends StatelessWidget {
  const _ServiceReportTile({required this.entry});

  final ReportEntryDefinition entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final available = entry.isAvailable;

    return AppCard(
      onTap: available ? () => context.push(entry.path!) : null,
      color: available
          ? null
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: (available ? colorScheme.primary : colorScheme.outline)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                entry.icon,
                color: available
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title(l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: available
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle(l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (available)
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            )
          else
            AppStatusBadge(
              label: l10n.moduleComingSoon,
              tone: AppStatusTone.neutral,
              animate: false,
            ),
        ],
      ),
    );
  }
}
