import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

/// Cross-cutting platform permissions (settings / sync / devices / companies).
///
/// Owned by System Setup so they remain available even when domain modules
/// are removed from the registry.
PermissionPackageDef platformPermissionPackage() {
  return PermissionPackageDef(
    id: 'platform',
    icon: Icons.settings_outlined,
    sortOrder: 90,
    titleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackagePlatform,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackagePlatformHint,
    services: [
      PermissionServiceDef(
        id: 'settings',
        icon: Icons.tune,
        titleBuilder: (context) => AppLocalizations.of(context).settingsTitle,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermGroupSettingsHint,
        operations: [
          StandardPermissionOps.view('settings.view'),
          StandardPermissionOps.update('settings.update'),
        ],
      ),
      PermissionServiceDef(
        id: 'sync',
        icon: Icons.sync_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).syncSectionTitle,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermGroupSyncHint,
        operations: [
          StandardPermissionOps.view('sync.view'),
          StandardPermissionOps.custom(
            code: 'sync.execute',
            icon: Icons.play_circle_outline,
            label: (l10n) => l10n.adminPermActionExecute,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'devices',
        icon: Icons.devices_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermResourceDevices,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceDevicesHint,
        operations: [
          StandardPermissionOps.view('devices.view'),
          StandardPermissionOps.custom(
            code: 'devices.revoke',
            icon: Icons.block_outlined,
            label: (l10n) => l10n.adminPermActionRevoke,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'companies',
        icon: Icons.business_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermResourceCompanies,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCompaniesHint,
        operations: [
          StandardPermissionOps.view('companies.view'),
          StandardPermissionOps.update('companies.update'),
          StandardPermissionOps.custom(
            code: 'platform.companies.manage',
            icon: Icons.business_outlined,
            label: (l10n) => l10n.adminPermOpPlatformCompanies,
          ),
          StandardPermissionOps.custom(
            code: 'platform.users.manage',
            icon: Icons.manage_accounts_outlined,
            label: (l10n) => l10n.adminPermOpPlatformUsers,
          ),
        ],
      ),
    ],
  );
}
