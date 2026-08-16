import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

PermissionPackageDef administrationPermissionPackage() {
  return PermissionPackageDef(
    id: 'administration',
    icon: Icons.admin_panel_settings_outlined,
    sortOrder: 60,
    titleBuilder: (context) =>
        AppLocalizations.of(context).moduleAdministration,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageAdminHint,
    services: [
      PermissionServiceDef(
        id: 'users',
        icon: Icons.people_outline,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminUsersTitle,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminUsersSubtitle,
        operations: [
          StandardPermissionOps.view('users.view'),
          StandardPermissionOps.create('users.create'),
          StandardPermissionOps.update('users.update'),
          StandardPermissionOps.delete('users.delete'),
          StandardPermissionOps.manage('users.manage'),
        ],
      ),
      PermissionServiceDef(
        id: 'roles',
        icon: Icons.badge_outlined,
        titleBuilder: (context) => AppLocalizations.of(context).adminRolesTitle,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminRolesHubSubtitle,
        operations: [
          StandardPermissionOps.view('roles.view'),
          StandardPermissionOps.create('roles.create'),
          StandardPermissionOps.update('roles.update'),
          StandardPermissionOps.delete('roles.delete'),
          StandardPermissionOps.manage('roles.manage'),
        ],
      ),
      PermissionServiceDef(
        id: 'permissions',
        icon: Icons.checklist_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermissionsCatalogTitle,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermissionsCatalogSubtitle,
        operations: [
          StandardPermissionOps.manage('permissions.manage'),
        ],
      ),
    ],
  );
}
