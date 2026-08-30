import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

/// Inventory permission codes (primary + legacy).
abstract final class InventoryPermissions {
  static const stockView = [
    'inventory.stock_count.view',
    'inventory.view',
  ];
  static const stockAdjust = [
    'inventory.stock_count.adjust',
    'inventory.adjust',
    'inventory.update',
  ];
  static const stockImport = [
    'inventory.stock_count.import',
    'inventory.create',
  ];
  static const stockExport = ['inventory.stock_count.export'];
  static const stockClear = [
    'inventory.stock_count.clear',
    'inventory.delete',
  ];
  static const productsView = [
    'inventory.products.view',
    'products.view',
  ];
  static const productsCreate = [
    'inventory.products.create',
    'products.create',
  ];
  static const productsUpdate = [
    'inventory.products.update',
    'products.update',
  ];
  static const productsDelete = [
    'inventory.products.delete',
    'products.delete',
  ];
  static const productsImport = ['inventory.products.import'];
  static const productsBarcode = [
    'inventory.products.barcode',
    'inventory.products.view',
    'products.view',
  ];
  static const receiptsView = [
    'inventory.receipts.view',
    'inventory.view',
  ];
  static const receiptsCreate = [
    'inventory.receipts.create',
    'inventory.create',
  ];
  static const receiptsUpdate = [
    'inventory.receipts.update',
    'inventory.update',
  ];
  static const receiptsDelete = [
    'inventory.receipts.delete',
    'inventory.delete',
  ];
  static const receiptsPost = [
    'inventory.receipts.post',
    'inventory.receipts.create',
    'inventory.create',
  ];
  static const receiptsReverse = [
    'inventory.receipts.reverse',
    'inventory.receipts.delete',
    'inventory.delete',
  ];
  static const issuesView = [
    'inventory.issues.view',
    'inventory.view',
  ];
  static const issuesCreate = [
    'inventory.issues.create',
    'inventory.create',
  ];
  static const issuesUpdate = [
    'inventory.issues.update',
    'inventory.update',
  ];
  static const issuesDelete = [
    'inventory.issues.delete',
    'inventory.delete',
  ];
  static const issuesPost = [
    'inventory.issues.post',
    'inventory.issues.create',
    'inventory.create',
  ];
  static const issuesReverse = [
    'inventory.issues.reverse',
    'inventory.issues.delete',
    'inventory.delete',
  ];

  static const transfersView = ['inventory.transfers.view', 'inventory.view'];
  static const transfersCreate = ['inventory.transfers.create', 'inventory.create'];
  static const transfersUpdate = ['inventory.transfers.update', 'inventory.update'];
  static const transfersDelete = ['inventory.transfers.delete', 'inventory.delete'];
  static const transfersPost = ['inventory.transfers.post', 'inventory.create'];
  static const transfersReverse = ['inventory.transfers.reverse', 'inventory.delete'];

  static const returnsView = ['inventory.returns.view', 'inventory.view'];
  static const returnsCreate = ['inventory.returns.create', 'inventory.create'];
  static const returnsUpdate = ['inventory.returns.update', 'inventory.update'];
  static const returnsDelete = ['inventory.returns.delete', 'inventory.delete'];
  static const returnsPost = ['inventory.returns.post', 'inventory.create'];
  static const returnsReverse = ['inventory.returns.reverse', 'inventory.delete'];

  static const adjustCost = [
    'inventory.stock_count.adjust',
    'inventory.cost.adjust',
    'inventory.adjust',
  ];
}


/// Inventory RBAC package — Stock count + Products services.
PermissionPackageDef inventoryPermissionPackage() {
  return PermissionPackageDef(
    id: 'inventory',
    icon: Icons.inventory_2_outlined,
    sortOrder: 10,
    titleBuilder: (context) => AppLocalizations.of(context).moduleInventory,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageInventoryHint,
    services: [
      PermissionServiceDef(
        id: 'stock_count',
        icon: Icons.fact_check_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).inventoryStockCountService,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).inventoryStockCountServiceDescription,
        operations: [
          StandardPermissionOps.view(
            'inventory.stock_count.view',
            legacyCodes: const ['inventory.view'],
          ),
          StandardPermissionOps.custom(
            code: 'inventory.stock_count.adjust',
            icon: Icons.fact_check_outlined,
            legacyCodes: const ['inventory.adjust', 'inventory.update'],
            label: (l10n) => l10n.adminPermOpStockCount,
          ),
          StandardPermissionOps.importOp(
            'inventory.stock_count.import',
            legacyCodes: const ['inventory.create'],
          ),
          StandardPermissionOps.custom(
            code: 'inventory.stock_count.export',
            icon: Icons.download_outlined,
            label: (l10n) => l10n.adminPermOpReportsExport,
          ),
          StandardPermissionOps.custom(
            code: 'inventory.stock_count.clear',
            icon: Icons.cleaning_services_outlined,
            legacyCodes: const ['inventory.delete'],
            label: (l10n) => l10n.adminPermOpClear,
          ),
        ],
      ),
      PermissionServiceDef(
        id: 'products',
        icon: Icons.qr_code_2_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).inventoryProductsService,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).inventoryProductsServiceDescription,
        operations: [
          StandardPermissionOps.view(
            'inventory.products.view',
            legacyCodes: const ['products.view'],
          ),
          StandardPermissionOps.create(
            'inventory.products.create',
            legacyCodes: const ['products.create'],
          ),
          StandardPermissionOps.update(
            'inventory.products.update',
            legacyCodes: const ['products.update'],
          ),
          StandardPermissionOps.delete(
            'inventory.products.delete',
            legacyCodes: const ['products.delete'],
          ),
          StandardPermissionOps.importOp('inventory.products.import'),
          StandardPermissionOps.custom(
            code: 'inventory.products.barcode',
            icon: Icons.qr_code_2_outlined,
            label: (l10n) => l10n.adminPermOpBarcode,
          ),
        ],
      ),
    ],
  );
}
