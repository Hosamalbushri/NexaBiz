import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

/// Customers permission codes (primary + legacy).
abstract final class CustomersPermissions {
  static const view = ['customers.master.view', 'customers.view'];
  static const create = ['customers.master.create', 'customers.create'];
  static const update = ['customers.master.update', 'customers.update'];
  static const delete = ['customers.master.delete', 'customers.delete'];
  static const importOp = ['customers.master.import'];
  static const accountsView = ['customers.accounts.view'];
  static const settingsView = [
    'customers.settings.view',
    'customers.master.view',
    'customers.view',
  ];
  static const settingsUpdate = [
    'customers.settings.update',
    'customers.master.update',
    'customers.update',
  ];
}

PermissionPackageDef customersPermissionPackage() {
  return PermissionPackageDef(
    id: 'customers',
    icon: Icons.people_outline,
    sortOrder: 30,
    titleBuilder: (context) => AppLocalizations.of(context).moduleCustomers,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageCustomersHint,
    services: [
      PermissionServiceDef(
        id: 'master',
        icon: Icons.person_outline,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCustomersMaster,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCustomersMasterHint,
        operations: [
          StandardPermissionOps.view(
            'customers.master.view',
            legacyCodes: const ['customers.view'],
          ),
          StandardPermissionOps.create(
            'customers.master.create',
            legacyCodes: const ['customers.create'],
          ),
          StandardPermissionOps.update(
            'customers.master.update',
            legacyCodes: const ['customers.update'],
          ),
          StandardPermissionOps.delete(
            'customers.master.delete',
            legacyCodes: const ['customers.delete'],
          ),
          StandardPermissionOps.importOp('customers.master.import'),
        ],
      ),
      PermissionServiceDef(
        id: 'accounts',
        icon: Icons.account_tree_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCustomersAccounts,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCustomersAccountsHint,
        operations: [
          StandardPermissionOps.view('customers.accounts.view'),
        ],
      ),
      PermissionServiceDef(
        id: 'settings',
        icon: Icons.tune_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCustomersSettings,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCustomersSettingsHint,
        operations: [
          StandardPermissionOps.view('customers.settings.view'),
          StandardPermissionOps.update('customers.settings.update'),
        ],
      ),
    ],
  );
}
