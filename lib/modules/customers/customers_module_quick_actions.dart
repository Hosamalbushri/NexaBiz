import 'package:flutter/material.dart';

import '../../core/modules/quick_action_definition.dart';
import 'shared/presentation/pages/customers_routes.dart';

List<QuickActionDefinition> buildCustomersQuickActions(String moduleId) {
  return [
    QuickActionDefinition(
      id: 'quick_action_new_customer',
      icon: Icons.person_add_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.moduleCustomers,
      subtitleBuilder: (l10n) => l10n.moduleCustomersDescription,
      routePath: CustomersRoutes.create,
      requiredPermissions: const ['customers.create', 'customers.manage'],
    ),
  ];
}
