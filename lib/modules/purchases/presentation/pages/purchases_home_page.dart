import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/auth/presentation/widgets/permission_gate_core.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../shared/providers/module_hub_view_mode_provider.dart';
import '../../../currency/presentation/widgets/missing_currency_dialog.dart';
import '../../permissions/purchases_permission_package.dart';
import '../../shared/presentation/pages/purchases_routes.dart';

/// Purchases Management Dashboard & Home Page
class PurchasesHomePage extends ConsumerWidget {
  const PurchasesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(moduleHubViewModeProvider);
    final isGrid = viewMode == ModuleHubViewMode.grid;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar'
            ? 'المشتريات والموردين'
            : 'Purchases & Suppliers',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => PurchasesRoutes.pushSettings(context),
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
              subtitle: l10n.localeName == 'ar'
                  ? 'إدارة أوامر الشراء، فواتير المشتريات، والموردين'
                  : 'Purchase Orders, Vendor Invoices, and Supplier Catalog',
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
                        icon: Icons.people_alt_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'دليل الموردين'
                            : 'Suppliers Directory',
                        subtitle: l10n.localeName == 'ar'
                            ? 'إدارة بيانات الموردين وأرصدتهم والحسابات المربوطة'
                            : 'Manage supplier profiles, balances, and linked accounts',
                        onTap: () => PurchasesRoutes.pushSuppliers(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.people_alt_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'دليل الموردين'
                            : 'Suppliers Directory',
                        subtitle: l10n.localeName == 'ar'
                            ? 'إدارة بيانات الموردين وأرصدتهم والحسابات المربوطة'
                            : 'Manage supplier profiles, balances, and linked accounts',
                        onTap: () => PurchasesRoutes.pushSuppliers(context),
                      ),
                PermissionGate(
                  anyOf: PurchasesPermissions.view,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.localeName == 'ar'
                              ? 'فواتير المشتريات'
                              : 'Purchase Invoices',
                          subtitle: l10n.localeName == 'ar'
                              ? 'إنشاء واستعراض فواتير المشتريات وترحيل قيود المخزون'
                              : 'Create, review, and post vendor purchase invoices',
                          animationDelay: const Duration(milliseconds: 60),
                          onTap: () => PurchasesRoutes.pushInvoices(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.localeName == 'ar'
                              ? 'فواتير المشتريات'
                              : 'Purchase Invoices',
                          subtitle: l10n.localeName == 'ar'
                              ? 'إنشاء واستعراض فواتير المشتريات وترحيل قيود المخزون'
                              : 'Create, review, and post vendor purchase invoices',
                          onTap: () => PurchasesRoutes.pushInvoices(context),
                        ),
                ),
                PermissionGate(
                  anyOf: PurchasesPermissions.view,
                  child: isGrid
                      ? AppModuleHubTile(
                          icon: Icons.inventory_2_outlined,
                          title: l10n.localeName == 'ar'
                              ? 'إشعارات الاستلام والمخزون'
                              : 'Goods Receipts',
                          subtitle: l10n.localeName == 'ar'
                              ? 'متابعة الشحنات المستلمة ومطابقة أوامر الشراء'
                              : 'Track incoming shipments and match purchase orders',
                          animationDelay: const Duration(milliseconds: 120),
                          onTap: () => PurchasesRoutes.pushReceipts(context),
                        )
                      : AppModuleHubCard(
                          icon: Icons.inventory_2_outlined,
                          title: l10n.localeName == 'ar'
                              ? 'إشعارات الاستلام والمخزون'
                              : 'Goods Receipts',
                          subtitle: l10n.localeName == 'ar'
                              ? 'متابعة الشحنات المستلمة ومطابقة أوامر الشراء'
                              : 'Track incoming shipments and match purchase orders',
                          onTap: () => PurchasesRoutes.pushReceipts(context),
                        ),
                ),
                isGrid
                    ? AppModuleHubTile(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المشتريات'
                            : 'Purchases Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات المحاسبية وإعدادات موديول المشتريات'
                            : 'Account bindings and purchases master settings',
                        animationDelay: const Duration(milliseconds: 180),
                        onTap: () => PurchasesRoutes.pushSettings(context),
                      )
                    : AppModuleHubCard(
                        icon: Icons.tune_outlined,
                        title: l10n.localeName == 'ar'
                            ? 'إعدادات المشتريات'
                            : 'Purchases Settings',
                        subtitle: l10n.localeName == 'ar'
                            ? 'ربط الحسابات المحاسبية وإعدادات موديول المشتريات'
                            : 'Account bindings and purchases master settings',
                        onTap: () => PurchasesRoutes.pushSettings(context),
                      ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: PermissionGate(
        anyOf: PurchasesPermissions.create,
        child: FloatingActionButton.extended(
          onPressed: () => PurchasesRoutes.pushCreateInvoice(context),
          icon: const Icon(Icons.add),
          label: Text(
            l10n.localeName == 'ar'
                ? 'فاتورة مشتريات جديدة'
                : 'New Purchase Invoice',
          ),
        ),
      ),
    );
  }
}
