import 'package:flutter/material.dart';

import '../../core/modules/module_settings_definition.dart';
import 'shared/presentation/pages/accounting_routes.dart';

List<ModuleSettingsCategoryDefinition> buildAccountingSettingsCategories(String moduleId) {
  return [
    ModuleSettingsCategoryDefinition(
      id: 'accounting_settings_cat',
      moduleId: moduleId,
      icon: Icons.account_tree_outlined,
      titleBuilder: (l10n) => l10n.moduleAccounting,
      subtitleBuilder: (l10n) => l10n.moduleAccountingDescription,
      items: [
        ModuleSettingsItemDefinition(
          id: 'accounting_chart_settings',
          moduleId: moduleId,
          icon: Icons.account_balance_outlined,
          path: AccountingRoutes.accounts,
          titleBuilder: (l10n) => l10n.moduleAccounting,
          subtitleBuilder: (l10n) => l10n.moduleAccountingDescription,
        ),
        ModuleSettingsItemDefinition(
          id: 'accounting_fiscal_years_settings',
          moduleId: moduleId,
          icon: Icons.date_range_outlined,
          path: AccountingRoutes.fiscalYears,
          titleBuilder: (l10n) => l10n.moduleAccounting,
          subtitleBuilder: (l10n) => l10n.moduleAccountingDescription,
        ),
      ],
    ),
  ];
}
