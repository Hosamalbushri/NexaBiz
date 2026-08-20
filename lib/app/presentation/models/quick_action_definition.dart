import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../../modules/inventory/presentation/pages/inventory_routes.dart';
import '../../../modules/sales/presentation/pages/sales_routes.dart';
import '../../../modules/customers/presentation/pages/customers_routes.dart';
import '../../../modules/receipts_payments/presentation/pages/receipts_payments_routes.dart';

/// How a quick action is executed.
enum QuickActionKind { route }

/// Maximum number of pinned quick actions on the shell add sheet.
const int kMaxQuickActions = 9;

/// A platform quick-action shortcut offered in the shell add sheet.
@immutable
class QuickActionDefinition {
  const QuickActionDefinition({
    required this.id,
    required this.icon,
    required this.kind,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.routePath,
  });

  final String id;
  final IconData icon;
  final QuickActionKind kind;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  /// Used when [kind] is [QuickActionKind.route].
  final String? routePath;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);
}

/// Full catalog of quick actions. Order here is the catalog display order.
List<QuickActionDefinition> quickActionCatalog() {
  return const [
    QuickActionDefinition(
      id: 'scan_barcode',
      icon: Icons.qr_code_scanner_outlined,
      kind: QuickActionKind.route,
      routePath: '/inventory/products/barcode?scan=1',
      titleBuilder: _scanBarcodeTitle,
      subtitleBuilder: _scanBarcodeSubtitle,
    ),
    QuickActionDefinition(
      id: 'create_sale',
      icon: Icons.receipt_long_outlined,
      kind: QuickActionKind.route,
      routePath: SalesRoutes.create,
      titleBuilder: _createSaleTitle,
      subtitleBuilder: _createSaleSubtitle,
    ),
    QuickActionDefinition(
      id: 'create_customer',
      icon: Icons.person_add_outlined,
      kind: QuickActionKind.route,
      routePath: CustomersRoutes.create,
      titleBuilder: _createCustomerTitle,
      subtitleBuilder: _createCustomerSubtitle,
    ),
    QuickActionDefinition(
      id: 'create_receipt',
      icon: Icons.payments_outlined,
      kind: QuickActionKind.route,
      routePath: ReceiptsPaymentsRoutes.createReceipt,
      titleBuilder: _createReceiptTitle,
      subtitleBuilder: _createReceiptSubtitle,
    ),
    QuickActionDefinition(
      id: 'create_product',
      icon: Icons.add_box_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.productsNew,
      titleBuilder: _createProductTitle,
      subtitleBuilder: _createProductSubtitle,
    ),
    QuickActionDefinition(
      id: 'products_list',
      icon: Icons.list_alt_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.productsList,
      titleBuilder: _productsListTitle,
      subtitleBuilder: _productsListSubtitle,
    ),
    QuickActionDefinition(
      id: 'products_barcode',
      icon: Icons.qr_code_2_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.productsBarcode,
      titleBuilder: _productsBarcodeTitle,
      subtitleBuilder: _productsBarcodeSubtitle,
    ),
    QuickActionDefinition(
      id: 'products_import',
      icon: Icons.upload_file_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.productsImport,
      titleBuilder: _productsImportTitle,
      subtitleBuilder: _productsImportSubtitle,
    ),
    QuickActionDefinition(
      id: 'stock_count',
      icon: Icons.fact_check_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.count,
      titleBuilder: _stockCountTitle,
      subtitleBuilder: _stockCountSubtitle,
    ),
    QuickActionDefinition(
      id: 'stock_import',
      icon: Icons.file_upload_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.import,
      titleBuilder: _stockImportTitle,
      subtitleBuilder: _stockImportSubtitle,
    ),
    QuickActionDefinition(
      id: 'stock_reports',
      icon: Icons.assessment_outlined,
      kind: QuickActionKind.route,
      routePath: InventoryRoutes.reports,
      titleBuilder: _stockReportsTitle,
      subtitleBuilder: _stockReportsSubtitle,
    ),
  ];
}

/// Default pinned shortcuts until the user customizes.
List<String> defaultQuickActionIds() => const [
  'scan_barcode',
  'create_sale',
  'create_customer',
  'create_receipt',
  'create_product',
];

QuickActionDefinition? findQuickActionById(String id) {
  for (final action in quickActionCatalog()) {
    if (action.id == id) {
      return action;
    }
  }
  return null;
}

String _scanBarcodeTitle(AppLocalizations l10n) => l10n.quickActionsScanBarcode;
String _scanBarcodeSubtitle(AppLocalizations l10n) =>
    l10n.quickActionsScanBarcodeSubtitle;

String _createSaleTitle(AppLocalizations l10n) => l10n.salesCreateTitle;
String _createSaleSubtitle(AppLocalizations l10n) =>
    l10n.salesCreateCardSubtitle;

String _createCustomerTitle(AppLocalizations l10n) =>
    l10n.customersCreateTitle;
String _createCustomerSubtitle(AppLocalizations l10n) =>
    l10n.customersCreateTitle;

String _createReceiptTitle(AppLocalizations l10n) =>
    l10n.rpServiceCreateReceipt;
String _createReceiptSubtitle(AppLocalizations l10n) =>
    l10n.rpCreateReceiptSubtitle;

String _createProductTitle(AppLocalizations l10n) =>
    l10n.quickActionsCreateProduct;
String _createProductSubtitle(AppLocalizations l10n) =>
    l10n.quickActionsCreateProductSubtitle;

String _productsListTitle(AppLocalizations l10n) => l10n.productsListTitle;
String _productsListSubtitle(AppLocalizations l10n) =>
    l10n.productsListSubtitle;

String _productsBarcodeTitle(AppLocalizations l10n) =>
    l10n.productsBarcodeTitle;
String _productsBarcodeSubtitle(AppLocalizations l10n) =>
    l10n.productsBarcodeSubtitle;

String _productsImportTitle(AppLocalizations l10n) => l10n.productsImportTitle;
String _productsImportSubtitle(AppLocalizations l10n) =>
    l10n.productsImportSubtitle;

String _stockCountTitle(AppLocalizations l10n) => l10n.inventoryCountTitle;
String _stockCountSubtitle(AppLocalizations l10n) =>
    l10n.inventoryCountSubtitle;

String _stockImportTitle(AppLocalizations l10n) => l10n.importPageTitle;
String _stockImportSubtitle(AppLocalizations l10n) =>
    l10n.inventoryStockCountServiceDescription;

String _stockReportsTitle(AppLocalizations l10n) => l10n.reportsTitle;
String _stockReportsSubtitle(AppLocalizations l10n) =>
    l10n.inventoryStockCountServiceDescription;
