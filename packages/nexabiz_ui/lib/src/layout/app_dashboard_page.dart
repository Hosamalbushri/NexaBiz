import 'package:flutter/material.dart';

import '../widgets/app_error_state.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_page_header.dart';
import 'app_layout_tokens.dart';
import 'app_page.dart';

/// Canonical Dashboard Page layout component for NexaBiz screens.
///
/// Controls multi-column stat cards grid, quick navigation shortcuts,
/// module hubs, and activity log layout.
class AppDashboardPage extends StatelessWidget {
  const AppDashboardPage({
    super.key,
    this.title = '',
    this.statsGrid = const SizedBox.shrink(),
    required this.content,
    this.subtitle,
    this.breadcrumbs,
    this.headerActions,
    this.quickActions,
    this.recentActivity,
    this.isLoading = false,
    this.errorText,
    this.onRetry,
    this.maxWidth = AppLayoutTokens.maxDashboardWidth,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? headerActions;

  final Widget statsGrid;
  final Widget content;
  final Widget? quickActions;
  final Widget? recentActivity;
  final bool isLoading;
  final String? errorText;
  final VoidCallback? onRetry;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title.isNotEmpty ||
        (subtitle != null && subtitle!.isNotEmpty) ||
        (headerActions != null && headerActions!.isNotEmpty);

    final headerWidget = hasHeader
        ? AppPageHeader(
            title: title,
            subtitle: subtitle,
            breadcrumbs: breadcrumbs,
            actions: headerActions,
          )
        : null;

    if (isLoading) {
      return AppPage(
        maxWidth: maxWidth,
        scrollable: true,
        header: headerWidget,
        child: const AppLoading(),
      );
    }

    if (errorText != null) {
      return AppPage(
        maxWidth: maxWidth,
        scrollable: true,
        header: headerWidget,
        child: AppErrorState(message: errorText, onRetry: onRetry),
      );
    }

    return AppPage(
      maxWidth: maxWidth,
      scrollable: true,
      header: headerWidget,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statsGrid,
          if (statsGrid is! SizedBox)
            const SizedBox(height: AppLayoutTokens.dashboardSectionGap),
          if (quickActions != null) ...[
            quickActions!,
            const SizedBox(height: AppLayoutTokens.dashboardSectionGap),
          ],
          content,
          if (recentActivity != null) ...[
            const SizedBox(height: AppLayoutTokens.dashboardSectionGap),
            recentActivity!,
          ],
        ],
      ),
    );
  }
}
