import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/router/app_routes.dart';
import '../../app/settings/widgets/settings_chrome.dart';
import '../../app/sync/sync_enabled_provider.dart';
import '../../core/modules/module_settings_definition.dart';
import 'sync.dart';

List<ModuleSettingsCategoryDefinition> buildSyncSettingsCategories(String moduleId) {
  return [
    ModuleSettingsCategoryDefinition(
      id: 'sync_settings_cat',
      moduleId: moduleId,
      icon: Icons.cloud_sync_outlined,
      titleBuilder: (l10n) => l10n.settingsDataSection,
      subtitleBuilder: (l10n) => l10n.settingsDataSection,
      items: [
        ModuleSettingsItemDefinition(
          id: 'sync_cloud_settings',
          moduleId: moduleId,
          icon: Icons.cloud_sync_outlined,
          path: AppRoutes.settingsDataSync,
          titleBuilder: (l10n) => l10n.settingsDataSection,
          subtitleBuilder: (l10n) => l10n.settingsDataSection,
        ),
      ],
    ),
  ];
}

/// Settings tile section injected by SyncModule into the platform settings page.
class SyncSettingsTileSection extends ConsumerWidget {
  const SyncSettingsTileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final syncOverview =
        ref.watch(syncOverviewProvider).asData?.value ?? SyncOverview.initial();
    final syncEnabled = ref.watch(syncEnabledProvider);

    return SettingsGroup(
      children: [
        SettingsTile(
          icon: Icons.cloud_sync_outlined,
          title: l10n.settingsDataSection,
          subtitle: syncEnabled
              ? (syncOverview.isOnline
                    ? l10n.syncConnectionOnline
                    : l10n.syncConnectionOffline)
              : l10n.subscriptionAndPackagesSubtitle,
          showChevron: true,
          onTap: () => context.push(AppRoutes.settingsDataSync),
        ),
      ],
    );
  }
}
