import 'package:flutter/material.dart';

import '../../core/modules/quick_action_definition.dart';
import 'shared/presentation/pages/accounting_routes.dart';

List<QuickActionDefinition> buildAccountingQuickActions(String moduleId) {
  return [
    QuickActionDefinition(
      id: 'quick_action_new_journal',
      icon: Icons.note_add_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.moduleAccounting,
      subtitleBuilder: (l10n) => l10n.moduleAccountingDescription,
      routePath: AccountingRoutes.journalsCreate,
      requiredPermissions: const ['accounting.create', 'journals.manage'],
    ),
  ];
}
