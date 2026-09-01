import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
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
import '../../core/widgets/empty_state_widget.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../notifications/presentation/providers/notifications_provider.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import '../sync/app_bar_sync_actions.dart';
import '../sync/sync_enabled_provider.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/authentication/presentation/widgets/company_selection_sheet.dart';
import 'company/company_profile.dart';
import 'company/company_profile_providers.dart';
import 'module_unit_settings_page.dart';
import 'modules_settings_page.dart';
import 'settings_repository.dart';
import 'subscription_packages_page.dart';
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
                    onTap: () => _saveTheme(
                      ref,
                      repository,
                      ThemeMode.light,
                    ),
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
                    onTap: () => _saveTheme(
                      ref,
                      repository,
                      ThemeMode.dark,
                    ),
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
                    onTap: () => _saveTheme(
                      ref,
                      repository,
                      ThemeMode.system,
                    ),
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
              subtitle: companyAsync.asData?.value.name ?? l10n.systemSetupEditCompany,
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
        if (categories.isNotEmpty) ...[
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.grid_view_rounded,
                title: l10n.moduleUnitsSettingsTitle,
                subtitle: l10n.moduleUnitsSettingsSubtitle,
                showChevron: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ModulesSettingsPage(categories: categories),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
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



class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.category});

  final ModuleSettingsCategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = category.titleBuilder(l10n);
    final subtitle = category.subtitleBuilder?.call(l10n) ??
        (l10n.localeName == 'ar'
            ? '${category.items.length} وحدات إعدادات'
            : '${category.items.length} setting units');

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleUnitSettingsPage(category: category),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: AppShadows.card(theme.brightness),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  ),
                  child: Icon(
                    category.icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
