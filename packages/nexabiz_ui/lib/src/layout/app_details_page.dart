import 'package:flutter/material.dart';

import '../widgets/app_error_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_page_header.dart';
import 'app_layout_tokens.dart';
import 'app_page.dart';

/// Canonical Detail Page layout component for NexaBiz ERP screens.
///
/// Standardizes Header + Summary/KPI Banner + Tabbed/Sectioned detail view.
class AppDetailsPage extends StatelessWidget {
  const AppDetailsPage({
    super.key,
    required this.title,
    this.body = const SizedBox.shrink(),
    this.subtitle,
    this.breadcrumbs,
    this.summaryBanner,
    this.actions,
    this.tabs,
    this.tabViews,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.isLoading = false,
    String? errorText,
    String? error,
    this.emptyState,
    this.onRetry,
    this.maxWidth = AppLayoutTokens.maxDetailsWidth,
  }) : errorText = errorText ?? error;

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final Widget? summaryBanner;
  final List<Widget>? actions;
  final Widget body;

  final List<Tab>? tabs;
  final List<Widget>? tabViews;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool isLoading;
  final String? errorText;
  final Widget? emptyState;
  final VoidCallback? onRetry;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AppPage(
        maxWidth: maxWidth,
        scrollable: true,
        header: AppPageHeader(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: actions,
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        child: const AppLoading(),
      );
    }

    if (errorText != null) {
      return AppPage(
        maxWidth: maxWidth,
        scrollable: true,
        header: AppPageHeader(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: actions,
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        child: AppErrorState(message: errorText, onRetry: onRetry),
      );
    }

    if (emptyState != null) {
      return AppPage(
        maxWidth: maxWidth,
        scrollable: true,
        header: AppPageHeader(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: actions,
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        child: emptyState!,
      );
    }

    final hasTabs =
        tabs != null && tabViews != null && tabs!.length == tabViews!.length;

    Widget mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summaryBanner != null) ...[
          summaryBanner!,
          const SizedBox(height: AppLayoutTokens.sectionGap),
        ],
        body,
      ],
    );

    if (hasTabs) {
      return DefaultTabController(
        length: tabs!.length,
        child: AppPage(
          maxWidth: maxWidth,
          scrollable: false,
          header: AppPageHeader(
            title: title,
            subtitle: subtitle,
            breadcrumbs: breadcrumbs,
            actions: actions,
          ),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (summaryBanner != null) ...[
                summaryBanner!,
                const SizedBox(height: AppLayoutTokens.sectionTitleGap),
              ],
              TabBar(
                tabs: tabs!,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
              ),
              const SizedBox(height: AppLayoutTokens.sectionTitleGap),
              Expanded(child: TabBarView(children: tabViews!)),
            ],
          ),
        ),
      );
    }

    return AppPage(
      maxWidth: maxWidth,
      scrollable: true,
      header: AppPageHeader(
        title: title,
        subtitle: subtitle,
        breadcrumbs: breadcrumbs,
        actions: actions,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      child: mainContent,
    );
  }
}
