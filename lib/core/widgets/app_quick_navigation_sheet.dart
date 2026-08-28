import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Modal bottom sheet providing quick entry/exit navigation to all key application screens.
class AppQuickNavigationSheet extends StatelessWidget {
  const AppQuickNavigationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AppQuickNavigationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    final navItems = <_NavItemData>[
      _NavItemData(
        title: isAr ? 'الشاشة الرئيسية' : 'Dashboard',
        subtitle: isAr ? 'العودة للواجهة الرئيسية' : 'Exit to main home dashboard',
        icon: Icons.grid_view_rounded,
        route: AppRoutes.dashboard,
        isPrimary: true,
      ),
      _NavItemData(
        title: isAr ? 'المبيعات' : 'Sales',
        subtitle: isAr ? 'الفواتير وإصدار المبيعات' : 'Invoices & sales management',
        icon: Icons.shopping_bag_outlined,
        route: '/sales',
      ),
      _NavItemData(
        title: isAr ? 'حركة المخزون' : 'Stock Movements',
        subtitle: isAr ? 'مركز عمليات الحركة المخزنية' : 'Movement transactions hub',
        icon: Icons.sync_alt_rounded,
        route: '/inventory/stock-movements',
      ),
      _NavItemData(
        title: isAr ? 'أوامر التوريد' : 'Stock Receipts',
        subtitle: isAr ? 'استلام بضائع وتوريدات' : 'Stock receipts & inventory input',
        icon: Icons.move_to_inbox_rounded,
        route: '/inventory/stock-movements/receipts',
      ),
      _NavItemData(
        title: isAr ? 'أوامر الصرف' : 'Stock Issues',
        subtitle: isAr ? 'صرف أصناف ومصروفات' : 'Stock issues & inventory output',
        icon: Icons.outbox_rounded,
        route: '/inventory/stock-movements',
      ),
      _NavItemData(
        title: isAr ? 'النقل المخزني' : 'Stock Transfers',
        subtitle: isAr ? 'تحويلات بين المستودعات' : 'Inter-warehouse stock transfers',
        icon: Icons.swap_horiz_rounded,
        route: '/inventory/stock-transfers',
      ),
      _NavItemData(
        title: isAr ? 'القيود المحاسبية' : 'Journal Entries',
        subtitle: isAr ? 'القيود اليومية والآلية' : 'Manual & automated journals',
        icon: Icons.book_outlined,
        route: '/journals',
      ),
      _NavItemData(
        title: isAr ? 'شجرة الحسابات' : 'Chart of Accounts',
        subtitle: isAr ? 'دليل الحسابات المالي' : 'Financial chart of accounts',
        icon: Icons.account_tree_outlined,
        route: '/accounts',
      ),
      _NavItemData(
        title: isAr ? 'المقبوضات والمدفوعات' : 'Vouchers',
        subtitle: isAr ? 'سندات القبض والصرف' : 'Cash & bank vouchers',
        icon: Icons.account_balance_wallet_outlined,
        route: '/vouchers',
      ),
      _NavItemData(
        title: isAr ? 'إدارة المستودعات' : 'Warehouses',
        subtitle: isAr ? 'إعدادات وقوائم المستودعات' : 'Warehouse configurations',
        icon: Icons.store_rounded,
        route: '/inventory/warehouses/settings',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.explore_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'التنقل السريع والخروج' : 'Quick Navigation & Exit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isAr ? 'الدخول المباشر للشاشات والعودة للرئيسية' : 'Direct access to screens & home exit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: navItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (ctx, idx) {
                final item = navItems[idx];
                final isPrimary = item.isPrimary;

                return Material(
                  color: isPrimary
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () {
                      Navigator.of(context).pop();
                      final router = GoRouter.of(context);
                      router.go(item.route);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isPrimary
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                                    color: isPrimary
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.isPrimary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool isPrimary;
}
