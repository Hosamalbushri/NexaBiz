import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';

/// A single report entry contributed by a module service.
@immutable
class ReportItemDefinition {
  const ReportItemDefinition({
    required this.id,
    required this.moduleId,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.path,
    this.requiredPermissions,
  });

  final String id;
  final String moduleId;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  /// Route to open when tapped. `null` indicates a coming-soon or unmapped report.
  final String? path;

  /// Optional RBAC permissions needed to view this report.
  final List<String>? requiredPermissions;

  bool get isAvailable => path != null && path!.isNotEmpty;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);
}

/// A module-contributed report category (e.g. Sales Reports, Inventory Reports).
@immutable
class ReportCategoryDefinition {
  const ReportCategoryDefinition({
    required this.id,
    required this.moduleId,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.reports = const [],
  });

  final String id;
  final String moduleId;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;
  final List<ReportItemDefinition> reports;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);
}
