import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

PermissionPackageDef reportsPermissionPackage() {
  return PermissionPackageDef(
    id: 'reports',
    icon: Icons.assessment_outlined,
    sortOrder: 50,
    titleBuilder: (context) => AppLocalizations.of(context).moduleReports,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageReportsHint,
    services: [
      PermissionServiceDef(
        id: 'sales_period',
        icon: Icons.date_range_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceSalesPeriod,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceSalesPeriodHint,
        operations: [
          StandardPermissionOps.view(
            'reports.sales_period.view',
            legacyCodes: const ['reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.sales_period.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'account_statement',
        icon: Icons.receipt_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceAccountStatement,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceAccountStatementHint,
        operations: [
          StandardPermissionOps.view(
            'reports.account_statement.view',
            legacyCodes: const ['reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.account_statement.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'trial_balance',
        icon: Icons.balance_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceTrialBalance,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceTrialBalanceHint,
        operations: [
          StandardPermissionOps.view(
            'reports.trial_balance.view',
            legacyCodes: const ['reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.trial_balance.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'journal_book',
        icon: Icons.receipt_long_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceJournalBook,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceJournalBookHint,
        operations: [
          StandardPermissionOps.view(
            'reports.journal_book.view',
            legacyCodes: const ['reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.journal_book.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'general_ledger',
        icon: Icons.book_outlined,
        titleBuilder: (context) => 'الأستاذ العام',
        subtitleBuilder: (context) => 'صلاحية عرض ودفتر الأستاذ العام',
        operations: [
          StandardPermissionOps.view(
            'reports.general_ledger.view',
            legacyCodes: const ['reports.view', 'financial_reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.general_ledger.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'income_statement',
        icon: Icons.trending_up_outlined,
        titleBuilder: (context) => 'قائمة الدخل',
        subtitleBuilder: (context) => 'صلاحية عرض الأرباح والخسائر',
        operations: [
          StandardPermissionOps.view(
            'reports.income_statement.view',
            legacyCodes: const ['reports.view', 'financial_reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.income_statement.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'balance_sheet',
        icon: Icons.account_balance_outlined,
        titleBuilder: (context) => 'الميزانية العمومية',
        subtitleBuilder: (context) => 'صلاحية عرض الميزانية العمومية',
        operations: [
          StandardPermissionOps.view(
            'reports.balance_sheet.view',
            legacyCodes: const ['reports.view', 'financial_reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.balance_sheet.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'receivables_payables',
        icon: Icons.swap_horiz_outlined,
        titleBuilder: (context) => 'كشف الذمم',
        subtitleBuilder: (context) => 'صلاحية عرض ذمم العملاء والموردين',
        operations: [
          StandardPermissionOps.view(
            'reports.receivables_payables.view',
            legacyCodes: const ['reports.view', 'financial_reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.receivables_payables.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'cash_flow',
        icon: Icons.water_drop_outlined,
        titleBuilder: (context) => 'التدفقات النقدية',
        subtitleBuilder: (context) => 'صلاحية عرض التدفقات النقدية',
        operations: [
          StandardPermissionOps.view(
            'reports.cash_flow.view',
            legacyCodes: const ['reports.view', 'financial_reports.view'],
          ),
          StandardPermissionOps.exportOp('reports.cash_flow.export'),
        ],
      ),
    ],
  );
}
