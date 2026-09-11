import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/modules/module_providers.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/shared/providers/module_hub_view_mode_provider.dart';

/// Catalog of report categories owned by ReportsModule matching standard module grid/list layout.
class ReportsHomePage extends ConsumerWidget {
  const ReportsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewMode = ref.watch(moduleHubViewModeProvider);
    final isGrid = viewMode == ModuleHubViewMode.grid;

    final registry = ref.watch(moduleRegistryProvider);

    // Reports are ONLY available if ReportsModule is registered & enabled
    final isReportsModuleActive = registry.isRegistered('reports');
    final reportsModule = registry.findById('reports');

    // Extract unique module IDs configured within ReportsModule
    final moduleIdsWithReports =
        (isReportsModuleActive && reportsModule != null)
            ? reportsModule.reportCategories.map((c) => c.moduleId).toSet()
            : <String>{};

    final modulesWithReports = [
      for (final m in registry.modules)
        if (m.isEnabled && moduleIdsWithReports.contains(m.id)) m,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: l10n.moduleReports, showBackButton: true),
      body: (!isReportsModuleActive || modulesWithReports.isEmpty)
          ? Center(
              child: AppEmptyState(
                icon: Icons.assessment_outlined,
                title: l10n.moduleReports,
                subtitle: l10n.platformReportsServiceComingSoon,
              ),
            )
          : AppContentConstraint(
              child: ListView(
                padding: AppConstants.pageInsets(context),
                children: [
                  AppModuleHubHeader(
                    title: l10n.servicesTitle,
                    subtitle: l10n.selectModuleReportsPrompt,
                    trailing: AppViewModeToggle<ModuleHubViewMode>(
                      options: [
                        AppViewModeOption(
                          value: ModuleHubViewMode.grid,
                          icon: Icons.grid_view_rounded,
                          tooltip: l10n.localeName == 'ar'
                              ? 'عرض شبكي'
                              : 'Grid View',
                        ),
                        AppViewModeOption(
                          value: ModuleHubViewMode.list,
                          icon: Icons.view_list_rounded,
                          tooltip: l10n.localeName == 'ar'
                              ? 'عرض قائمة'
                              : 'List View',
                        ),
                      ],
                      selected: viewMode,
                      onChanged: (mode) => ref
                          .read(moduleHubViewModeProvider.notifier)
                          .setMode(mode),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppModuleHubView(
                    isGrid: isGrid,
                    children: [
                      for (var i = 0; i < modulesWithReports.length; i++)
                        _buildReportItem(
                          context,
                          ref,
                          modulesWithReports[i],
                          i,
                          isGrid,
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    WidgetRef ref,
    module,
    int index,
    bool isGrid,
  ) {
    final l10n = AppLocalizations.of(context);
    final title = module.label(context);

    final reportsModule = ref
        .watch(moduleRegistryProvider)
        .findById('reports');
    final moduleCategories =
        reportsModule?.reportCategories
            .where((c) => c.moduleId == module.id)
            .toList() ??
        const [];

    final totalReports = moduleCategories.fold<int>(
      0,
      (sum, cat) => sum + cat.reports.length,
    );

    final subtitle =
        module.description(context) ??
        (l10n.localeName == 'ar'
            ? '$totalReports تقارير متاحة'
            : '$totalReports reports available');

    final onTap = () => context.push(AppRoutes.moduleReports(module.id));

    if (isGrid) {
      return AppModuleHubTile(
        icon: module.icon,
        title: title,
        subtitle: subtitle,
        animationDelay: Duration(milliseconds: index * 40),
        onTap: onTap,
      );
    }

    return AppModuleHubCard(
      icon: module.icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
