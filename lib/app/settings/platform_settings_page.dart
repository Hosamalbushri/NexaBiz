import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/di/app_providers.dart';
import '../../core/modules/module_providers.dart';
import '../../core/modules/module_settings_definition.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_responsive.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../notifications/presentation/providers/notifications_provider.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import '../sync/app_bar_sync_actions.dart';
import '../sync/sync_enabled_provider.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/authentication/presentation/widgets/company_selection_sheet.dart';
import 'company/company_profile.dart';
import 'company/company_profile_providers.dart';
import 'settings_repository.dart';

import 'widgets/settings_chrome.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Platform settings hub — grouped, professional preference layout with modular tabs.
class PlatformSettingsPage extends ConsumerWidget {
  const PlatformSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final registry = ref.watch(moduleRegistryProvider);
    final categories = registry.allSettingsCategories;
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.settingsTitle,
        centerTitle: true,
        leading: const AppBarSyncActions(),
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
      ),
      body: const _PlatformSettingsBody(),
    );
  }
}

class _PlatformSettingsBody extends ConsumerWidget {
  const _PlatformSettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final companyAsync = ref.watch(companyProfileProvider);
    final syncOverview =
        ref.watch(syncOverviewProvider).asData?.value ?? SyncOverview.initial();
    final syncEnabled = ref.watch(syncEnabledProvider);
    final repository = ref.read(settingsRepositoryProvider);
    final registry = ref.watch(moduleRegistryProvider);
    final categories = registry.allSettingsCategories;
    final pageInsets = AppConstants.pageInsets(context);

    return AppContentConstraint(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: pageInsets.left,
              right: pageInsets.right,
              top: pageInsets.top,
              bottom: AppSpacing.sm,
            ),
            child: _CompanyHeaderCard(
              profile: companyAsync.asData?.value,
              onTap: () => context.push(AppRoutes.settingsSetup),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: pageInsets.left,
                right: pageInsets.right,
                bottom: pageInsets.bottom,
              ),
              children: [
                SettingsExpandableSection(
                  icon: Icons.tune_rounded,
                  title: l10n.settingsGeneralSection,
                  subtitle: l10n.settingsGeneralSectionSubtitle,
                  children: [
                    Text(
                      l10n.appearance,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.light_mode_outlined,
                            label: l10n.lightTheme,
                            showLabel: false,
                            dense: true,
                            selected: themeMode == ThemeMode.light,
                            onTap: () =>
                                _saveTheme(ref, repository, ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.dark_mode_outlined,
                            label: l10n.darkTheme,
                            showLabel: false,
                            dense: true,
                            selected: themeMode == ThemeMode.dark,
                            onTap: () =>
                                _saveTheme(ref, repository, ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.brightness_auto_outlined,
                            label: l10n.systemTheme,
                            showLabel: false,
                            dense: true,
                            selected: themeMode == ThemeMode.system,
                            onTap: () =>
                                _saveTheme(ref, repository, ThemeMode.system),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.language,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.language_rounded,
                            label: l10n.english,
                            dense: true,
                            selected:
                                (locale ?? AppConstants.englishLocale) ==
                                AppConstants.englishLocale,
                            onTap: () => _saveLocale(
                              ref,
                              repository,
                              AppConstants.englishLocale,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.translate_rounded,
                            label: l10n.arabic,
                            dense: true,
                            selected:
                                (locale ?? AppConstants.englishLocale) ==
                                AppConstants.arabicLocale,
                            onTap: () => _saveLocale(
                              ref,
                              repository,
                              AppConstants.arabicLocale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.store_outlined,
                      title: l10n.setupSettingsTitle,
                      subtitle:
                          companyAsync.asData?.value.name ??
                          l10n.systemSetupEditCompany,
                      showChevron: true,
                      onTap: () => context.push(AppRoutes.settingsSetup),
                    ),
                    SettingsTile(
                      icon: Icons.business_outlined,
                      title: l10n.authSelectCompanyTitle,
                      subtitle: companyAsync.asData?.value.name ?? '',
                      showChevron: true,
                      onTap: () => CompanySelectionSheet.show(context),
                    ),
                    SettingsTile(
                      icon: Icons.currency_exchange_outlined,
                      title: Localizations.localeOf(context).languageCode == 'ar'
                          ? 'إدارة سجل العملات والرسوم'
                          : 'Currency Master & Roles Management',
                      subtitle: Localizations.localeOf(context).languageCode == 'ar'
                          ? 'تحديد العملة الرئيسية، عملة تقييم المخزون، وسجل أسعار الصرف'
                          : 'Manage functional currency, inventory valuation currency, and master currencies',
                      showChevron: true,
                      onTap: () => context.push(AppRoutes.settingsCurrencies),
                    ),
                    SettingsTile(
                      icon: Icons.star_outline,
                      title: l10n.subscriptionAndPackagesTitle,
                      subtitle: l10n.subscriptionAndPackagesSubtitle,
                      showChevron: true,
                      onTap: () => context.push(AppRoutes.settingsSubscription),
                    ),
                    SettingsTile(
                      icon: Icons.shield_outlined,
                      title: l10n.appLockSettingsTitle,
                      subtitle: ref.watch(appLockControllerProvider).enabled
                          ? l10n.appLockSettingsEnabledHint
                          : l10n.appLockSettingsDisabledHint,
                      showChevron: true,
                      onTap: () => context.push(AppRoutes.settingsSecurity),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsExpandableSection(
                  icon: Icons.apps_outlined,
                  title: Localizations.localeOf(context).languageCode == 'ar'
                      ? 'إعدادات الموديولات'
                      : 'Module Settings Hub',
                  subtitle: Localizations.localeOf(context).languageCode == 'ar'
                      ? 'تهيئة وإعدادات كربط الحسابات والإعدادات الخاصة بكل موديول'
                      : 'Configure account bindings and module master settings',
                  initiallyExpanded: true,
                  children: [
                    SettingsGroup(
                      children: [
                        SettingsTile(
                          icon: Icons.inventory_2_outlined,
                          title: l10n.moduleInventory,
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعدادات وتهيئة موديول المخزون والمستودعات'
                              : 'Inventory master settings & account bindings',
                          showChevron: true,
                          onTap: () => context.push('/inventory/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.account_balance_outlined,
                          title: l10n.moduleAccounting,
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعدادات وتهيئة موديول المحاسبة والدفاتر'
                              : 'Accounting master settings & account bindings',
                          showChevron: true,
                          onTap: () => context.push('/accounting/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.point_of_sale_outlined,
                          title: l10n.moduleSales,
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعدادات وتهيئة موديول المبيعات'
                              : 'Sales master settings & account bindings',
                          showChevron: true,
                          onTap: () => context.push('/sales/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.shopping_bag_outlined,
                          title: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'المشتريات والموردين'
                              : 'Purchases & Suppliers',
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعدادات وتهيئة موديول المشتريات'
                              : 'Purchases master settings & account bindings',
                          showChevron: true,
                          onTap: () => context.push('/purchases/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: l10n.moduleReceiptsPayments,
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعدادات وتهيئة موديول المقبوضات والمدفوعات'
                              : 'Receipts & Payments settings & account bindings',
                          showChevron: true,
                          onTap: () => context.push('/receipts-payments/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.people_outline,
                          title: l10n.moduleCustomers,
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إعدادات وتهيئة موديول العملاء والدليل'
                              : 'Customers settings & account bindings',
                          showChevron: true,
                          onTap: () => context.push('/customers/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.admin_panel_settings_outlined,
                          title: l10n.moduleAdministration,
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إدارة المستخدمين، الأدوار، الفروع، والأجهزة'
                              : 'Administer users, roles, branches, & devices',
                          showChevron: true,
                          onTap: () => context.push('/administration/settings'),
                        ),
                        SettingsTile(
                          icon: Icons.sync_outlined,
                          title: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'مزامنة البيانات'
                              : 'Data Sync',
                          subtitle: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'مراقبة المزامنة وفض التعارضات السحابية'
                              : 'Monitor cloud sync status & conflict strategy',
                          showChevron: true,
                          onTap: () => context.push(AppRoutes.settingsDataSync),
                        ),
                      ],
                    ),
                  ],
                ),

                SettingsExpandableSection(
                  icon: Icons.info_outline_rounded,
                  title: l10n.about,
                  subtitle: l10n.settingsAboutSectionSubtitle,
                  children: [
                    packageInfo.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => Text(
                        l10n.settingsAboutSectionSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      data: (info) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AboutInfoRow(
                            icon: Icons.apps_outlined,
                            label: l10n.applicationName,
                            value: info.appName,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _AboutInfoRow(
                            icon: Icons.tag_outlined,
                            label: l10n.version,
                            value: '${info.version} (${info.buildNumber})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.restart_alt_rounded,
                      iconColor: colorScheme.error,
                      titleColor: colorScheme.error,
                      title: l10n.resetApplication,
                      subtitle: l10n.settingsResetHint,
                      onTap: () => _resetSettings(context, ref, repository),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTheme(
    WidgetRef ref,
    SettingsRepository repository,
    ThemeMode value,
  ) async {
    ref.read(themeModeProvider.notifier).state = value;
    await repository.saveThemeMode(value);
  }

  Future<void> _saveLocale(
    WidgetRef ref,
    SettingsRepository repository,
    Locale value,
  ) async {
    ref.read(localeProvider.notifier).state = value;
    await repository.saveLocale(value);
  }

  Future<void> _resetSettings(
    BuildContext context,
    WidgetRef ref,
    SettingsRepository repository,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog(
      context: context,
      title: l10n.resetApplicationConfirmationTitle,
      message: l10n.resetApplicationConfirmationMessage,
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await repository.resetSettings();
    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    ref.read(localeProvider.notifier).state = null;
    ref.invalidate(dashboardServicesProvider);
    ref.invalidate(companyProfileProvider);
    for (final module in ref.read(moduleRegistryProvider).modules) {
      module.onSettingsReset(ref);
    }

    if (!context.mounted) {
      return;
    }
    showAppSnackBar(context, message: l10n.success, isSuccess: true);
  }
}



class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyHeaderCard extends StatelessWidget {
  const _CompanyHeaderCard({required this.profile, required this.onTap});

  final CompanyProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()
        : l10n.systemSetupEditCompany;

    return Material(
      color: colorScheme.surface,
      elevation: 1.25,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md - 2,
          ),
          child: Row(
            children: [
              _CompanyAvatar(profile: profile),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  l10n.localeName == 'ar' ? 'تعديل' : 'Edit',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({required this.profile});

  final CompanyProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final logoPath = profile?.logoPath;
    final hasLogo = logoPath != null && File(logoPath).existsSync();
    final initial = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim().characters.first.toUpperCase()
        : 'B';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: hasLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.file(
                File(logoPath),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
    );
  }
}
