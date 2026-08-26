import 'package:flutter/material.dart';

import '../../core/modules/module_settings_definition.dart';
import 'shared/presentation/pages/customers_routes.dart';

List<ModuleSettingsCategoryDefinition> buildCustomersSettingsCategories(String moduleId) {
  return [
    ModuleSettingsCategoryDefinition(
      id: 'customers_settings_cat',
      moduleId: moduleId,
      icon: Icons.people_outline,
      titleBuilder: (l10n) => l10n.customersSettingsTitle,
      subtitleBuilder: (l10n) => l10n.customersSettingsSubtitle,
      items: [
        ModuleSettingsItemDefinition(
          id: 'customers_parent_account_setting',
          moduleId: moduleId,
          icon: Icons.account_tree_outlined,
          path: CustomersRoutes.parentAccountSettings,
          titleBuilder: (l10n) => l10n.customersParentAccountSectionTitle,
          subtitleBuilder: (l10n) => l10n.customersParentAccountSectionSubtitle,
        ),
        ModuleSettingsItemDefinition(
          id: 'customers_hub_setting',
          moduleId: moduleId,
          icon: Icons.tune_outlined,
          path: CustomersRoutes.settings,
          titleBuilder: (l10n) => l10n.customersSettingsTitle,
          subtitleBuilder: (l10n) => l10n.customersSettingsSubtitle,
        ),
      ],
    ),
  ];
}
