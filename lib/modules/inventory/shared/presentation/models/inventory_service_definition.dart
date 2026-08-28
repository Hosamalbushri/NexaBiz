import 'package:flutter/material.dart';

import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import 'package:stock_count/app/localization/app_localizations.dart';

/// A service offered inside the Inventory module (not a platform AppModule).
@immutable
class InventoryServiceDefinition {
  const InventoryServiceDefinition({
    required this.id,
    required this.icon,
    required this.path,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  final String id;
  final IconData icon;
  final String path;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);
}

/// Catalog of inventory-internal services. Order here is the default pin order.
List<InventoryServiceDefinition> inventoryServiceCatalog() {
  return const [
    InventoryServiceDefinition(
      id: 'stock_movements',
      icon: Icons.swap_vert_rounded,
      path: InventoryRoutes.stockMovements,
      titleBuilder: _stockMovementsTitle,
      subtitleBuilder: _stockMovementsSubtitle,
    ),
    InventoryServiceDefinition(
      id: 'stock_count',
      icon: Icons.fact_check_outlined,
      path: InventoryRoutes.stockCount,
      titleBuilder: _stockCountTitle,
      subtitleBuilder: _stockCountSubtitle,
    ),
    InventoryServiceDefinition(
      id: 'products',
      icon: Icons.inventory_2_outlined,
      path: InventoryRoutes.products,
      titleBuilder: _productsTitle,
      subtitleBuilder: _productsSubtitle,
    ),
  ];
}

String _stockMovementsTitle(AppLocalizations l10n) => 'الحركة';
String _stockMovementsSubtitle(AppLocalizations l10n) => 'أوامر الصرف وأوامر التوريد للمخزون';

String _stockCountTitle(AppLocalizations l10n) =>
    l10n.inventoryStockCountService;

String _stockCountSubtitle(AppLocalizations l10n) =>
    l10n.inventoryStockCountServiceDescription;

String _productsTitle(AppLocalizations l10n) => l10n.inventoryProductsService;

String _productsSubtitle(AppLocalizations l10n) =>
    l10n.inventoryProductsServiceDescription;

InventoryServiceDefinition? findInventoryServiceById(String id) {
  for (final service in inventoryServiceCatalog()) {
    if (service.id == id) {
      return service;
    }
  }
  if (id == 'stock_receipts' || id == 'stock_issues' || id == 'stock_transfers') {
    return findInventoryServiceById('stock_movements');
  }
  return null;
}
