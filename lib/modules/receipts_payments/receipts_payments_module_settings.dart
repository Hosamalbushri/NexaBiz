import 'package:flutter/material.dart';

import '../../core/modules/module_settings_definition.dart';
import 'shared/presentation/pages/receipts_payments_routes.dart';

List<ModuleSettingsCategoryDefinition> buildReceiptsPaymentsSettingsCategories(String moduleId) {
  return [
    ModuleSettingsCategoryDefinition(
      id: 'rp_settings_cat',
      moduleId: moduleId,
      icon: Icons.account_balance_wallet_outlined,
      titleBuilder: (l10n) => l10n.moduleReceiptsPayments,
      subtitleBuilder: (l10n) => l10n.moduleReceiptsPaymentsDescription,
      items: [
        ModuleSettingsItemDefinition(
          id: 'rp_posting_setting',
          moduleId: moduleId,
          icon: Icons.published_with_changes_outlined,
          path: ReceiptsPaymentsRoutes.postingService,
          titleBuilder: (l10n) => l10n.moduleReceiptsPayments,
          subtitleBuilder: (l10n) => l10n.moduleReceiptsPaymentsDescription,
        ),
      ],
    ),
  ];
}
