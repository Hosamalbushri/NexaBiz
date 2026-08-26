import 'package:flutter/material.dart';

import '../../core/modules/quick_action_definition.dart';
import 'shared/presentation/pages/inventory_routes.dart';

List<QuickActionDefinition> buildInventoryQuickActions(String moduleId) {
  return [
    QuickActionDefinition(
      id: 'quick_action_new_product',
      icon: Icons.add_box_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.moduleInventory,
      subtitleBuilder: (l10n) => l10n.moduleInventoryDescription,
      routePath: InventoryRoutes.productsNew,
      requiredPermissions: const ['inventory.create', 'products.manage'],
    ),
    QuickActionDefinition(
      id: 'quick_action_new_stock_count',
      icon: Icons.fact_check_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.moduleInventory,
      subtitleBuilder: (l10n) => l10n.moduleInventoryDescription,
      routePath: InventoryRoutes.count,
      requiredPermissions: const ['inventory.create', 'products.manage'],
    ),
  ];
}
