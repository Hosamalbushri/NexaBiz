import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../app/sync/sync_enabled_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../authentication/presentation/widgets/permission_gate.dart';
import '../providers/admin_providers.dart';

/// Administration hub with clear entry points for access control.
class AdministrationHomePage extends ConsumerWidget {
  const AdministrationHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final syncOn = ref.watch(syncEnabledProvider);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleAdministration,
        centerTitle: false,
        showBackButton: true,
      ),
      body: (!syncOn || !auth.canUseRemoteSync)
          ? AppEmptyState(
              icon: Icons.cloud_off_outlined,
              title: auth.needsSessionRenewal
                  ? l10n.syncSessionExpired
                  : l10n.adminRequiresOnlineTitle,
              subtitle: auth.needsSessionRenewal
                  ? l10n.syncSessionExpired
                  : l10n.adminRequiresOnlineMessage,
            )
          : ListView(
              padding: AppConstants.pageInsets(context).copyWith(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              children: [
                Text(
                  l10n.adminAccessControlIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsGroupLabel(l10n.adminAccessControlSection),
                SettingsGroup(
                  children: [
                    PermissionGate(
                      anyOf: const [
                        'users.view',
                        'users.manage',
                        'platform.users.manage',
                      ],
                      child: SettingsTile(
                        icon: Icons.people_outline,
                        title: l10n.adminUsersTitle,
                        subtitle: l10n.adminUsersSubtitle,
                        showChevron: true,
                        onTap: () =>
                            context.push(AppRoutes.administrationUsers),
                      ),
                    ),
                    PermissionGate(
                      anyOf: const ['roles.view', 'roles.manage'],
                      child: SettingsTile(
                        icon: Icons.badge_outlined,
                        title: l10n.adminRolesTitle,
                        subtitle: l10n.adminRolesHubSubtitle,
                        showChevron: true,
                        onTap: () =>
                            context.push(AppRoutes.administrationRoles),
                      ),
                    ),
                    PermissionGate(
                      anyOf: const [
                        'roles.view',
                        'permissions.manage',
                        'roles.manage',
                      ],
                      child: SettingsTile(
                        icon: Icons.checklist_rtl_outlined,
                        title: l10n.adminPermissionsCatalogTitle,
                        subtitle: l10n.adminPermissionsCatalogSubtitle,
                        showChevron: true,
                        onTap: () => context
                            .push(AppRoutes.administrationPermissions),
                      ),
                    ),
                    PermissionGate(
                      anyOf: const [
                        'devices.view',
                        'devices.revoke',
                      ],
                      child: const _DevicesTile(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.adminAccessControlTip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DevicesTile extends ConsumerWidget {
  const _DevicesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending =
        ref.watch(adminSyncDisableRequestsProvider).asData?.value.length ?? 0;
    return SettingsTile(
      icon: Icons.devices_outlined,
      title: l10n.adminDevicesTitle,
      subtitle: pending > 0
          ? l10n.adminDevicesPendingCount(pending)
          : l10n.adminDevicesSubtitle,
      showChevron: true,
      onTap: () => context.push(AppRoutes.administrationDevices),
    );
  }
}
