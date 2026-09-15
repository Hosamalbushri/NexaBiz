import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/auth/presentation/widgets/permission_gate_core.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/shared/providers/module_hub_view_mode_provider.dart';
import 'package:stock_count/modules/currency/presentation/widgets/missing_currency_dialog.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';
import 'package:stock_count/modules/sales/shared/presentation/pages/sales_routes.dart';

/// Sales module hub.
class SalesHomePage extends ConsumerWidget {
  const SalesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(moduleHubViewModeProvider);
    final isGrid = viewMode == ModuleHubViewMode.grid;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleSales,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/sales/settings'),
          ),
        ],
      ),
      body: AppDashboardPage(
        statsGrid: const AppMissingCurrencyGuardBanner(),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppModuleHubHeader(
              title: l10n.servicesTitle,
              subtitle: l10n.moduleSalesDescription,
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
                        icon: Icons.receipt_long_outlined,
                        title: l10n.salesListTitle,
                        subtitle: l10n.salesListCardSubtitle,
                        onTap: () => SalesRoutes.goList(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.salesListTitle,
                        subtitle: l10n.salesListCardSubtitle,
                        onTap: () => SalesRoutes.goList(context),
                      ),
                PermissionGate(
                  anyOf: SalesPermissions.create,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.add_shopping_cart_outlined,
                          title: l10n.salesCreateTitle,
                          subtitle: l10n.salesCreateCardSubtitle,
                          animationDelay: const Duration(milliseconds: 60),
                          onTap: () => SalesRoutes.pushCreate(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.add_shopping_cart_outlined,
                          title: l10n.salesCreateTitle,
                          subtitle: l10n.salesCreateCardSubtitle,
                          onTap: () => SalesRoutes.pushCreate(context),
                        ),
                ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المبيعات'
                            : 'Sales Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات وإعدادات موديول المبيعات'
                            : 'Account bindings and sales master settings',
                        animationDelay: const Duration(milliseconds: 120),
                        onTap: () => context.push('/sales/settings'),
                      )
                    : AppModuleHubCard(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المبيعات'
                            : 'Sales Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات وإعدادات موديول المبيعات'
                            : 'Account bindings and sales master settings',
                        onTap: () => context.push('/sales/settings'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
