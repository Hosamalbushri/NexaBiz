import 'package:flutter/material.dart';

import '../../core/modules/quick_nav_definition.dart';

List<QuickNavDefinition> buildReceiptsPaymentsQuickNav(String moduleId) {
  return [
    QuickNavDefinition(
      id: 'quick_nav_receipts',
      icon: Icons.call_received_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'سندات القبض' : 'Receipt Vouchers',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'استلام ونقدية وحسابات' : 'Cash & bank receipts',
      routePath: '/receipts-payments/receipts',
      moduleId: moduleId,
      requiredPermissions: const ['receipts_payments.view', 'receipts.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_payments',
      icon: Icons.call_made_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'سندات الصرف' : 'Payment Vouchers',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'صرف ونقدية وحسابات' : 'Cash & bank payments',
      routePath: '/receipts-payments/payments',
      moduleId: moduleId,
      requiredPermissions: const ['receipts_payments.view', 'payments.manage'],
    ),
  ];
}
