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

  /// Products service hub (list / import / barcode).
  static const String products = '/inventory/products';

  static const String productsList = '/inventory/products/list';
  static const String productsNew = '/inventory/products/new';
  static const String productsImport = '/inventory/products/import';
  static const String productsBarcode = '/inventory/products/barcode';

  static String productsEdit(int id) => '/inventory/products/$id/edit';

  static void goRoot(BuildContext context) => context.go(root);

  static void goStockCount(BuildContext context) => context.go(stockCount);

  static void goProducts(BuildContext context) => context.go(products);

  static void pushCount(BuildContext context) => context.push(count);

  static void pushCountDetails(BuildContext context) =>
      context.push(countDetails);

  static void pushImport(BuildContext context) => context.push(import);

  static void pushReports(BuildContext context) => context.push(reports);

  static void pushProductsList(BuildContext context) =>
      context.push(productsList);

  static void pushProductsNew(BuildContext context) => context.push(productsNew);

  static void pushProductsEdit(BuildContext context, int id) =>
      context.push(productsEdit(id));

  static void pushProductsImport(BuildContext context) =>
      context.push(productsImport);

  static void pushProductsBarcode(BuildContext context) =>
      context.push(productsBarcode);
}
