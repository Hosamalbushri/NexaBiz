import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/core/modules/app_module.dart';
import 'package:stock_count/app/router/app_routes.dart';

import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/core/modules/route_access_rule.dart';
import 'package:stock_count/core/permissions/permission_defs.dart';


/// Independent Currency & Exchange Business Module.
class CurrencyModule extends AppModule {
  const CurrencyModule();

  static const String moduleId = 'currency';

  static void register() {
    ModuleRegistry.register(const CurrencyModule());
  }

  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleCurrency';

  @override
  IconData get icon => Icons.monetization_on_outlined;

  @override
  String get rootRoute => AppRoutes.settingsCurrencies;

  @override
  int get sortOrder => 15;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => const [
        'accounting.currency_rates.view',
        'accounting.fiscal_years.configure_fx',
        'platform.company.manage',
      ];

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathPrefix: AppRoutes.settingsCurrencies,
          anyOf: requiredAnyPermissions,
        ),
      ];


  @override
  PermissionPackageDef? get permissionPackage => PermissionPackageDef(
        id: 'currency',
        icon: Icons.monetization_on_outlined,
        sortOrder: 45,
        titleBuilder: (context) =>
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'إدارة العملات وسعر الصرف'
                : 'Currency & Exchange Rate Management',
        subtitleBuilder: (context) =>
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تكوين العملة الوظيفية وسجل أسعار الصرف'
                : 'Configure functional currency and FX rates log',
        services: [
          PermissionServiceDef(
            id: 'currency_management',
            icon: Icons.currency_exchange_outlined,
            titleBuilder: (context) =>
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'إدارة العملات'
                    : 'Currency Management',
            subtitleBuilder: (context) =>
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'إعداد العملة الوظيفية وأسعار الصرف'
                    : 'Manage functional currency and rates',
            operations: [
              PermissionOperationDef(
                code: 'currency.functional.configure',
                icon: Icons.tune_outlined,
                labelBuilder: (context) =>
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'تكوين العملة الوظيفية'
                        : 'Configure Functional Currency',
              ),
              PermissionOperationDef(
                code: 'accounting.currency_rates.view',
                icon: Icons.visibility_outlined,
                labelBuilder: (context) =>
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'عرض أسعار الصرف'
                        : 'View Currency Rates',
              ),
              PermissionOperationDef(
                code: 'accounting.currency_rates.manage',
                icon: Icons.edit_outlined,
                labelBuilder: (context) =>
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'إدارة أسعار الصرف'
                        : 'Manage Currency Rates',
              ),
            ],
          ),
        ],
      );

  @override
  String label(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'العملات وسعر الصرف'
        : 'Currencies & FX';
  }

  @override
  String? description(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'إدارة سجل العملات الرئيسي وسعر الصرف والعملة الوظيفية'
        : 'Currency master data, exchange rates, and functional currency configuration';
  }

  @override
  List<RouteBase> get routes => const [];


  @override
  List<Override> get providerOverrides => [];
}
