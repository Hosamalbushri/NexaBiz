import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Routes owned by the Reports module.
class ReportsRoutes {
  const ReportsRoutes._();

  static const String root = '/module-reports';
  static const String salesPeriod = '/module-reports/sales-period';
  static const String accountStatement = '/module-reports/account-statement';
  static const String rpReceipts = '/module-reports/rp-receipts';
  static const String rpPayments = '/module-reports/rp-payments';
  static const String rpCashMovement = '/module-reports/rp-cash-movement';
  static const String rpBankMovement = '/module-reports/rp-bank-movement';
  static const String rpCustomerReceipts =
      '/module-reports/rp-customer-receipts';
  static const String rpDailySummary = '/module-reports/rp-daily-summary';
  static const String rpPeriodSummary = '/module-reports/rp-period-summary';
  static const String preview = '/module-reports/preview';

  static void goRoot(BuildContext context) => context.go(root);

  static void pushSalesPeriod(BuildContext context) =>
      context.push(salesPeriod);

  static void pushAccountStatement(BuildContext context) =>
      context.push(accountStatement);

  static void pushPreview(BuildContext context) => context.push(preview);
}
