import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../shared/widgets/service_grid.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../sync/app_bar_sync_actions.dart';
import '../../theme/app_spacing.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

/// Dynamic platform reports hub — renders module report cards directly using ServiceGrid.
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
    final moduleIdsWithReports =
        (isReportsModuleActive && reportsModule != null)
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
        showBackButton: true,
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
                  ServiceGrid(
                    modules: modulesWithReports,
                    onModuleSelected: (module) {
                      context.push(AppRoutes.moduleReports(module.id));
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
