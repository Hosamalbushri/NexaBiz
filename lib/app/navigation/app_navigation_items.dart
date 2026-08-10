import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../router/app_routes.dart';

/// A top-level shell destination (App-owned, not module-specific).
@immutable
class AppNavigationItem {
  const AppNavigationItem({
    required this.id,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.labelBuilder,
  });

  final String id;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) labelBuilder;

  String label(AppLocalizations l10n) => labelBuilder(l10n);
}

/// Central list of StatefulShellRoute branch destinations.
List<AppNavigationItem> appNavigationItems() {
  return const [
    AppNavigationItem(
      id: 'dashboard',
      path: AppRoutes.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      labelBuilder: _dashboardLabel,
    ),
    AppNavigationItem(
      id: 'services',
      path: AppRoutes.services,
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps_rounded,
      labelBuilder: _servicesLabel,
    ),
    AppNavigationItem(
      id: 'reports',
      path: AppRoutes.reports,
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment_rounded,
      labelBuilder: _reportsLabel,
    ),
    AppNavigationItem(
      id: 'settings',
      path: AppRoutes.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      labelBuilder: _settingsLabel,
    ),
  ];
}

String _dashboardLabel(AppLocalizations l10n) => l10n.navigationDashboard;
String _servicesLabel(AppLocalizations l10n) => l10n.navigationServices;
String _reportsLabel(AppLocalizations l10n) => l10n.navigationReports;
String _settingsLabel(AppLocalizations l10n) => l10n.settingsTitle;

/// Resolves which bottom-nav destination should appear selected for [path].
///
/// Returns `-1` when [path] is not a shell destination (e.g. module pages),
/// so no tab looks active — including **Services**, which is selected only on
/// `/services` itself.
int selectedNavigationIndex(String path) {
  final items = appNavigationItems();
  for (var i = 0; i < items.length; i++) {
    final itemPath = items[i].path;
    if (path == itemPath || path.startsWith('$itemPath/')) {
      return i;
    }
  }
  return -1;
}
