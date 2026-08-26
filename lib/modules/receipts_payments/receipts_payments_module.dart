import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/report_category_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import 'domain/entities/transaction_type.dart';
import 'permissions/receipts_payments_permission_package.dart';
import 'presentation/pages/cash_box_transfer_form_page.dart';
import 'presentation/pages/currency_exchange_form_page.dart';
import 'presentation/pages/financial_transaction_details_page.dart';
import 'presentation/pages/financial_transaction_form_page.dart';
import 'presentation/pages/receipts_payments_home_page.dart';
import 'presentation/pages/receipts_payments_list_page.dart';
import 'presentation/pages/receipts_payments_routes.dart';
import 'presentation/pages/rp_posting_service_page.dart';
import 'presentation/pages/rp_service_menu_page.dart';

class ReceiptsPaymentsModule extends AppModule {
  const ReceiptsPaymentsModule();

  static const String moduleId = 'receipts_payments';

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleReceiptsPayments';

  @override
  IconData get icon => Icons.account_balance_wallet_outlined;

  @override
  String get rootRoute => ReceiptsPaymentsRoutes.root;

  @override
  int get sortOrder => 40;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => ReceiptsPaymentsPermissions.anyView;

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathEquals: ReceiptsPaymentsRoutes.createReceipt,
          anyOf: ReceiptsPaymentsPermissions.receiptsCreate,
        ),
        RouteAccessRule(
          pathEquals: ReceiptsPaymentsRoutes.createPayment,
          anyOf: ReceiptsPaymentsPermissions.paymentsCreate,
        ),
        RouteAccessRule(
          pathEquals: ReceiptsPaymentsRoutes.createTransfer,
          anyOf: ReceiptsPaymentsPermissions.transfersCreate,
        ),
        RouteAccessRule(
          pathEquals: ReceiptsPaymentsRoutes.createExchange,
          anyOf: ReceiptsPaymentsPermissions.exchangesCreate,
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/receipts-payments/transfers/\d+/edit$'),
          anyOf: ReceiptsPaymentsPermissions.transfersUpdate,
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/receipts-payments/exchanges/\d+/edit$'),
          anyOf: ReceiptsPaymentsPermissions.exchangesUpdate,
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/receipts-payments/\d+/edit$'),
          anyOf: [
            ...ReceiptsPaymentsPermissions.receiptsUpdate,
            ...ReceiptsPaymentsPermissions.paymentsUpdate,
          ],
        ),
        RouteAccessRule(
          pathEquals: ReceiptsPaymentsRoutes.postingService,
          anyOf: ReceiptsPaymentsPermissions.anyPost,
        ),
        RouteAccessRule(
          pathPrefix: ReceiptsPaymentsRoutes.root,
          anyOf: ReceiptsPaymentsPermissions.anyView,
        ),
      ];

  @override
  PermissionPackageDef? get permissionPackage =>
      receiptsPaymentsPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleReceiptsPayments;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleReceiptsPaymentsDescription;
  }

  @override
  List<QuickActionDefinition> get quickActions => [
        QuickActionDefinition(
          id: 'create_receipt',
          icon: Icons.payments_outlined,
          kind: QuickActionKind.route,
          routePath: ReceiptsPaymentsRoutes.createReceipt,
          titleBuilder: (l10n) => l10n.rpServiceCreateReceipt,
          subtitleBuilder: (l10n) => l10n.rpCreateReceiptSubtitle,
          requiredPermissions: const ['receipts.create', 'receipts_payments.sync'],
        ),
        QuickActionDefinition(
          id: 'create_payment',
          icon: Icons.outbox_outlined,
          kind: QuickActionKind.route,
          routePath: ReceiptsPaymentsRoutes.createPayment,
          titleBuilder: (l10n) => l10n.rpServiceCreatePayment,
          subtitleBuilder: (l10n) => l10n.rpCreatePaymentSubtitle,
          requiredPermissions: const ['payments.create', 'receipts_payments.sync'],
        ),
      ];

  @override
  List<ReportCategoryDefinition> get reportCategories => [
        ReportCategoryDefinition(
          id: 'rp_reports',
          moduleId: moduleId,
          icon: Icons.account_balance_wallet_outlined,
          titleBuilder: (l10n) => l10n.moduleReceiptsPayments,
          subtitleBuilder: (l10n) => l10n.moduleReceiptsPaymentsDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_rp_receipts',
              moduleId: moduleId,
              icon: Icons.payments_outlined,
              path: '/reports/rp-receipts',
              titleBuilder: (l10n) => l10n.rpServiceReceiptsTitle,
              subtitleBuilder: (l10n) => l10n.rpServiceReceiptsSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_rp_payments',
              moduleId: moduleId,
              icon: Icons.outbox_outlined,
              path: '/reports/rp-payments',
              titleBuilder: (l10n) => l10n.rpServicePaymentsTitle,
              subtitleBuilder: (l10n) => l10n.rpServicePaymentsSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_rp_transfers',
              moduleId: moduleId,
              icon: Icons.swap_horiz_outlined,
              path: '/reports/rp-cash-movement',
              titleBuilder: (l10n) => l10n.rpServiceTransfersTitle,
              subtitleBuilder: (l10n) => l10n.rpServiceTransfersSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_rp_exchanges',
              moduleId: moduleId,
              icon: Icons.currency_exchange_outlined,
              path: '/reports/rp-daily-summary',
              titleBuilder: (l10n) => l10n.rpServiceExchangesTitle,
              subtitleBuilder: (l10n) => l10n.rpServiceExchangesSubtitle,
            ),
          ],
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: ReceiptsPaymentsRoutes.root,
          name: 'receiptsPayments',
          builder: (context, state) => const ReceiptsPaymentsHomePage(),
          routes: [
            GoRoute(
              path: 'receipts',
              name: 'receiptsService',
              builder: (context, state) => const RpServiceMenuPage(
                type: TransactionType.receipt,
              ),
              routes: [
                GoRoute(
                  path: 'list',
                  name: 'receiptsList',
                  builder: (context, state) => const ReceiptsPaymentsListPage(
                    transactionType: TransactionType.receipt,
                  ),
                ),
                GoRoute(
                  path: 'create',
                  name: 'receiptsCreate',
                  builder: (context, state) => const FinancialTransactionFormPage(
                    transactionType: TransactionType.receipt,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'payments',
              name: 'paymentsService',
              builder: (context, state) => const RpServiceMenuPage(
                type: TransactionType.payment,
              ),
              routes: [
                GoRoute(
                  path: 'list',
                  name: 'paymentsList',
                  builder: (context, state) => const ReceiptsPaymentsListPage(
                    transactionType: TransactionType.payment,
                  ),
                ),
                GoRoute(
                  path: 'create',
                  name: 'paymentsCreate',
                  builder: (context, state) => const FinancialTransactionFormPage(
                    transactionType: TransactionType.payment,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'transfers',
              name: 'transfersService',
              builder: (context, state) => const RpServiceMenuPage(
                type: TransactionType.transfer,
              ),
              routes: [
                GoRoute(
                  path: 'list',
                  name: 'transfersList',
                  builder: (context, state) => const ReceiptsPaymentsListPage(
                    transactionType: TransactionType.transfer,
                  ),
                ),
                GoRoute(
                  path: 'create',
                  name: 'transfersCreate',
                  builder: (context, state) =>
                      const CashBoxTransferFormPage(),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: 'transfersEdit',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    return CashBoxTransferFormPage(transactionId: id ?? -1);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'exchanges',
              name: 'exchangesService',
              builder: (context, state) => const RpServiceMenuPage(
                type: TransactionType.currencyExchange,
              ),
              routes: [
                GoRoute(
                  path: 'list',
                  name: 'exchangesList',
                  builder: (context, state) => const ReceiptsPaymentsListPage(
                    transactionType: TransactionType.currencyExchange,
                  ),
                ),
                GoRoute(
                  path: 'create',
                  name: 'exchangesCreate',
                  builder: (context, state) =>
                      const CurrencyExchangeFormPage(),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: 'exchangesEdit',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    return CurrencyExchangeFormPage(transactionId: id ?? -1);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'posting',
              name: 'receiptsPaymentsPosting',
              builder: (context, state) => const RpPostingServicePage(),
            ),
            GoRoute(
              path: ':id',
              name: 'receiptsPaymentsDetails',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                return FinancialTransactionDetailsPage(transactionId: id ?? -1);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'receiptsPaymentsEdit',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    return FinancialTransactionFormPage(
                      transactionId: id ?? -1,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ];
}
