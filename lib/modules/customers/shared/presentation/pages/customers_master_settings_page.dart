import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'customers_settings_page.dart';

/// Single authoritative Master Settings Hub for the Customers Module (`/customers/settings`).
///
/// Clean, unified, tabless professional configuration interface for Customers.
class CustomersMasterSettingsPage extends ConsumerStatefulWidget {
  const CustomersMasterSettingsPage({super.key});

  @override
  ConsumerState<CustomersMasterSettingsPage> createState() =>
      _CustomersMasterSettingsPageState();
}

class _CustomersMasterSettingsPageState
    extends ConsumerState<CustomersMasterSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr ? 'إعدادات وتهيئة موديول العملاء' : 'Customers Module Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Account Linking & Bulk Actions Menu List
          SettingsGroupLabel(
            isAr ? 'ربط وتوجيه الحسابات وتصحيحها' : 'Account Linking & Repair',
          ),
          const SettingsGroup(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: CustomersSettingsPageBody(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Parent CoA Group Settings Menu List
          SettingsGroupLabel(
            isAr ? 'دليل الحساب الأب وسياسات الائتمان' : 'Parent CoA Account Group',
          ),
          const SettingsGroup(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: CustomersParentAccountSettingsBody(),
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
              Icons.people_alt_rounded,
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
                  isAr ? 'مركز تهيئة وإعدادات العملاء' : 'Customers Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'ربط حسابات العملاء بدليل الحسابات، تصحيح الحسابات المفقودة، وتحديد المجموعة الرئيسية'
                      : 'Link customer CoA accounts, repair missing accounts, and assign parent group',
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

/// Extracted body widget for CustomersSettingsPage
class CustomersSettingsPageBody extends ConsumerWidget {
  const CustomersSettingsPageBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomersSettingsPage();
  }
}

