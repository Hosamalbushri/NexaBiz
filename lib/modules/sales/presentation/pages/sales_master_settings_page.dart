import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/core/routes/routes_core.dart';


/// Single authoritative Master Settings Hub for the Sales Module (`/sales/settings`).
///
/// Clean, unified, tabless professional configuration interface for Sales.
class SalesMasterSettingsPage extends ConsumerWidget {
  const SalesMasterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr
            ? 'إعدادات وتهيئة المبيعات'
            : 'Sales Module Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Per-Warehouse Sales Configuration
          SettingsGroupLabel(
            isAr
                ? 'التهيئة والربط المحاسبي للمبيعات (حسب المستودع)'
                : 'Per-Warehouse Sales Configuration',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.store_rounded,
                iconColor: colorScheme.primary,
                title: isAr
                    ? 'إعدادات المستودعات والربط المحاسبي للمبيعات'
                    : 'Warehouse Sales & Revenue Bindings',
                subtitle: isAr
                    ? 'يتم تهيئة وتخصيص حسابات المبيعات والمردودات وتكلفة البضاعة المباعة لكل مستودع بشكل مستقل'
                    : 'Configure sales revenue and COGS account bindings directly within each warehouse',
                onTap: () => InventoryRoutes.pushWarehousesSettings(context),
              ),

            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isAr) {
    return AppSurface(
      variant: AppSurfaceVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
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
                  isAr
                      ? 'مركز تهيئة وإعدادات المبيعات'
                      : 'Sales Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'التهيئة والربط المحاسبي لدليل حسابات المبيعات والعملاء'
                      : 'Configure sales revenue and customer chart of account bindings',
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
