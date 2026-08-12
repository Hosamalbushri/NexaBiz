import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../notifications/presentation/providers/notifications_provider.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import '../sync/sync_settings_section.dart';
import '../sync/sync_status_indicator.dart';
import '../theme/app_spacing.dart';
import '../../core/di/app_providers.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import 'settings_repository.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Platform settings: appearance, language, and about.
class PlatformSettingsPage extends ConsumerWidget {
  const PlatformSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final repository = ref.read(settingsRepositoryProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: localization.settingsTitle,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
        actions: const [SyncStatusIndicator()],
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          _SectionHeader(title: localization.appearance),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(localization.lightTheme),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (value) async {
                    if (value == null) return;
                    ref.read(themeModeProvider.notifier).state = value;
                    await repository.saveThemeMode(value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(localization.darkTheme),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (value) async {
                    if (value == null) return;
                    ref.read(themeModeProvider.notifier).state = value;
                    await repository.saveThemeMode(value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(localization.systemTheme),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (value) async {
                    if (value == null) return;
                    ref.read(themeModeProvider.notifier).state = value;
                    await repository.saveThemeMode(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _SectionHeader(title: localization.language),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                RadioListTile<Locale>(
                  title: Text(localization.english),
                  value: AppConstants.englishLocale,
                  groupValue: locale ?? AppConstants.englishLocale,
                  onChanged: (value) async {
                    if (value == null) return;
                    ref.read(localeProvider.notifier).state = value;
                    await repository.saveLocale(value);
                  },
                ),
                RadioListTile<Locale>(
                  title: Text(localization.arabic),
                  value: AppConstants.arabicLocale,
                  groupValue: locale ?? AppConstants.englishLocale,
                  onChanged: (value) async {
                    if (value == null) return;
                    ref.read(localeProvider.notifier).state = value;
                    await repository.saveLocale(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          const SyncSettingsSection(),
          const SizedBox(height: AppSpacing.section),
          _SectionHeader(title: localization.about),
          AppCard(
            padding: EdgeInsets.zero,
            child: packageInfo.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppConstants.pagePadding),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (info) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(localization.applicationName),
                      subtitle: Text(info.appName),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(localization.version),
                      subtitle: Text(info.version),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(localization.buildNumber),
                      subtitle: Text(info.buildNumber),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.restart_alt_outlined),
              title: Text(localization.resetApplication),
              onTap: () => _resetSettings(context, ref, repository),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings(
    BuildContext context,
    WidgetRef ref,
    SettingsRepository repository,
  ) async {
    final localization = AppLocalizations.of(context);
    final confirmed = await showAppDialog(
      context: context,
      title: localization.resetApplicationConfirmationTitle,
      message: localization.resetApplicationConfirmationMessage,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await repository.resetSettings();
    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    ref.read(localeProvider.notifier).state = null;
    ref.invalidate(dashboardServicesProvider);

    if (!context.mounted) {
      return;
    }
    showAppSnackBar(context, message: localization.success, isSuccess: true);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
