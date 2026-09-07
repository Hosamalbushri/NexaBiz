import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';
import '../../widgets/app_page_header.dart';
import 'app_page_shell.dart';

/// Canonical Detail Page Pattern for NexaBiz ERP screens.
///
/// Standardizes Header + Summary/KPI Banner + Tabbed/Sectioned Detail cards layout.
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
    final hasTabs =
        tabs != null && tabViews != null && tabs!.length == tabViews!.length;

    Widget mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPageHeader(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: actions,
        ),
        if (summaryBanner != null) ...[
          summaryBanner!,
          const SizedBox(height: AppSpacing.lg),
        ],
        body,
      ],
    );

    if (hasTabs) {
      return DefaultTabController(
        length: tabs!.length,
        child: AppPageShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: title,
                subtitle: subtitle,
                breadcrumbs: breadcrumbs,
                actions: actions,
              ),
              if (summaryBanner != null) ...[
                summaryBanner!,
                const SizedBox(height: AppSpacing.md),
              ],
              TabBar(
                tabs: tabs!,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: TabBarView(children: tabViews!)),
            ],
          ),
        ),
      );
    }

    return AppPageShell(scrollable: true, child: mainContent);
  }
}
