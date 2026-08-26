import 'package:flutter/material.dart';

import '../../core/modules/module_settings_definition.dart';
import 'shared/presentation/pages/sales_routes.dart';

List<ModuleSettingsCategoryDefinition> buildSalesSettingsCategories(String moduleId) {
  return [
    ModuleSettingsCategoryDefinition(
      id: 'sales_settings_cat',
      moduleId: moduleId,
      icon: Icons.point_of_sale_outlined,
      titleBuilder: (l10n) => l10n.moduleSales,
      subtitleBuilder: (l10n) => l10n.moduleSalesDescription,
      items: [
        ModuleSettingsItemDefinition(
          id: 'sales_invoices_settings',
          moduleId: moduleId,
          icon: Icons.receipt_long_outlined,
          path: SalesRoutes.root,
          titleBuilder: (l10n) => l10n.moduleSales,
          subtitleBuilder: (l10n) => l10n.moduleSalesDescription,
        ),
      ],
    ),
  ];
}
