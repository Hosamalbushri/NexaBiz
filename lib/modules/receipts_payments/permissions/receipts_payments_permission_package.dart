import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';

export 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart' show TransactionType;

abstract final class ReceiptsPaymentsPermissions {
  static const receiptsView = ['receipts.view'];
  static const receiptsCreate = ['receipts.create'];
  static const receiptsUpdate = ['receipts.update'];
  static const receiptsPost = ['receipts.post'];
  static const receiptsCancel = ['receipts.cancel'];

  static const paymentsView = ['payments.view'];
  static const paymentsCreate = ['payments.create'];
  static const paymentsUpdate = ['payments.update'];
  static const paymentsPost = ['payments.post'];
  static const paymentsCancel = ['payments.cancel'];

  static const transfersView = ['transfers.view'];
  static const transfersCreate = ['transfers.create'];
  static const transfersUpdate = ['transfers.update'];
  static const transfersPost = ['transfers.post'];
  static const transfersCancel = ['transfers.cancel'];

  static const exchangesView = ['exchanges.view'];
  static const exchangesCreate = ['exchanges.create'];
  static const exchangesUpdate = ['exchanges.update'];
  static const exchangesPost = ['exchanges.post'];
  static const exchangesCancel = ['exchanges.cancel'];

  static const anyView = [
    'receipts.view',
    'payments.view',
    'transfers.view',
    'exchanges.view',
  ];
  static const anyPost = [
    'receipts.post',
    'payments.post',
    'transfers.post',
    'exchanges.post',
  ];
  static const reportsView = ['receipts_payments.reports.view'];
  static const reportsExport = ['receipts_payments.reports.export'];
  static const sync = ['receipts_payments.sync'];

  static List<String> createFor(TransactionType type) => switch (type) {
        TransactionType.receipt => receiptsCreate,
        TransactionType.payment => paymentsCreate,
        TransactionType.transfer => transfersCreate,
        TransactionType.currencyExchange => exchangesCreate,
      };

  static List<String> updateFor(TransactionType type) => switch (type) {
        TransactionType.receipt => receiptsUpdate,
        TransactionType.payment => paymentsUpdate,
        TransactionType.transfer => transfersUpdate,
        TransactionType.currencyExchange => exchangesUpdate,
      };

  static List<String> postFor(TransactionType type) => switch (type) {
        TransactionType.receipt => receiptsPost,
        TransactionType.payment => paymentsPost,
        TransactionType.transfer => transfersPost,
        TransactionType.currencyExchange => exchangesPost,
      };

  static List<String> cancelFor(TransactionType type) => switch (type) {
        TransactionType.receipt => receiptsCancel,
        TransactionType.payment => paymentsCancel,
        TransactionType.transfer => transfersCancel,
        TransactionType.currencyExchange => exchangesCancel,
      };
}

PermissionPackageDef receiptsPaymentsPermissionPackage() {
  return PermissionPackageDef(
    id: 'receipts_payments',
    icon: Icons.account_balance_wallet_outlined,
    sortOrder: 25,
    titleBuilder: (context) =>
        AppLocalizations.of(context).moduleReceiptsPayments,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageReceiptsPaymentsHint,
    services: [
      PermissionServiceDef(
        id: 'receipts',
        icon: Icons.call_received_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceReceipts,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceReceiptsHint,
        operations: [
          StandardPermissionOps.view('receipts.view'),
          StandardPermissionOps.create('receipts.create'),
          StandardPermissionOps.update('receipts.update'),
          StandardPermissionOps.custom(
            code: 'receipts.post',
            icon: Icons.check_circle_outline,
            label: (l10n) => l10n.adminPermActionPost,
          ),
          StandardPermissionOps.custom(
            code: 'receipts.cancel',
            icon: Icons.cancel_outlined,
            label: (l10n) => l10n.adminPermActionCancel,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'payments',
        icon: Icons.call_made_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServicePayments,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServicePaymentsHint,
        operations: [
          StandardPermissionOps.view('payments.view'),
          StandardPermissionOps.create('payments.create'),
          StandardPermissionOps.update('payments.update'),
          StandardPermissionOps.custom(
            code: 'payments.post',
            icon: Icons.check_circle_outline,
            label: (l10n) => l10n.adminPermActionPost,
          ),
          StandardPermissionOps.custom(
            code: 'payments.cancel',
            icon: Icons.cancel_outlined,
            label: (l10n) => l10n.adminPermActionCancel,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'transfers',
        icon: Icons.swap_horiz_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceTransfers,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceTransfersHint,
        operations: [
          StandardPermissionOps.view('transfers.view'),
          StandardPermissionOps.create('transfers.create'),
          StandardPermissionOps.update('transfers.update'),
          StandardPermissionOps.custom(
            code: 'transfers.post',
            icon: Icons.check_circle_outline,
            label: (l10n) => l10n.adminPermActionPost,
          ),
          StandardPermissionOps.custom(
            code: 'transfers.cancel',
            icon: Icons.cancel_outlined,
            label: (l10n) => l10n.adminPermActionCancel,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'exchanges',
        icon: Icons.currency_exchange_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceExchanges,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceExchangesHint,
        operations: [
          StandardPermissionOps.view('exchanges.view'),
          StandardPermissionOps.create('exchanges.create'),
          StandardPermissionOps.update('exchanges.update'),
          StandardPermissionOps.custom(
            code: 'exchanges.post',
            icon: Icons.check_circle_outline,
            label: (l10n) => l10n.adminPermActionPost,
          ),
          StandardPermissionOps.custom(
            code: 'exchanges.cancel',
            icon: Icons.cancel_outlined,
            label: (l10n) => l10n.adminPermActionCancel,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'reports',
        icon: Icons.assessment_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceRpReports,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceRpReportsHint,
        operations: [
          StandardPermissionOps.view('receipts_payments.reports.view'),
          StandardPermissionOps.exportOp('receipts_payments.reports.export'),
        ],
      ),
      PermissionServiceDef(
        id: 'sync',
        icon: Icons.sync_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceRpSync,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceRpSyncHint,
        operations: [
          StandardPermissionOps.custom(
            code: 'receipts_payments.sync',
            icon: Icons.sync_outlined,
            label: (l10n) => l10n.adminPermActionSync,
          ),
        ],
      ),
    ],
  );
}
