import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/shared/providers/module_hub_view_mode_provider.dart';
import 'package:stock_count/modules/currency/presentation/widgets/missing_currency_dialog.dart';
import 'accounting_routes.dart';

/// Accounting module hub.
class AccountingHomePage extends ConsumerWidget {
  const AccountingHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(moduleHubViewModeProvider);
    final isGrid = viewMode == ModuleHubViewMode.grid;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleAccounting,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/accounting/settings'),
          ),
        ],
      ),
      body: AppContentConstraint(
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            const AppMissingCurrencyGuardBanner(),
            AppModuleHubHeader(
              title: l10n.servicesTitle,
              subtitle: l10n.moduleAccountingDescription,
              trailing: AppViewModeToggle<ModuleHubViewMode>(
                options: [
                  AppViewModeOption(
                    value: ModuleHubViewMode.grid,
                    icon: Icons.grid_view_rounded,
                    tooltip: l10n.localeName == 'ar' ? 'عرض شبكي' : 'Grid View',
                  ),
                  AppViewModeOption(
                    value: ModuleHubViewMode.list,
                    icon: Icons.view_list_rounded,
                    tooltip: l10n.localeName == 'ar' ? 'عرض قائمة' : 'List View',
                  ),
                ],
                selected: viewMode,
                onChanged: (mode) =>
                    ref.read(moduleHubViewModeProvider.notifier).setMode(mode),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppModuleHubView(
              isGrid: isGrid,
              children: [
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.account_tree_outlined,
                        title: l10n.accountingChartOfAccounts,
                        subtitle: l10n.accountingChartOfAccountsDescription,
                        onTap: () => AccountingRoutes.goAccounts(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.account_tree_outlined,
                        title: l10n.accountingChartOfAccounts,
                        subtitle: l10n.accountingChartOfAccountsDescription,
                        onTap: () => AccountingRoutes.goAccounts(context),
                      ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.upload_file_outlined,
                        title: l10n.accountingOpeningSetupCardTitle,
                        subtitle: l10n.accountingOpeningSetupCardSubtitle,
                        animationDelay: const Duration(milliseconds: 40),
                        onTap: () => AccountingRoutes.pushOpeningSetup(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.upload_file_outlined,
                        title: l10n.accountingOpeningSetupCardTitle,
                        subtitle: l10n.accountingOpeningSetupCardSubtitle,
                        onTap: () => AccountingRoutes.pushOpeningSetup(context),
                      ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.accountingJournalsTitle,
                        subtitle: l10n.accountingJournalsSubtitle,
                        animationDelay: const Duration(milliseconds: 80),
                        onTap: () => AccountingRoutes.pushJournals(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.accountingJournalsTitle,
                        subtitle: l10n.accountingJournalsSubtitle,
                        onTap: () => AccountingRoutes.pushJournals(context),
                      ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.date_range_outlined,
                        title: l10n.accountingFiscalYearsTitle,
                        subtitle: l10n.accountingFiscalYearsSubtitle,
                        animationDelay: const Duration(milliseconds: 120),
                        onTap: () => AccountingRoutes.pushFiscalYears(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.date_range_outlined,
                        title: l10n.accountingFiscalYearsTitle,
                        subtitle: l10n.accountingFiscalYearsSubtitle,
                        onTap: () => AccountingRoutes.pushFiscalYears(context),
                      ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.menu_book_outlined,
                        title: l10n.accountingVoucherBooksTitle,
                        subtitle: l10n.accountingVoucherBooksCardSubtitle,
                        animationDelay: const Duration(milliseconds: 200),
                        onTap: () => AccountingRoutes.pushVoucherBooks(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.menu_book_outlined,
                        title: l10n.accountingVoucherBooksTitle,
                        subtitle: l10n.accountingVoucherBooksCardSubtitle,
                        onTap: () => AccountingRoutes.pushVoucherBooks(context),
                      ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.assessment_outlined,
                        title: l10n.accountingReportsTitle,
                        subtitle: l10n.accountingReportsSubtitle,
                        animationDelay: const Duration(milliseconds: 240),
                        onTap: () => AccountingRoutes.pushReports(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.assessment_outlined,
                        title: l10n.accountingReportsTitle,
                        subtitle: l10n.accountingReportsSubtitle,
                        onTap: () => AccountingRoutes.pushReports(context),
                      ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المحاسبة'
                            : 'Accounting Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات المحاسبية وإعدادات موديول المحاسبة'
                            : 'Account bindings and accounting master settings',
                        animationDelay: const Duration(milliseconds: 280),
                        onTap: () => context.push('/accounting/settings'),
                      )
                    : AppModuleHubCard(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المحاسبة'
                            : 'Accounting Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات المحاسبية وإعدادات موديول المحاسبة'
                            : 'Account bindings and accounting master settings',
                        onTap: () => context.push('/accounting/settings'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
