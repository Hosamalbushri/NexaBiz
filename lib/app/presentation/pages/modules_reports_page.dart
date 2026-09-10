import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../shared/widgets/service_grid.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../theme/app_spacing.dart';

/// Screen displaying the hub of all registered business module report cards using ServiceGrid.
class ModulesReportsPage extends ConsumerWidget {
  const ModulesReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pageTitle = l10n.moduleUnitsReportsTitle;

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
      appBar: CustomAppBar(title: pageTitle, showBackButton: true),
      body: modulesWithReports.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: Icons.assessment_outlined,
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
                    l10n.selectModuleReportsPrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ServiceGrid(
                  modules: modulesWithReports,
                  onModuleSelected: (module) {
                    context.push(AppRoutes.moduleReports(module.id));
                  },
                ),
              ],
            ),
    );
  }
}
