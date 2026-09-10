import 'package:flutter/material.dart';

import '../../core/modules/quick_nav_definition.dart';

List<QuickNavDefinition> buildAccountingQuickNav(String moduleId) {
  return [
    QuickNavDefinition(
      id: 'quick_nav_accounting_journals',
      icon: Icons.book_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'القيود المحاسبية' : 'Journal Entries',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'القيود اليومية والآلية' : 'Manual & automated journals',
      routePath: '/accounting/journals',
      moduleId: moduleId,
      requiredPermissions: const ['accounting.view', 'journals.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_accounting_accounts',
      icon: Icons.account_tree_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'شجرة الحسابات' : 'Chart of Accounts',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'دليل الحسابات المالي' : 'Financial chart of accounts',
      routePath: '/accounting/accounts',
      moduleId: moduleId,
      requiredPermissions: const ['accounting.view', 'accounts.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_accounting_fiscal_years',
      icon: Icons.calendar_today_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'السنوات المالية' : 'Fiscal Years',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'إدارة الفترات وإغلاق السنوات' : 'Manage accounting periods & year closure',
      routePath: '/accounting/fiscal-years',
      moduleId: moduleId,
      requiredPermissions: const ['accounting.view', 'fiscal_years.manage'],
    ),
  ];
}
