import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/currencies_manage_page.dart';
import 'package:stock_count/modules/accounting/shared/presentation/widgets/accounting_settings_panel.dart';
import 'package:stock_count/core/setup/setup_core.dart';

/// Single authoritative Master Settings Hub for the Accounting Module (`/accounting/settings`).
///
/// Clean, unified, tabless professional configuration interface for Accounting.
class AccountingMasterSettingsPage extends ConsumerStatefulWidget {
  const AccountingMasterSettingsPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<AccountingMasterSettingsPage> createState() =>
      _AccountingMasterSettingsPageState();
}

class _AccountingMasterSettingsPageState
    extends ConsumerState<AccountingMasterSettingsPage> {
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
            ? 'إعدادات وتهيئة النظام المحاسبي'
            : 'Accounting Module Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Currencies Management Quick Action List Menu
          SettingsGroupLabel(
            isAr ? 'العملات وإدارة أسعار الصرف' : 'Currencies & Daily Rates',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.currency_exchange_rounded,
                iconColor: Colors.teal,
                title: isAr
                    ? 'إدارة العملات وأسعار الصرف اليومية'
                    : 'Manage Currencies & Daily Rates',
                subtitle: isAr
                    ? 'تعريف العملات، تحديد العملة الأساسية، وتحديث أسعار التحويل'
                    : 'Manage active system currencies and daily conversion rates',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CurrenciesManagePage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Chart of Accounts & Books Setup List Menu Panel
          SettingsGroupLabel(
            isAr
                ? 'دليل الحسابات والدفاتر المحاسبية'
                : 'Chart of Accounts & Book Setup',
          ),
          const SettingsGroup(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: AccountingSettingsPanel(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 3: Package Account Bindings List Menu
          SettingsGroupLabel(
            isAr
                ? 'التهيئة والربط المحاسبي الافتراضي'
                : 'Accounting Package Account Bindings',
          ),
          const SettingsGroup(
            children: [
              PackageInitializationSettingsHub(packageId: 'accounting'),
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
              Icons.account_balance_rounded,
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
                      ? 'مركز تهيئة وإعدادات المحاسبة'
                      : 'Accounting Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'إدارة دليل الحسابات، الدفاتر، العملات، والربط المحاسبي للنظام'
                      : 'Comprehensive control over Chart of Accounts, currencies, and system accounting roles',
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
