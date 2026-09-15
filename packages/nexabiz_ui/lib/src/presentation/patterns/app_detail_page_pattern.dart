import 'package:flutter/material.dart';

import '../../layout/app_details_page.dart';

/// Legacy compatible Detail Page pattern delegating to canonical [AppDetailsPage].
class AppDetailPagePattern extends StatelessWidget {
  const AppDetailPagePattern({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.breadcrumbs,
    this.summaryBanner,
    this.actions,
    this.tabs,
    this.tabViews,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final Widget? summaryBanner;
  final List<Widget>? actions;
  final Widget body;

  final List<Tab>? tabs;
  final List<Widget>? tabViews;

  @override
  Widget build(BuildContext context) {
    return AppDetailsPage(
      title: title,
      subtitle: subtitle,
      breadcrumbs: breadcrumbs,
      summaryBanner: summaryBanner,
      actions: actions,
      body: body,
      tabs: tabs,
      tabViews: tabViews,
    );
  }
}
