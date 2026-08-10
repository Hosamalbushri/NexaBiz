import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths owned by the Inventory module.
class InventoryRoutes {
  const InventoryRoutes._();

  static const String root = '/inventory';

  /// Stock-count service hub (grid of count / import / reports).
  static const String stockCount = '/inventory/stock-count';

  /// Stock-count entry — product search / counting.
  static const String count = '/inventory/stock-count/count';

  /// Selected product count / details screen.
  static const String countDetails = '/inventory/stock-count/count/details';

  /// Alias kept for older call sites; same as [count].
  static const String search = count;

  static const String import = '/inventory/stock-count/import';
  static const String reports = '/inventory/stock-count/reports';

  static void goRoot(BuildContext context) => context.go(root);

  static void goStockCount(BuildContext context) => context.go(stockCount);

  static void pushCount(BuildContext context) => context.push(count);

  static void pushCountDetails(BuildContext context) =>
      context.push(countDetails);

  static void pushImport(BuildContext context) => context.push(import);

  static void pushReports(BuildContext context) => context.push(reports);
}
