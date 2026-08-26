import 'package:flutter/material.dart';

import '../../app/router/app_routes.dart';
import '../../core/modules/module_settings_definition.dart';

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
