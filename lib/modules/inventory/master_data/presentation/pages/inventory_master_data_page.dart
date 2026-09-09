import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/categories/presentation/pages/categories_settings_page.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/pages/cost_valuation_settings_page.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/pages/warehouses_settings_page.dart';

/// Unified Inventory Master Settings Hub.
///
/// Consolidates Warehouses, Category Hierarchy, and Cost Valuation Policies
/// into a modern, streamlined tabbed interface.
class InventoryMasterDataPage extends ConsumerStatefulWidget {
  const InventoryMasterDataPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<InventoryMasterDataPage> createState() =>
      _InventoryMasterDataPageState();
}

class _InventoryMasterDataPageState
    extends ConsumerState<InventoryMasterDataPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr
            ? 'إعدادات وبيانات المخزون الرئيسية'
            : 'Inventory Master Data & Settings',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.warehouse_rounded, size: 20),
              text: isAr ? 'المستودعات' : 'Warehouses',
            ),
            Tab(
              icon: const Icon(Icons.account_tree_rounded, size: 20),
              text: isAr ? 'تصنيفات المخزون' : 'Categories',
            ),
            Tab(
              icon: const Icon(Icons.calculate_outlined, size: 20),
              text: isAr ? 'سياسة التكلفة والتقييم' : 'Cost Valuation',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WarehousesSettingsPage(),
          CategoriesSettingsPage(),
          CostValuationSettingsPage(),
        ],
      ),
    );
  }
}
