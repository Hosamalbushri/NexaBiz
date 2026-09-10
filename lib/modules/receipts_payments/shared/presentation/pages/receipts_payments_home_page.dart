import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/auth/presentation/widgets/permission_gate_core.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/shared/providers/module_hub_view_mode_provider.dart';
import 'package:stock_count/modules/currency/presentation/widgets/missing_currency_dialog.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import 'receipts_payments_routes.dart';

/// Receipts & Payments module hub — one entry per service.
class ReceiptsPaymentsHomePage extends ConsumerWidget {
  const ReceiptsPaymentsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(moduleHubViewModeProvider);
    final isGrid = viewMode == ModuleHubViewMode.grid;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleReceiptsPayments,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/receipts-payments/settings'),
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
              subtitle: l10n.moduleReceiptsPaymentsDescription,
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
                PermissionGate(
                  anyOf: ReceiptsPaymentsPermissions.receiptsView,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.call_received_outlined,
                          title: l10n.rpServiceReceiptsTitle,
                          subtitle: l10n.rpServiceReceiptsSubtitle,
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushReceiptsMenu(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.call_received_outlined,
                          title: l10n.rpServiceReceiptsTitle,
                          subtitle: l10n.rpServiceReceiptsSubtitle,
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushReceiptsMenu(context),
                        ),
                ),
                PermissionGate(
                  anyOf: ReceiptsPaymentsPermissions.paymentsView,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.call_made_outlined,
                          title: l10n.rpServicePaymentsTitle,
                          subtitle: l10n.rpServicePaymentsSubtitle,
                          animationDelay: const Duration(milliseconds: 60),
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushPaymentsMenu(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.call_made_outlined,
                          title: l10n.rpServicePaymentsTitle,
                          subtitle: l10n.rpServicePaymentsSubtitle,
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushPaymentsMenu(context),
                        ),
                ),
                PermissionGate(
                  anyOf: ReceiptsPaymentsPermissions.transfersView,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.swap_horiz_outlined,
                          title: l10n.rpServiceTransfersTitle,
                          subtitle: l10n.rpServiceTransfersSubtitle,
                          animationDelay: const Duration(milliseconds: 120),
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushTransfersMenu(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.swap_horiz_outlined,
                          title: l10n.rpServiceTransfersTitle,
                          subtitle: l10n.rpServiceTransfersSubtitle,
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushTransfersMenu(context),
                        ),
                ),
                PermissionGate(
                  anyOf: ReceiptsPaymentsPermissions.exchangesView,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.currency_exchange_outlined,
                          title: l10n.rpServiceExchangesTitle,
                          subtitle: l10n.rpServiceExchangesSubtitle,
                          animationDelay: const Duration(milliseconds: 180),
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushExchangesMenu(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.currency_exchange_outlined,
                          title: l10n.rpServiceExchangesTitle,
                          subtitle: l10n.rpServiceExchangesSubtitle,
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushExchangesMenu(context),
                        ),
                ),
                PermissionGate(
                  anyOf: ReceiptsPaymentsPermissions.anyPost,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.fact_check_outlined,
                          title: l10n.rpPostingServiceTitle,
                          subtitle: l10n.rpPostingServiceHubSubtitle,
                          animationDelay: const Duration(milliseconds: 240),
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushPostingService(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.fact_check_outlined,
                          title: l10n.rpPostingServiceTitle,
                          subtitle: l10n.rpPostingServiceHubSubtitle,
                          onTap: () =>
                              ReceiptsPaymentsRoutes.pushPostingService(context),
                        ),
                ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المقبوضات والمدفوعات'
                            : 'Receipts & Payments Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات المحاسبية وإعدادات الموديول'
                            : 'Account bindings and module settings',
                        animationDelay: const Duration(milliseconds: 300),
                        onTap: () => context.push('/receipts-payments/settings'),
                      )
                    : AppModuleHubCard(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المقبوضات والمدفوعات'
                            : 'Receipts & Payments Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات المحاسبية وإعدادات الموديول'
                            : 'Account bindings and module settings',
                        onTap: () => context.push('/receipts-payments/settings'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
