import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/categories/presentation/pages/categories_settings_page.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/pages/cost_valuation_settings_page.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/pages/warehouses_settings_page.dart';

/// Single authoritative Master Settings Hub for the Inventory Module (`/inventory/settings`).
///
/// Clean, unified, tabless professional configuration interface for Inventory.
class InventoryMasterSettingsPage extends ConsumerWidget {
  const InventoryMasterSettingsPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr ? 'إعدادات وتهيئة موديول المخزون' : 'Inventory Module Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Header Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Master Data Navigation Menu List
          SettingsGroupLabel(
            isAr ? 'البيانات الرئيسية والتشغيلية' : 'Inventory Master Data & Operations',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.warehouse_rounded,
                iconColor: colorScheme.primary,
                title: isAr ? 'إدارة المستودعات والمواقع' : 'Warehouses & Locations',
                subtitle: isAr
                    ? 'تعريف المستودعات، الأفرع، والمواقع التخزينية'
                    : 'Manage warehouses, branches, and storage locations',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WarehousesSettingsPage()),
                ),
              ),
              SettingsTile(
                icon: Icons.account_tree_rounded,
                iconColor: Colors.teal,
                title: isAr ? 'شجرة تصنيفات المنتجات' : 'Product Categories Hierarchy',
                subtitle: isAr
                    ? 'تنظيم فئات ومجموعات المنتجات الرئيسية والفرعية'
                    : 'Organize category tree and item classification groups',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesSettingsPage()),
                ),
              ),
              SettingsTile(
                icon: Icons.calculate_outlined,
                iconColor: Colors.amber.shade800,
                title: isAr ? 'سياسة تقييم التكلفة المخزنية' : 'Cost Valuation Method',
                subtitle: isAr
                    ? 'تحديد طريقة التقييم المحاسبي (المتوسط المرجح / FIFO)'
                    : 'Configure inventory costing method (Weighted Avg / FIFO)',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CostValuationSettingsPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Per-Warehouse Configuration & Bindings
          SettingsGroupLabel(
            isAr
                ? 'التهيئة والربط المحاسبي (حسب المستودع)'
                : 'Per-Warehouse Configuration & Bindings',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.account_balance_outlined,
                iconColor: colorScheme.primary,
                title: isAr
                    ? 'إعدادات والربط المحاسبي للمستودعات'
                    : 'Warehouse Account Bindings',
                subtitle: isAr
                    ? 'يتم تهيئة وتحديد جميع حسابات المخزون والتكلفة والتسويات داخل كل مستودع'
                    : 'Configure stock asset, COGS, and adjustment accounts directly per warehouse',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WarehousesSettingsPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isAr) {
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'مركز تهيئة وإعدادات المخزون' : 'Inventory Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'تحكم كامل بالمستودعات، تصنيفات المنتجات، تقييم التكلفة والربط المحاسبي'
                      : 'Comprehensive control over warehouses, categories, valuation, and account bindings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
