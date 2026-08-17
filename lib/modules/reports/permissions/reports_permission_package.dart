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
    ],
  );
}
