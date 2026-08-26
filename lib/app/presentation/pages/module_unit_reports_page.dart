import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/modules/report_category_definition.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Screen displaying sub-module unit reports for a selected module.
class ModuleUnitReportsPage extends ConsumerWidget {
  const ModuleUnitReportsPage({
    super.key,
    required this.moduleId,
  });

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final registry = ref.watch(moduleRegistryProvider);
    final module = registry.findById(moduleId);

    // Categories are centrally owned by ReportsModule and filtered by moduleId
    final reportsModule = registry.findById('reports');
    final categories = reportsModule?.reportCategories
            .where((c) => c.moduleId == moduleId)
            .toList() ??
        const [];

    final moduleTitle = module?.label(context) ?? moduleId;
    final moduleSubtitle = module?.description(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: moduleTitle,
        showBackButton: true,
      ),
      body: categories.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: module?.icon ?? Icons.assessment_outlined,
                title: moduleTitle,
                subtitle: l10n.platformReportsServiceComingSoon,
              ),
            )
          : ListView(
              padding: AppConstants.pageInsets(context),
              children: [
                // Module Header Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: AppShadows.card(theme.brightness),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                        ),
                        child: Icon(
                          module?.icon ?? Icons.assessment_outlined,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moduleTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (moduleSubtitle != null && moduleSubtitle.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                moduleSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Categories & Units
                for (final category in categories) ...[
                  _UnitReportCategorySection(category: category),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class _UnitReportCategorySection extends StatelessWidget {
  const _UnitReportCategorySection({required this.category});

  final ReportCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryTitle = category.title(l10n);
    final categorySubtitle = category.subtitle(l10n);
    final reports = category.reports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              categoryTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (categorySubtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            categorySubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < reports.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _ReportItemCard(item: reports[i]),
        ],
      ],
    );
  }
}

class _ReportItemCard extends StatelessWidget {
  const _ReportItemCard({required this.item});

  final ReportItemDefinition item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final available = item.isAvailable;

    return AppCard(
      onTap: available
          ? () => context.push(item.path!)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.platformReportsServiceComingSoon),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
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
                item.icon,
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
                  item.title(l10n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: available
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (available)
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                l10n.platformReportsServiceComingSoon,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
