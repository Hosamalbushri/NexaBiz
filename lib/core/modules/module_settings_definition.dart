import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';

/// High-level settings category definition contributed by a module.
class ModuleSettingsCategoryDefinition {
  const ModuleSettingsCategoryDefinition({
    required this.id,
    required this.moduleId,
    required this.icon,
    required this.titleBuilder,
    this.subtitleBuilder,
    required this.items,
    this.sortOrder = 100,
  });

  final String id;
  final String moduleId;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n)? subtitleBuilder;
  final List<ModuleSettingsItemDefinition> items;
  final int sortOrder;
}

/// An individual settings item or section definition within a module settings category.
class ModuleSettingsItemDefinition {
  const ModuleSettingsItemDefinition({
    required this.id,
    required this.moduleId,
    required this.icon,
    required this.titleBuilder,
    this.subtitleBuilder,
    this.path,
    this.builder,
    this.onTap,
  });

  final String id;
  final String moduleId;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n)? subtitleBuilder;
  final String? path;
  final Widget Function(BuildContext context)? builder;
  final void Function(BuildContext context)? onTap;
}
