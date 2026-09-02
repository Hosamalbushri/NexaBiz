import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../sync/app_bar_sync_actions.dart';
import '../../theme/app_breakpoints.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import 'module_unit_reports_page.dart';

/// Dynamic platform reports hub — renders module report cards directly.
///
/// Requires [ReportsModule] to be registered and enabled. Displays report
/// cards grouped by registered business modules.
class PlatformReportsPage extends ConsumerWidget {
  const PlatformReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unread = ref.watch(unreadNotificationsCountProvider);

    final registry = ref.watch(moduleRegistryProvider);

    // Reports are ONLY available if ReportsModule is registered & enabled
    final isReportsModuleActive = registry.isRegistered('reports');
    final reportsModule = registry.findById('reports');

    // Extract unique module IDs configured within ReportsModule
    final moduleIdsWithReports = (isReportsModuleActive && reportsModule != null)
        ? reportsModule.reportCategories.map((c) => c.moduleId).toSet()
        : <String>{};

    final modulesWithReports = [
      for (final m in registry.modules)
        if (m.isEnabled && moduleIdsWithReports.contains(m.id)) m,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.platformReportsTitle,
        centerTitle: true,
        leading: const AppBarSyncActions(),
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
      ),
      body: (!isReportsModuleActive || modulesWithReports.isEmpty)
          ? Center(
              child: AppEmptyState(
                icon: Icons.assessment_outlined,
                title: l10n.platformReportsTitle,
                subtitle: l10n.platformReportsServiceComingSoon,
              ),
            )
          : AppContentConstraint(
              child: ListView(
                padding: AppConstants.pageInsets(context),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.selectModuleReportsPrompt,
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
                        itemCount: modulesWithReports.length,
                        itemBuilder: (context, index) {
                          return _ModuleReportCard(module: modulesWithReports[index]);
                        },
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modulesWithReports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _ModuleReportCard(module: modulesWithReports[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _ModuleReportCard extends ConsumerWidget {
  const _ModuleReportCard({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = module.label(context);

    final reportsModule = ref.watch(moduleRegistryProvider).findById('reports');
    final moduleCategories = reportsModule?.reportCategories
            .where((c) => c.moduleId == module.id)
            .toList() ??
        const [];

    final totalReports = moduleCategories.fold<int>(
      0,
      (sum, cat) => sum + cat.reports.length,
    );

    final subtitle = module.description(context) ??
        (l10n.localeName == 'ar'
            ? '$totalReports تقارير متاحة'
            : '$totalReports reports available');

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleUnitReportsPage(moduleId: module.id),
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
                    module.icon,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$totalReports',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
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
