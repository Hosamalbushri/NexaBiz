import 'package:flutter/material.dart';

import '../../core/modules/module_settings_definition.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'module_unit_settings_page.dart';

/// Screen displaying the list/grid of registered module cards.
class ModulesSettingsPage extends StatelessWidget {
  const ModulesSettingsPage({
    super.key,
    required this.categories,
  });

  final List<ModuleSettingsCategoryDefinition> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pageTitle = l10n.moduleUnitsSettingsTitle;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: pageTitle,
        showBackButton: true,
      ),
      body: categories.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: Icons.grid_view_rounded,
                title: pageTitle,
                subtitle: l10n.platformReportsServiceComingSoon,
              ),
            )
          : ListView(
              padding: AppConstants.pageInsets(context),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.selectModulePrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = AppBreakpoints.isTablet(constraints.maxWidth) ||
                        AppBreakpoints.isDesktop(constraints.maxWidth);

                    if (isWide) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 2.6,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return _ModuleCard(category: categories[index]);
                        },
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _ModuleCard(category: categories[index]);
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.category});

  final ModuleSettingsCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = category.titleBuilder(l10n);
    final subtitle = category.subtitleBuilder?.call(l10n) ??
        (l10n.localeName == 'ar'
            ? '${category.items.length} وحدات إعدادات'
            : '${category.items.length} setting units');

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleUnitSettingsPage(category: category),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: AppShadows.card(theme.brightness),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ),
                  child: Icon(
                    category.icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
