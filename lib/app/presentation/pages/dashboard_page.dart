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
import '../../../modules/authentication/presentation/providers/auth_providers.dart';
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
        centerTitle: false,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
        actions: const [AppBarSyncActions()],
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
          final auth = ref.watch(authStateProvider);
          final permissions = ref.watch(currentPermissionsProvider);
          final modules =
              controller.resolveModules(permissions: permissions);
          final isOffline = !auth.isRemoteSession;
          final isRestricted = auth.isOfflineAuthorizationUnavailable ||
              (isOffline && permissions.isEmpty && !(auth.session?.user.isSuperAdmin ?? false));

          return Padding(
            padding: AppConstants.pageInsets(context),
            child: SingleChildScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isOffline) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isRestricted
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRestricted
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRestricted
                                ? Icons.security_update_warning_rounded
                                : Icons.offline_pin_rounded,
                            color: isRestricted
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRestricted
                                      ? 'Offline Authorization Restricted'
                                      : 'Offline Mode — Last Server Permissions Restored',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isRestricted
                                            ? Theme.of(context).colorScheme.onErrorContainer
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isRestricted
                                      ? 'Permissions unavailable for this offline account. Connect to the server to update permissions.'
                                      : 'Permissions are enforced using your last server synchronization snapshot.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 11,
                                        color: isRestricted
                                            ? Theme.of(context).colorScheme.onErrorContainer
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
