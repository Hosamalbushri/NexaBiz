import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/pages/stock_transfers_list_page.dart';
import 'stock_issues_list_page.dart';
import 'stock_receipts_list_page.dart';

/// Stock Movements Hub Page ('الحركة') matching the Sales Module Hub layout.
class StockMovementsPage extends ConsumerStatefulWidget {
  const StockMovementsPage({
    super.key,
    this.initialIndex,
  });

  /// Optional initial tab index. If provided, opens direct list tab view instead of hub menu cards.
  final int? initialIndex;

  @override
  ConsumerState<StockMovementsPage> createState() => _StockMovementsPageState();
}

class _StockMovementsPageState extends ConsumerState<StockMovementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _showTabs;

  @override
  void initState() {
    super.initState();
    _showTabs = widget.initialIndex != null;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialIndex ?? 0).clamp(0, 2),
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
    final isAr = l10n.localeName == 'ar';

    if (_showTabs) {
      return Scaffold(
        appBar: CustomAppBar(
          title: isAr ? 'حركة المخزون' : 'Stock Movements',
          showBackButton: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: isAr ? 'القائمة الرئيسية' : 'Main Menu',
              onPressed: () {
                setState(() => _showTabs = false);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: [
              Tab(
                icon: const Icon(Icons.move_to_inbox_rounded, size: 18),
                text: isAr ? 'أوامر التوريد' : 'Stock Receipts',
              ),
              Tab(
                icon: const Icon(Icons.outbox_rounded, size: 18),
                text: isAr ? 'أوامر الصرف' : 'Stock Issues',
              ),
              Tab(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                text: isAr ? 'النقل المخزني' : 'Stock Transfers',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            StockReceiptsListPage(embedInTab: true),
            StockIssuesListPage(embedInTab: true),
            StockTransfersListPage(embedInTab: true),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr ? 'حركة المخزون' : 'Stock Movements',
        showBackButton: true,
      ),
      body: AppContentConstraint(
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            Text(
              isAr ? 'خدمات وقوائم حركة المخزون' : 'Stock Movement Services',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isAr
                  ? 'إدارة واستعراض وإصدار أوامر الصرف والتوريد والنقل المخزني'
                  : 'Manage and issue stock receipts, stock issues, and warehouse transfers',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 1: Stock Receipts (أوامر التوريد)
            _SectionHeader(
              title: isAr ? 'أوامر التوريد' : 'Stock Receipts',
              icon: Icons.move_to_inbox_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MovementHubCard(
              icon: Icons.receipt_long_outlined,
              title: isAr ? 'قائمة أوامر التوريد' : 'Stock Receipts List',
              subtitle: isAr
                  ? 'عرض والبحث في كافة إيصالات التوريد المسجلة'
                  : 'View and search all registered stock receipt documents',
              onTap: () {
                _tabController.animateTo(0);
                setState(() => _showTabs = true);
              },
            ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04, end: 0, duration: 220.ms),
            const SizedBox(height: AppSpacing.sm),
            _MovementHubCard(
              icon: Icons.add_circle_outline_rounded,
              title: isAr ? 'إصدار أمر توريد جديد' : 'New Stock Receipt',
              subtitle: isAr
                  ? 'استلام بضائع وتغذية رصيد وأصل المخزون'
                  : 'Receive items & update inventory asset values',
              onTap: () => InventoryRoutes.pushStockReceiptsNew(context),
            ).animate().fadeIn(delay: 40.ms, duration: 220.ms).slideY(begin: 0.04, end: 0, delay: 40.ms, duration: 220.ms),

            const SizedBox(height: AppSpacing.xl),

            // Section 2: Stock Issues (أوامر الصرف)
            _SectionHeader(
              title: isAr ? 'أوامر الصرف' : 'Stock Issues',
              icon: Icons.outbox_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MovementHubCard(
              icon: Icons.assignment_outlined,
              title: isAr ? 'قائمة أوامر الصرف' : 'Stock Issues List',
              subtitle: isAr
                  ? 'عرض والبحث في كافة أذونات الصرف المسجلة'
                  : 'View and search all registered stock issue documents',
              onTap: () {
                _tabController.animateTo(1);
                setState(() => _showTabs = true);
              },
            ).animate().fadeIn(delay: 80.ms, duration: 220.ms).slideY(begin: 0.04, end: 0, delay: 80.ms, duration: 220.ms),
            const SizedBox(height: AppSpacing.sm),
            _MovementHubCard(
              icon: Icons.add_shopping_cart_outlined,
              title: isAr ? 'إصدار أمر صرف جديد' : 'New Stock Issue',
              subtitle: isAr
                  ? 'صرف أصناف وتثبيت المصروف وتكلفة المبيعات'
                  : 'Issue items & assign cost of goods / expenses',
              onTap: () => InventoryRoutes.pushStockIssuesNew(context),
            ).animate().fadeIn(delay: 120.ms, duration: 220.ms).slideY(begin: 0.04, end: 0, delay: 120.ms, duration: 220.ms),

            const SizedBox(height: AppSpacing.xl),

            // Section 3: Stock Transfers (النقل المخزني)
            _SectionHeader(
              title: isAr ? 'النقل المخزني' : 'Stock Transfers',
              icon: Icons.swap_horiz_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MovementHubCard(
              icon: Icons.compare_arrows_rounded,
              title: isAr ? 'قائمة النقل المخزني' : 'Stock Transfers List',
              subtitle: isAr
                  ? 'عرض والبحث في كافة عمليات التحويل بين المستودعات'
                  : 'View and search all inter-warehouse stock transfers',
              onTap: () {
                _tabController.animateTo(2);
                setState(() => _showTabs = true);
              },
            ).animate().fadeIn(delay: 160.ms, duration: 220.ms).slideY(begin: 0.04, end: 0, delay: 160.ms, duration: 220.ms),
            const SizedBox(height: AppSpacing.sm),
            _MovementHubCard(
              icon: Icons.swap_horizontal_circle_outlined,
              title: isAr ? 'إنشاء أمر تحويل جديد' : 'New Stock Transfer',
              subtitle: isAr
                  ? 'تحويل الأصول والأصناف بين المستودعات'
                  : 'Transfer inventory items between different warehouses',
              onTap: () => InventoryRoutes.pushStockTransfersNew(context),
            ).animate().fadeIn(delay: 200.ms, duration: 220.ms).slideY(begin: 0.04, end: 0, delay: 200.ms, duration: 220.ms),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _MovementHubCard extends StatelessWidget {
  const _MovementHubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
