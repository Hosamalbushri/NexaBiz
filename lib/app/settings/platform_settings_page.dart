import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/di/app_providers.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_providers.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../modules/system_setup/system_setup_module.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../notifications/presentation/providers/notifications_provider.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import '../sync/app_bar_sync_actions.dart';
import '../sync/sync_settings_section.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'company/company_profile.dart';
import 'company/company_profile_providers.dart';
import 'settings_repository.dart';
import 'widgets/settings_chrome.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Platform settings hub — grouped, professional preference layout.
class PlatformSettingsPage extends ConsumerWidget {
  const PlatformSettingsPage({super.key});

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
    final repository = ref.read(settingsRepositoryProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final modules = ref
        .watch(moduleRegistryProvider)
        .modules
        .where(
          (m) =>
              m.id != SystemSetupModule.moduleId &&
              m.isEnabled &&
              m.hasSettings,
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.settingsTitle,
        centerTitle: false,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
        actions: const [AppBarSyncActions()],
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          _CompanyHeaderCard(
            profile: companyAsync.asData?.value,
            onTap: () => context.push(AppRoutes.settingsSetup),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroupLabel(l10n.settingsGeneralSection),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.appearance,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.light_mode_outlined,
                            label: l10n.lightTheme,
                            showLabel: false,
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
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.language,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SettingsChoiceCard(
                            icon: Icons.language_rounded,
                            label: l10n.english,
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroupLabel(l10n.settingsDataSection),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: syncOverview.isOnline
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                iconColor: syncOverview.isOnline
                    ? colorScheme.primary
                    : colorScheme.outline,
                title: l10n.syncConnectionLabel,
                subtitle: syncOverview.isOnline
                    ? l10n.syncConnectionOnline
                    : l10n.syncConnectionOffline,
                trailing: _SyncPhaseChip(overview: syncOverview),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SyncSettingsSection(embedded: true, compactHeader: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroupLabel(l10n.setupSettingsTitle),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.apartment_outlined,
                title: l10n.systemSetupEditCompany,
                subtitle: l10n.setupSettingsCardSubtitle,
                showChevron: true,
                onTap: () => context.push(AppRoutes.settingsSetup),
              ),
            ],
          ),
          if (modules.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SettingsGroupLabel(l10n.settingsModulesSection),
            Text(
              l10n.settingsModulesSectionSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final module in modules) ...[
              _ModuleSettingsCard(module: module),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          SettingsGroupLabel(l10n.about),
          packageInfo.when(
            loading: () => SettingsGroup(
              children: const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (_, _) => SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.info_outline,
                  title: l10n.about,
                  subtitle: l10n.settingsAboutSectionSubtitle,
                ),
              ],
            ),
            data: (info) => SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.apps_outlined,
                  title: l10n.applicationName,
                  subtitle: info.appName,
                ),
                SettingsTile(
                  icon: Icons.tag_outlined,
                  title: l10n.version,
                  subtitle: '${info.version} (${info.buildNumber})',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
        : l10n.setupSettingsTitle;
    final subtitle = [
      if (profile?.defaultCurrencyCode.isNotEmpty ?? false)
        profile!.defaultCurrencyCode,
      if (profile?.city?.trim().isNotEmpty ?? false) profile!.city!.trim(),
    ].join(' · ');

    return Material(
      color: colorScheme.surface,
      elevation: 1.25,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _CompanyAvatar(profile: profile),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isEmpty
                          ? l10n.setupSettingsCardSubtitle
                          : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                color: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final logoPath = profile?.logoPath;
    final hasLogo = logoPath != null && File(logoPath).existsSync();
    final initial = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim().characters.first.toUpperCase()
        : 'B';

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        image: hasLogo
            ? DecorationImage(
                image: FileImage(File(logoPath)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasLogo
          ? null
          : Text(
              initial,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
    );
  }
}

class _SyncPhaseChip extends StatelessWidget {
  const _SyncPhaseChip({required this.overview});

  final SyncOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (overview.phase) {
      SyncPhase.offline => (l10n.syncStatusOffline, colorScheme.outline),
      SyncPhase.syncing => (l10n.syncStatusSyncing, colorScheme.primary),
      SyncPhase.pending => (l10n.syncStatusPending, colorScheme.tertiary),
      SyncPhase.failed => (l10n.syncStatusFailed, colorScheme.error),
      SyncPhase.conflict => (l10n.syncStatusConflict, colorScheme.error),
      SyncPhase.idleSynced => (l10n.syncStatusSynced, colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModuleSettingsCard extends StatelessWidget {
  const _ModuleSettingsCard({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final sections = module.buildSettingsSections(context);
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return SettingsExpandableSection(
      icon: module.icon,
      title: module.label(context),
      subtitle: module.description(context),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          sections[i],
        ],
      ],
    );
  }
}
