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
        ModuleSettingsItemDefinition(
          id: 'inventory_categories_settings',
          moduleId: moduleId,
          icon: Icons.account_tree_outlined,
          path: InventoryRoutes.categoriesSettings,
          titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'شجرة تصنيفات المخزون' : 'Inventory Category Tree',
          subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'إدارة شجرة التصنيفات المرتبطة بالمستودعات ووراثة طرق احتساب التكلفة' : 'Manage warehouse-rooted category tree & cost valuation inheritance',
        ),
        ModuleSettingsItemDefinition(
          id: 'inventory_warehouses_settings',
          moduleId: moduleId,
          icon: Icons.warehouse_outlined,
          path: InventoryRoutes.warehousesSettings,
          titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'إدارة المستودعات' : 'Warehouses Management',
          subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'تهيئة المستودعات الرئيسية والفروع وتحديد المستودع الافتراضي' : 'Manage main warehouses, branches, and set default location',
        ),
        ModuleSettingsItemDefinition(
          id: 'inventory_cost_valuation_settings',
          moduleId: moduleId,
          icon: Icons.monetization_on_outlined,
          path: InventoryRoutes.costValuationSettings,
          titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'تقييم تكلفة المخزون' : 'Inventory Cost Valuation',
          subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'اختيار طريقة احتساب التكلفة (FIFO, LIFO, المتوسط المرجح)' : 'Select valuation method (FIFO, LIFO, Weighted Average)',
        ),
      ],
    ),
  ];
}
