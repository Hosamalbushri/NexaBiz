import 'package:flutter/material.dart';

import '../../core/modules/quick_action_definition.dart';
import 'shared/presentation/pages/sales_routes.dart';

List<QuickActionDefinition> buildSalesQuickActions(String moduleId) {
  return [
    QuickActionDefinition(
      id: 'quick_action_new_sale',
      icon: Icons.add_shopping_cart_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.moduleSales,
      subtitleBuilder: (l10n) => l10n.moduleSalesDescription,
      routePath: SalesRoutes.create,
      requiredPermissions: const ['sales.create', 'invoices.manage'],
    ),
  ];
}
