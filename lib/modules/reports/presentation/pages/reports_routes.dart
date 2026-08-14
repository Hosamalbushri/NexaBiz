import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Routes owned by the Reports module.
class ReportsRoutes {
  const ReportsRoutes._();

  static const String root = '/module-reports';
  static const String salesPeriod = '/module-reports/sales-period';
  static const String accountStatement = '/module-reports/account-statement';
  static const String preview = '/module-reports/preview';

  static void goRoot(BuildContext context) => context.go(root);

  static void pushSalesPeriod(BuildContext context) =>
      context.push(salesPeriod);

  static void pushAccountStatement(BuildContext context) =>
      context.push(accountStatement);

  static void pushPreview(BuildContext context) => context.push(preview);
}
