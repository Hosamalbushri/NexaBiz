import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/modules/module_settings_definition.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Screen displaying sub-module unit cards for a selected module's settings category.
class ModuleUnitSettingsPage extends StatelessWidget {
  const ModuleUnitSettingsPage({
    super.key,
    required this.category,
  });

  final ModuleSettingsCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final moduleTitle = category.titleBuilder(l10n);
    final moduleSubtitle = category.subtitleBuilder?.call(l10n);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: moduleTitle,
        showBackButton: true,
      ),
      body: category.items.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: category.icon,
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
                          category.icon,
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

                // Section Title
                Text(
                  l10n.localeName == 'ar' ? 'بطاقات إعدادات الوحدات' : 'Unit Settings Cards',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Sub-Module Unit Cards Grid/List
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
                          childAspectRatio: 2.8,
                        ),
                        itemCount: category.items.length,
                        itemBuilder: (context, index) {
                          return _UnitSettingCard(item: category.items[index]);
                        },
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: category.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _UnitSettingCard(item: category.items[index]);
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _UnitSettingCard extends StatelessWidget {
  const _UnitSettingCard({required this.item});

  final ModuleSettingsItemDefinition item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = item.titleBuilder(l10n);
    final subtitle = item.subtitleBuilder?.call(l10n);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          if (item.onTap != null) {
            item.onTap!(context);
          } else if (item.path != null && item.path!.isNotEmpty) {
            context.push(item.path!);
          }
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    item.icon,
                    color: colorScheme.secondary,
                    size: 22,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
