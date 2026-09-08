import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/administration/shared/presentation/admin_localizations_extension.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/sync/sync_enabled_provider.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/administration/settings'),
          ),
        ],
      ),
      body: auth.needsSessionRenewal
          ? AppEmptyState(
              icon: Icons.cloud_off_outlined,
              title: l10n.syncSessionExpired,
              subtitle: l10n.syncSessionExpired,
            )
          : ListView(
              padding: AppConstants.pageInsets(
                context,
              ).copyWith(top: AppSpacing.sm, bottom: AppSpacing.lg),
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
                    SettingsTile(
                      icon: Icons.tune_outlined,
                      title: l10n.localeName == 'ar'
                          ? 'إعدادات الإدارة العامة'
                          : 'Administration Master Settings',
                      subtitle: l10n.localeName == 'ar'
                          ? 'صفحة الإعدادات الشاملة للإدارة'
                          : 'Master administration settings hub',
                      showChevron: true,
                      onTap: () => context.push('/administration/settings'),
                    ),
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
                        onTap: () =>
                            context.push(AppRoutes.administrationPermissions),
                      ),
                    ),
                    PermissionGate(
                      anyOf: const [
                        'companies.view',
                        'companies.manage',
                        'platform.companies.manage',
                      ],
                      child: SettingsTile(
                        icon: Icons.business_outlined,
                        title: l10n.adminCompaniesTitle,
                        subtitle: 'إدارة الشركات للمؤسسة',
                        showChevron: true,
                        onTap: () =>
                            context.push(AppRoutes.administrationCompanies),
                      ),
                    ),
                    PermissionGate(
                      anyOf: const [
                        'branches.view',
                        'branches.manage',
                        'platform.companies.manage',
                      ],
                      child: SettingsTile(
                        icon: Icons.account_tree_outlined,
                        title: l10n.adminBranchesTitle,
                        subtitle: 'إدارة الفروع والهيكل التنظيمي الإداري',
                        showChevron: true,
                        onTap: () =>
                            context.push(AppRoutes.administrationBranches),
                      ),
                    ),
                    PermissionGate(
                      anyOf: const ['devices.view', 'devices.revoke'],
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
