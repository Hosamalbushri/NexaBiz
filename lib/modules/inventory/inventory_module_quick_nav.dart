import 'package:flutter/material.dart';

import '../../core/modules/quick_nav_definition.dart';

List<QuickNavDefinition> buildInventoryQuickNav(String moduleId) {
  return [
    QuickNavDefinition(
      id: 'quick_nav_stock_movements',
      icon: Icons.sync_alt_rounded,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'حركة المخزون' : 'Stock Movements',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'مركز عمليات الحركة المخزنية' : 'Movement transactions hub',
      routePath: '/inventory/stock-movements',
      moduleId: moduleId,
      requiredPermissions: const ['inventory.view', 'stock.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_stock_receipts',
      icon: Icons.move_to_inbox_rounded,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'أوامر التوريد' : 'Stock Receipts',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'استلام بضائع وتوريدات' : 'Stock receipts & inventory input',
      routePath: '/inventory/stock-movements/receipts',
      moduleId: moduleId,
      requiredPermissions: const ['inventory.view', 'stock.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_stock_issues',
      icon: Icons.outbox_rounded,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'أوامر الصرف' : 'Stock Issues',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'صرف أصناف ومصروفات' : 'Stock issues & inventory output',
      routePath: '/inventory/stock-movements/issues',
      moduleId: moduleId,
      requiredPermissions: const ['inventory.view', 'stock.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_stock_transfers',
      icon: Icons.swap_horiz_rounded,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'النقل المخزني' : 'Stock Transfers',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'تحويلات بين المستودعات' : 'Inter-warehouse stock transfers',
      routePath: '/inventory/stock-transfers',
      moduleId: moduleId,
      requiredPermissions: const ['inventory.view', 'stock.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_stock_count',
      icon: Icons.fact_check_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'الجرد المخزني' : 'Stock Count',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'عمليات وتعديلات الجرد' : 'Stock count operations & adjustments',
      routePath: '/inventory/stock-count',
      moduleId: moduleId,
      requiredPermissions: const ['inventory.view', 'stock.manage'],
    ),
    QuickNavDefinition(
      id: 'quick_nav_products',
      icon: Icons.inventory_2_outlined,
      titleBuilder: (l10n) => l10n.localeName == 'ar' ? 'دليل الأصناف' : 'Products Directory',
      subtitleBuilder: (l10n) => l10n.localeName == 'ar' ? 'قوائم وأسعار الأصناف' : 'Product catalog & price lists',
      routePath: '/inventory/products',
      moduleId: moduleId,
      requiredPermissions: const ['inventory.view', 'products.manage'],
    ),
  ];
}
