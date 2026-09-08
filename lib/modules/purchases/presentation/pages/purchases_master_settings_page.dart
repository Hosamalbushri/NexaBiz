import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/system_setup/presentation/widgets/package_initialization_settings_hub.dart';

/// Single authoritative Master Settings Hub for the Purchases Module (`/purchases/settings`).
///
/// Clean, unified, tabless professional configuration interface for Purchases.
class PurchasesMasterSettingsPage extends ConsumerWidget {
  const PurchasesMasterSettingsPage({super.key});

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
            ? 'إعدادات وتهيئة المشتريات والموردين'
            : 'Purchases Module Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Package Setup & Account Bindings List Menu
          SettingsGroupLabel(
            isAr ? 'التهيئة والربط المحاسبي للمشتريات' : 'Purchases Account Bindings',
          ),
          const SettingsGroup(
            children: [
              PackageInitializationSettingsHub(packageId: 'purchases'),
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
              Icons.shopping_bag_rounded,
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
                  isAr ? 'مركز تهيئة وإعدادات المشتريات' : 'Purchases Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'التهيئة والربط المحاسبي لدليل حسابات الموردين والمشتريات'
                      : 'Configure vendor and purchasing chart of account bindings',
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
