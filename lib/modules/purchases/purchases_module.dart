import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../../core/setup/setup.dart';
import '../../core/modules/module_setup_definition.dart';
import 'permissions/purchases_permission_package.dart';
import 'presentation/pages/purchases_home_page.dart';
import 'presentation/pages/purchases_master_settings_page.dart';
import 'purchases_module_setup.dart';

/// Purchases business module in NexaBiz ERP.
class PurchasesModule extends AppModule {
  const PurchasesModule();

  static const String moduleId = 'purchases';

  static void register({CentralSetupRegistry? setupRegistry}) {
    ModuleRegistry.register(const PurchasesModule());
    if (setupRegistry != null) {
      registerPurchasesSetup(setupRegistry);
    }
  }

  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'modulePurchases';

  @override
  IconData get icon => Icons.shopping_bag_outlined;

  @override
  String get rootRoute => '/purchases';

  @override
  int get sortOrder => 35;

  @override
  bool get isEnabled => true;

  @override
  List<ModuleSetupStepDefinition> get setupSteps => purchasesSetupSteps;

  @override
  List<String> get requiredAnyPermissions => PurchasesPermissions.view;

  @override
  List<RouteAccessRule> get routeAccessRules => [
    RouteAccessRule(pathPrefix: '/purchases', anyOf: PurchasesPermissions.view),
  ];

  @override
  PermissionPackageDef? get permissionPackage => purchasesPermissionPackage();

  @override
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return l10n.localeName == 'ar'
        ? 'المشتريات والموردين'
        : 'Purchases & Suppliers';
  }

  @override
  String? description(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return l10n.localeName == 'ar'
        ? 'إدارة أوامر الشراء، فواتير المشتريات، والموردين'
        : 'Purchase Orders, Vendor Invoices, and Supplier Catalog';
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: '/purchases',
      name: 'purchases',
      builder: (context, state) => const PurchasesHomePage(),
    ),
    GoRoute(
      path: '/purchases/settings',
      name: 'purchasesSettings',
      builder: (context, state) => const PurchasesMasterSettingsPage(),
    ),
  ];
}
