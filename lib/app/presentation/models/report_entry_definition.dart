import 'package:flutter/material.dart';

import '../../../modules/inventory/inventory_module.dart';
import '../../../modules/inventory/presentation/pages/inventory_routes.dart';
import '../../localization/app_localizations.dart';
import '../../router/app_routes.dart';

/// A single report entry contributed by a module service.
@immutable
class ReportEntryDefinition {
  const ReportEntryDefinition({
    required this.id,
    required this.moduleId,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.path,
  });

  final String id;
  final String moduleId;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  /// Route to open. `null` means the report is not available yet.
  final String? path;

  bool get isAvailable => path != null && path!.isNotEmpty;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);
}

/// A module that exposes one or more service reports.
@immutable
class ReportModuleDefinition {
  const ReportModuleDefinition({
    required this.moduleId,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  final String moduleId;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);

  /// Hub route under the platform reports tab.
  String get hubPath => AppRoutes.moduleReports(moduleId);
}

/// Platform modules that have a reports hub.
List<ReportModuleDefinition> platformReportModules() {
  return const [
    ReportModuleDefinition(
      moduleId: InventoryModule.moduleId,
      icon: Icons.inventory_2_outlined,
      titleBuilder: _inventoryReportsTitle,
      subtitleBuilder: _inventoryReportsSubtitle,
    ),
  ];
}

/// Per-service reports for a module. Extend when new services ship reports.
List<ReportEntryDefinition> reportsForModule(String moduleId) {
  return [
    for (final entry in _allReportEntries())
      if (entry.moduleId == moduleId) entry,
  ];
}

ReportModuleDefinition? findReportModule(String moduleId) {
  for (final module in platformReportModules()) {
    if (module.moduleId == moduleId) {
      return module;
    }
  }
  return null;
}

List<ReportEntryDefinition> _allReportEntries() {
  return const [
    ReportEntryDefinition(
      id: 'inventory_stock_count',
      moduleId: InventoryModule.moduleId,
      icon: Icons.fact_check_outlined,
      path: InventoryRoutes.reports,
      titleBuilder: _stockCountReportTitle,
      subtitleBuilder: _stockCountReportSubtitle,
    ),
    ReportEntryDefinition(
      id: 'inventory_products',
      moduleId: InventoryModule.moduleId,
      icon: Icons.inventory_2_outlined,
      path: null,
      titleBuilder: _productsReportTitle,
      subtitleBuilder: _productsReportComingSoon,
    ),
  ];
}

String _inventoryReportsTitle(AppLocalizations l10n) =>
    l10n.platformReportsInventory;

String _inventoryReportsSubtitle(AppLocalizations l10n) =>
    l10n.platformReportsInventorySubtitle;

String _stockCountReportTitle(AppLocalizations l10n) =>
    l10n.platformReportsStockCountTitle;

String _stockCountReportSubtitle(AppLocalizations l10n) =>
    l10n.platformReportsStockCountSubtitle;

String _productsReportTitle(AppLocalizations l10n) =>
    l10n.platformReportsProductsTitle;

String _productsReportComingSoon(AppLocalizations l10n) =>
    l10n.platformReportsServiceComingSoon;
