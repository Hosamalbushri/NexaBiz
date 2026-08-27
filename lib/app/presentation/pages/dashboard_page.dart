import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../sync/app_bar_sync_actions.dart';
import '../../theme/app_spacing.dart';
import '../../../core/auth/presentation/providers/auth_state_core.dart';
import '../providers/dashboard_services_provider.dart';
import '../providers/quick_actions_panel_provider.dart';
import '../widgets/dashboard_recent_operations.dart';
import '../widgets/dashboard_services_panel.dart';
import 'dashboard_customize_sheet.dart';

/// Platform dashboard with user-customizable service shortcuts.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(dashboardServicesProvider);
    final controller = ref.read(dashboardServicesProvider.notifier);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.dashboardTitle,
        centerTitle: true,
        leading: const AppBarSyncActions(),
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
      ),
      body: servicesAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.somethingWentWrong),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: l10n.retry, onPressed: controller.reload),
              ],
            ),
          ),
        ),
        data: (_) {
          final permissions = ref.watch(currentPermissionsProvider);
          final modules =
              controller.resolveModules(permissions: permissions);

          return SingleChildScrollView(
            padding: AppConstants.pageInsets(context),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardServicesPanel(
                  modules: modules,
                  customizeLabel: l10n.dashboardCustomizeServices,
                  onCustomize: () => _openCustomize(context, ref),
                  onModuleSelected: (module) {
                    if (!module.isEnabled) {
                      return;
                    }
                    // Use go (not push): leaving StatefulShellRoute under a
                    // pushed module, then later pushing a shell tab, duplicates
                    // ShellRouteMatch page keys (go_router #140586).
                    context.go(module.rootRoute);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                const DashboardRecentOperations(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCustomize(BuildContext context, WidgetRef ref) async {
    // Avoid fighting the shell quick-actions panel / nested sheets.
    requestCloseQuickActions(ref);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!context.mounted) {
      return;
    }

    final registry = ref.read(moduleRegistryProvider);
    final permissions = ref.read(currentPermissionsProvider);
    final isSuperAdmin =
        ref.read(authStateProvider).session?.user.isSuperAdmin == true;
    final availableModules = [
      for (final module in registry.enabledModules)
        if (isSuperAdmin ||
            module.requiredAnyPermissions.isEmpty ||
            module.requiredAnyPermissions.any(permissions.contains))
          module,
    ];
    final current =
        ref.read(dashboardServicesProvider).valueOrNull ??
        [for (final module in availableModules) module.id];

    final result = await showAppBottomSheet<List<String>>(
      context: context,
      child: DashboardCustomizeSheet(
        availableModules: availableModules,
        initiallySelectedIds: current,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await ref.read(dashboardServicesProvider.notifier).save(result);
  }
}
