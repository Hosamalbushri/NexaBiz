import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../pages/inventory_routes.dart';

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
      id: 'stock_count',
      icon: Icons.fact_check_outlined,
      path: InventoryRoutes.stockCount,
      titleBuilder: _stockCountTitle,
      subtitleBuilder: _stockCountSubtitle,
    ),
  ];
}

String _stockCountTitle(AppLocalizations l10n) =>
    l10n.inventoryStockCountService;

String _stockCountSubtitle(AppLocalizations l10n) =>
    l10n.inventoryStockCountServiceDescription;

InventoryServiceDefinition? findInventoryServiceById(String id) {
  for (final service in inventoryServiceCatalog()) {
    if (service.id == id) {
      return service;
    }
  }
  return null;
}
