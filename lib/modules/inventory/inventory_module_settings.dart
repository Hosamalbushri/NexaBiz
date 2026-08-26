import 'package:flutter/material.dart';

import '../../core/modules/module_settings_definition.dart';
import 'shared/presentation/pages/inventory_routes.dart';

List<ModuleSettingsCategoryDefinition> buildInventorySettingsCategories(String moduleId) {
  return [
    ModuleSettingsCategoryDefinition(
      id: 'inventory_settings_cat',
      moduleId: moduleId,
      icon: Icons.inventory_2_outlined,
      titleBuilder: (l10n) => l10n.moduleInventory,
      subtitleBuilder: (l10n) => l10n.moduleInventoryDescription,
      items: [
        ModuleSettingsItemDefinition(
          id: 'inventory_catalog_settings',
          moduleId: moduleId,
          icon: Icons.category_outlined,
          path: InventoryRoutes.productsSettings,
          titleBuilder: (l10n) => l10n.productSettingsTitle,
          subtitleBuilder: (l10n) => l10n.productSettingsSubtitle,
        ),
        ModuleSettingsItemDefinition(
          id: 'inventory_sessions_settings',
          moduleId: moduleId,
          icon: Icons.fact_check_outlined,
          path: InventoryRoutes.stockCountSettings,
          titleBuilder: (l10n) => l10n.stockCountSettingsTitle,
          subtitleBuilder: (l10n) => l10n.stockCountSettingsSubtitle,
        ),
      ],
    ),
  ];
}
