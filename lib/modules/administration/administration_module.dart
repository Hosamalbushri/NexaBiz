import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/router/app_routes.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import 'branches/presentation/pages/admin_branches_page.dart';
import 'companies/presentation/pages/admin_companies_page.dart';
import 'devices/presentation/pages/admin_devices_page.dart';
import 'permissions_cat/presentation/pages/admin_permissions_catalog_page.dart';
import 'permissions/administration_permission_package.dart';
import 'roles/presentation/pages/admin_role_editor_page.dart';
import 'roles/presentation/pages/admin_roles_page.dart';
import 'shared/data/admin_api_repository.dart';
import 'shared/presentation/pages/administration_home_page.dart';
import 'users/presentation/pages/admin_users_page.dart';

/// Administration module — users / roles inside the same Flutter app.
class AdministrationModule extends AppModule {
  const AdministrationModule();

  static const String moduleId = 'administration';

  /// Self-registers AdministrationModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const AdministrationModule());
  }

  /// Self-unregisters AdministrationModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  static const usersView = [
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'users.manage',
    'platform.users.manage',
  ];
  static const rolesView = ['roles.view', 'roles.manage'];
  static const rolesCreate = ['roles.create', 'roles.manage'];
  static const rolesUpdate = ['roles.update', 'roles.manage'];
  static const permissionsManage = [
    'permissions.manage',
    'roles.manage',
    'platform.users.manage',
  ];
  static const devicesView = ['devices.view', 'devices.revoke'];
  static const companiesView = [
    'companies.view',
    'companies.manage',
    'platform.companies.manage',
  ];
  static const branchesView = [
    'branches.view',
    'branches.manage',
    'platform.companies.manage',
  ];

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleAdministration';

  @override
  IconData get icon => Icons.admin_panel_settings_outlined;

  @override
  String get rootRoute => AppRoutes.administration;

  @override
  int get sortOrder => 70;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => const [
    ...usersView,
    ...rolesView,
    ...devicesView,
    ...companiesView,
    ...branchesView,
  ];

  @override
  List<RouteAccessRule> get routeAccessRules => [
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationUsers,
      anyOf: usersView,
    ),
    RouteAccessRule(
      pathEquals: AppRoutes.administrationRolesCreate,
      anyOf: rolesCreate,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationRolesEdit,
      anyOf: rolesUpdate,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationRoles,
      anyOf: rolesView,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationPermissions,
      anyOf: permissionsManage,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationDevices,
      anyOf: devicesView,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationCompanies,
      anyOf: companiesView,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administrationBranches,
      anyOf: branchesView,
    ),
    RouteAccessRule(
      pathPrefix: AppRoutes.administration,
      anyOf: const [
        ...usersView,
        ...rolesView,
        ...devicesView,
        ...companiesView,
        ...branchesView,
      ],
    ),
  ];

  @override
  PermissionPackageDef? get permissionPackage =>
      administrationPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleAdministration;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleAdministrationDescription;
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.administration,
      name: 'administrationModule',
      builder: (context, state) => const AdministrationHomePage(),
      routes: [
        GoRoute(
          path: 'users',
          name: 'administrationModuleUsers',
          builder: (context, state) => const AdminUsersPage(),
        ),
        GoRoute(
          path: 'roles',
          name: 'administrationModuleRoles',
          builder: (context, state) => const AdminRolesPage(),
          routes: [
            GoRoute(
              path: 'new',
              name: 'administrationModuleRolesCreate',
              builder: (context, state) => const AdminRoleEditorPage(),
            ),
            GoRoute(
              path: 'edit',
              name: 'administrationModuleRolesEdit',
              builder: (context, state) => AdminRoleEditorPage(
                existing: state.extra as AdminRoleSummary?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'permissions',
          name: 'administrationModulePermissions',
          builder: (context, state) => const AdminPermissionsCatalogPage(),
        ),
        GoRoute(
          path: 'devices',
          name: 'administrationModuleDevices',
          builder: (context, state) => const AdminDevicesPage(),
        ),
        GoRoute(
          path: 'companies',
          name: 'administrationModuleCompanies',
          builder: (context, state) => const AdminCompaniesPage(),
        ),
        GoRoute(
          path: 'branches',
          name: 'administrationModuleBranches',
          builder: (context, state) => const AdminBranchesPage(),
        ),
      ],
    ),
  ];
}
