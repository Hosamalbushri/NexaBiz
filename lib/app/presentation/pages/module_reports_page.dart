import 'package:flutter/material.dart';

import 'module_unit_reports_page.dart';

/// Legacy alias for [ModuleUnitReportsPage].
/// Renders unit reports for [moduleId] dynamically via [ReportsModule.reportCategories].
class ModuleReportsPage extends StatelessWidget {
  const ModuleReportsPage({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return ModuleUnitReportsPage(moduleId: moduleId);
  }
}
