import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

PermissionPackageDef accountingPermissionPackage() {
  return PermissionPackageDef(
    id: 'accounting',
    icon: Icons.account_balance_outlined,
    sortOrder: 40,
    titleBuilder: (context) => AppLocalizations.of(context).moduleAccounting,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageAccountingHint,
    services: [
      PermissionServiceDef(
        id: 'accounts',
        icon: Icons.account_balance_wallet_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceChartOfAccounts,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceChartOfAccountsHint,
        operations: [
          StandardPermissionOps.view('accounting.accounts.view'),
          StandardPermissionOps.create('accounting.accounts.create'),
          StandardPermissionOps.update('accounting.accounts.update'),
          StandardPermissionOps.delete('accounting.accounts.delete'),
        ],
      ),
      PermissionServiceDef(
        id: 'journals',
        icon: Icons.menu_book_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceJournals,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceJournalsHint,
        operations: [
          StandardPermissionOps.view('accounting.journals.view'),
          StandardPermissionOps.create('accounting.journals.create'),
          StandardPermissionOps.update('accounting.journals.update'),
          StandardPermissionOps.delete('accounting.journals.delete'),
        ],
      ),
      PermissionServiceDef(
        id: 'currency_rates',
        icon: Icons.currency_exchange_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCurrencyRates,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceCurrencyRatesHint,
        operations: [
          StandardPermissionOps.view('accounting.currency_rates.view'),
          StandardPermissionOps.create('accounting.currency_rates.create'),
          StandardPermissionOps.update('accounting.currency_rates.update'),
          StandardPermissionOps.delete('accounting.currency_rates.delete'),
        ],
      ),
      PermissionServiceDef(
        id: 'voucher_books',
        icon: Icons.book_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceVoucherBooks,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceVoucherBooksHint,
        operations: [
          StandardPermissionOps.view('accounting.voucher_books.view'),
          StandardPermissionOps.create('accounting.voucher_books.create'),
          StandardPermissionOps.update('accounting.voucher_books.update'),
          StandardPermissionOps.delete('accounting.voucher_books.delete'),
        ],
      ),
      PermissionServiceDef(
        id: 'fiscal_years',
        icon: Icons.date_range_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceFiscalYears,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceFiscalYearsHint,
        operations: [
          StandardPermissionOps.view('accounting.fiscal_years.view'),
          StandardPermissionOps.create('accounting.fiscal_years.create'),
          StandardPermissionOps.update('accounting.fiscal_years.update'),
          PermissionOperationDef(
            code: 'accounting.fiscal_years.open_period',
            icon: Icons.lock_open_outlined,
            labelBuilder: (context) =>
                AppLocalizations.of(context).adminPermActionOpenPeriod,
          ),
          PermissionOperationDef(
            code: 'accounting.fiscal_years.close_period',
            icon: Icons.lock_outlined,
            labelBuilder: (context) =>
                AppLocalizations.of(context).adminPermActionClosePeriod,
          ),
          PermissionOperationDef(
            code: 'accounting.fiscal_years.reopen_period',
            icon: Icons.restart_alt_outlined,
            labelBuilder: (context) =>
                AppLocalizations.of(context).adminPermActionReopenPeriod,
          ),
          PermissionOperationDef(
            code: 'accounting.fiscal_years.configure_fx',
            icon: Icons.currency_exchange_outlined,
            labelBuilder: (context) =>
                AppLocalizations.of(context).adminPermActionConfigureFx,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'reports',
        icon: Icons.assessment_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceAccountingReports,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceAccountingReportsHint,
        operations: [
          StandardPermissionOps.view('accounting.reports.view'),
        ],
      ),
    ],
  );
}
