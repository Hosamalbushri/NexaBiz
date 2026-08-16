import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import 'domain/entities/transaction_type.dart';
import 'permissions/receipts_payments_permission_package.dart';
import 'presentation/pages/financial_transaction_details_page.dart';
import 'presentation/pages/financial_transaction_form_page.dart';
import 'presentation/pages/receipts_payments_home_page.dart';
import 'presentation/pages/receipts_payments_list_page.dart';
import 'presentation/pages/receipts_payments_routes.dart';
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
          pathRegex: RegExp(r'^/receipts-payments/\d+/edit$'),
          anyOf: [
            ...ReceiptsPaymentsPermissions.receiptsUpdate,
            ...ReceiptsPaymentsPermissions.paymentsUpdate,
          ],
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
  List<RouteBase> get routes => [
        GoRoute(
          path: ReceiptsPaymentsRoutes.root,
          name: 'receiptsPayments',
          builder: (context, state) => const ReceiptsPaymentsHomePage(),
          routes: [
            GoRoute(
              path: 'list',
              name: 'receiptsPaymentsList',
              builder: (context, state) {
                final typeParam = state.uri.queryParameters['type'];
                final type = typeParam == null
                    ? null
                    : TransactionTypeX.fromStorage(typeParam);
                return ReceiptsPaymentsListPage(initialType: type);
              },
            ),
            GoRoute(
              path: 'receipts',
              name: 'receiptsService',
              builder: (context, state) => const RpServiceMenuPage(
                type: TransactionType.receipt,
              ),
              routes: [
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
                  path: 'create',
                  name: 'paymentsCreate',
                  builder: (context, state) => const FinancialTransactionFormPage(
                    transactionType: TransactionType.payment,
                  ),
                ),
              ],
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
