import 'package:flutter/material.dart';

import '../../core/modules/quick_nav_definition.dart';

List<QuickNavDefinition> buildReportsQuickNav(String moduleId) {
  return [
    QuickNavDefinition(
      id: 'quick_nav_reports',
      icon: Icons.bar_chart_outlined,
      titleBuilder: (l10n) => l10n.moduleReports,
      subtitleBuilder: (l10n) => l10n.moduleReportsDescription,
      routePath: '/reports',
      requiredPermissions: const ['reports.view'],
    ),
  ];
}
