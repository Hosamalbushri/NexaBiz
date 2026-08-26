import 'package:flutter/material.dart';

import '../../core/modules/quick_action_definition.dart';
import 'shared/presentation/pages/receipts_payments_routes.dart';

List<QuickActionDefinition> buildReceiptsPaymentsQuickActions(String moduleId) {
  return [
    QuickActionDefinition(
      id: 'create_receipt',
      icon: Icons.payments_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.rpServiceReceiptsTitle,
      subtitleBuilder: (l10n) => l10n.rpServiceReceiptsSubtitle,
      routePath: ReceiptsPaymentsRoutes.createReceipt,
      requiredPermissions: const ['receipts.create', 'receipts_payments.sync'],
    ),
    QuickActionDefinition(
      id: 'create_payment',
      icon: Icons.outbox_outlined,
      kind: QuickActionKind.route,
      titleBuilder: (l10n) => l10n.rpServicePaymentsTitle,
      subtitleBuilder: (l10n) => l10n.rpServicePaymentsSubtitle,
      routePath: ReceiptsPaymentsRoutes.createPayment,
      requiredPermissions: const ['payments.create', 'receipts_payments.sync'],
    ),
  ];
}
