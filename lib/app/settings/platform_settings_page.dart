import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/di/app_providers.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_providers.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../notifications/presentation/providers/notifications_provider.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import '../sync/sync_settings_section.dart';
import '../sync/sync_status_indicator.dart';
import '../theme/app_spacing.dart';
import 'company/company_profile_providers.dart';
import 'settings_repository.dart';
import 'widgets/settings_chrome.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Platform settings as collapsible accordion sections.
class PlatformSettingsPage extends ConsumerWidget {
  const PlatformSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final repository = ref.read(settingsRepositoryProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final modules = ref
        .watch(moduleRegistryProvider)
        .enabledModules
        .where((m) => m.hasSettings)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.settingsTitle,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
        actions: const [SyncStatusIndicator()],
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          SettingsExpandableSection(
            icon: Icons.business_outlined,
            title: l10n.setupSettingsTitle,
            subtitle: l10n.setupSettingsCardSubtitle,
            initiallyExpanded: true,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apartment_outlined),
                title: Text(l10n.setupSettingsTitle),
                subtitle: Text(l10n.setupSettingsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsSetup),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsExpandableSection(
            icon: Icons.tune_outlined,
            title: l10n.settingsGeneralSection,
            subtitle: l10n.settingsGeneralSectionSubtitle,
            children: [
              Text(
                l10n.appearance,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.lightTheme),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.darkTheme),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.systemTheme),
                    icon: const Icon(Icons.brightness_auto_outlined),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selected) async {
                  final value = selected.first;
                  ref.read(themeModeProvider.notifier).state = value;
                  await repository.saveThemeMode(value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.language,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<Locale>(
                segments: [
                  ButtonSegment(
                    value: AppConstants.englishLocale,
                    label: Text(l10n.english),
                    icon: const Icon(Icons.language),
                  ),
                  ButtonSegment(
                    value: AppConstants.arabicLocale,
                    label: Text(l10n.arabic),
                    icon: const Icon(Icons.translate_outlined),
                  ),
                ],
                selected: {locale ?? AppConstants.englishLocale},
                onSelectionChanged: (selected) async {
                  final value = selected.first;
                  ref.read(localeProvider.notifier).state = value;
                  await repository.saveLocale(value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsExpandableSection(
            icon: Icons.cloud_sync_outlined,
            title: l10n.settingsDataSection,
            subtitle: l10n.settingsDataSectionSubtitle,
            children: const [SyncSettingsSection(embedded: true)],
          ),
          for (final module in modules) ...[
            const SizedBox(height: AppSpacing.sm),
            _ModuleExpandableSettings(module: module),
          ],
          const SizedBox(height: AppSpacing.sm),
          SettingsExpandableSection(
            icon: Icons.info_outline,
            title: l10n.about,
            subtitle: l10n.settingsAboutSectionSubtitle,
            children: [
              packageInfo.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (info) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.apps_outlined),
                        title: Text(l10n.applicationName),
                        subtitle: Text(info.appName),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.tag_outlined),
                        title: Text(l10n.version),
                        subtitle: Text(info.version),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.numbers_outlined),
                        title: Text(l10n.buildNumber),
                        subtitle: Text(info.buildNumber),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
            child: ListTile(
              leading: Icon(
                Icons.restart_alt_outlined,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.resetApplication,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(l10n.settingsResetHint),
              onTap: () => _resetSettings(context, ref, repository),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
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
    for (final module in ref.read(moduleRegistryProvider).enabledModules) {
      module.onSettingsReset(ref);
    }

    if (!context.mounted) {
      return;
    }
    showAppSnackBar(context, message: l10n.success, isSuccess: true);
  }
}

class _ModuleExpandableSettings extends StatelessWidget {
  const _ModuleExpandableSettings({required this.module});

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
