import 'package:flutter/material.dart';

import '../../core/modules/quick_nav_definition.dart';

List<QuickNavDefinition> buildCustomersQuickNav(String moduleId) {
  return [
    QuickNavDefinition(
      id: 'quick_nav_customers',
      icon: Icons.people_outline,
      titleBuilder: (l10n) => l10n.moduleCustomers,
      subtitleBuilder: (l10n) => l10n.moduleCustomersDescription,
      routePath: '/customers',
      requiredPermissions: const ['customers.view'],
    ),
  ];
}
