import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/auth/presentation/widgets/permission_gate_core.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/shared/providers/module_hub_view_mode_provider.dart';
import 'package:stock_count/modules/currency/presentation/widgets/missing_currency_dialog.dart';
import 'package:stock_count/modules/customers/permissions/customers_permission_package.dart';
import 'package:stock_count/modules/customers/shared/presentation/pages/customers_routes.dart';
import '../providers/customer_providers.dart';

/// Customers module hub.
class CustomersHomePage extends ConsumerWidget {
  const CustomersHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(moduleHubViewModeProvider);
    final isGrid = viewMode == ModuleHubViewMode.grid;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleCustomers,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => CustomersRoutes.pushSettings(context),
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
              subtitle: l10n.moduleCustomersDescription,
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
            const SizedBox(height: AppSpacing.md),
            ...[
              ref
                  .watch(customersParentAccountProvider)
                  .when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (parent) {
                      if (parent == null) {
                        return Text(
                          l10n.customersParentAccountNotSet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        );
                      }
                      return Text(
                        l10n.customersParentAccountCurrent(
                          parent.code,
                          parent.name,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppModuleHubView(
              isGrid: isGrid,
              children: [
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.people_outline,
                        title: l10n.customersListTitle,
                        subtitle: l10n.customersListCardSubtitle,
                        onTap: () => CustomersRoutes.goList(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.people_outline,
                        title: l10n.customersListTitle,
                        subtitle: l10n.customersListCardSubtitle,
                        onTap: () => CustomersRoutes.goList(context),
                      ),
                PermissionGate(
                  anyOf: CustomersPermissions.accountsView,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.account_balance_outlined,
                          title: l10n.customersAccountsTitle,
                          subtitle: l10n.customersAccountsCardSubtitle,
                          animationDelay: const Duration(milliseconds: 40),
                          onTap: () => CustomersRoutes.pushAccounts(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.account_balance_outlined,
                          title: l10n.customersAccountsTitle,
                          subtitle: l10n.customersAccountsCardSubtitle,
                          onTap: () => CustomersRoutes.pushAccounts(context),
                        ),
                ),
                PermissionGate(
                  anyOf: CustomersPermissions.importOp,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.upload_file_outlined,
                          title: l10n.customersImportTitle,
                          subtitle: l10n.customersImportSubtitle,
                          animationDelay: const Duration(milliseconds: 80),
                          onTap: () => CustomersRoutes.pushImport(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.upload_file_outlined,
                          title: l10n.customersImportTitle,
                          subtitle: l10n.customersImportSubtitle,
                          onTap: () => CustomersRoutes.pushImport(context),
                        ),
                ),
                PermissionGate(
                  anyOf: CustomersPermissions.settingsView,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.settings_outlined,
                          title: l10n.customersSettingsTitle,
                          subtitle: l10n.customersSettingsCardSubtitle,
                          animationDelay: const Duration(milliseconds: 120),
                          onTap: () => CustomersRoutes.pushSettings(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.settings_outlined,
                          title: l10n.customersSettingsTitle,
                          subtitle: l10n.customersSettingsCardSubtitle,
                          onTap: () => CustomersRoutes.pushSettings(context),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
