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
  static const String reportPreview = '/inventory/stock-count/report-preview';
  static const String stockCountSettings = '/inventory/stock-count/settings';

  /// Products service hub (list / import / barcode).
  static const String products = '/inventory/products';

  static const String productsList = '/inventory/products/list';
  static const String productsNew = '/inventory/products/new';
  static const String productsImport = '/inventory/products/import';
  static const String productsBarcode = '/inventory/products/barcode';
  static const String productsSettings = '/inventory/products/settings';

  static String productsEdit(int id) => '/inventory/products/$id/edit';

  /// Stock Movements service (receipts & issues)
  static const String stockMovements = '/inventory/stock-movements';
  static const String stockReceipts = '/inventory/stock-movements/receipts';
  static const String stockReceiptsNew = '/inventory/stock-movements/receipts/new';
  static const String stockIssues = '/inventory/stock-movements/issues';
  static const String stockIssuesNew = '/inventory/stock-movements/issues/new';

  static void goRoot(BuildContext context) => context.go(root);

  static void goStockCount(BuildContext context) => context.go(stockCount);

  static void goProducts(BuildContext context) => context.go(products);

  static void pushCount(BuildContext context) => context.push(count);

  static void pushCountDetails(BuildContext context) =>
      context.push(countDetails);

  static void pushImport(BuildContext context) => context.push(import);

  static void pushReports(BuildContext context) => context.push(reports);

  static Future<void> pushReportPreview(BuildContext context) async {
    await context.push(reportPreview);
  }

  static void pushProductsList(BuildContext context) =>
      context.push(productsList);

  static void pushProductsNew(BuildContext context) =>
      context.push(productsNew);

  static void pushProductsEdit(BuildContext context, int id) =>
      context.push(productsEdit(id));

  static void pushProductsImport(BuildContext context) =>
      context.push(productsImport);

  static void pushProductsBarcode(BuildContext context) =>
      context.push(productsBarcode);

  static void pushStockReceipts(BuildContext context) =>
      context.push(stockReceipts);

  static void pushStockReceiptDetails(BuildContext context, String id) =>
      context.push('/inventory/stock-movements/receipts/$id');

  static void pushStockReceiptsNew(BuildContext context) =>
      context.push(stockReceiptsNew);

  static void pushStockReceiptsEdit(BuildContext context, String id) =>
      context.push('/inventory/stock-movements/receipts/$id/edit');

  static void pushStockIssues(BuildContext context) =>
      context.push(stockIssues);

  static void pushStockIssueDetails(BuildContext context, String id) =>
      context.push('/inventory/stock-movements/issues/$id');

  static void pushStockIssuesNew(BuildContext context) =>
      context.push(stockIssuesNew);

  static void pushStockIssuesEdit(BuildContext context, String id) =>
      context.push('/inventory/stock-movements/issues/$id/edit');

  /// Multi-Warehouse & Inventory Cost Valuation Settings
  static const String warehousesSettings = '/inventory/warehouses/settings';
  static const String categoriesSettings = '/inventory/categories/settings';
  static const String costValuationSettings = '/inventory/cost-valuation/settings';

  /// Inter-Warehouse Stock Transfers
  static const String stockTransfers = '/inventory/stock-transfers';
  static const String stockTransfersNew = '/inventory/stock-transfers/new';

  static void pushWarehousesSettings(BuildContext context) =>
      context.push(warehousesSettings);

  static void pushCategoriesSettings(BuildContext context) =>
      context.push(categoriesSettings);

  static void pushCostValuationSettings(BuildContext context) =>
      context.push(costValuationSettings);

  static void pushStockTransfers(BuildContext context) =>
      context.push(stockTransfers);

  static void pushStockTransfersNew(BuildContext context) =>
      context.push(stockTransfersNew);
}
