import 'package:flutter/material.dart';

import '../../core/modules/quick_nav_definition.dart';

List<QuickNavDefinition> buildSalesQuickNav(String moduleId) {
  return [
    QuickNavDefinition(
      id: 'quick_nav_sales',
      icon: Icons.shopping_bag_outlined,
      titleBuilder: (l10n) => l10n.moduleSales,
      subtitleBuilder: (l10n) => l10n.moduleSalesDescription,
      routePath: '/sales',
      requiredPermissions: const ['sales.view', 'invoices.manage'],
    ),
  ];
}
