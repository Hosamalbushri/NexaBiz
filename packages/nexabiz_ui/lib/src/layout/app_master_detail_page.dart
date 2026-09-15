import 'package:flutter/material.dart';

import '../widgets/app_page_header.dart';
import 'app_breakpoints.dart';
import 'app_layout_tokens.dart';
import 'app_page.dart';
import 'app_responsive.dart';

/// Canonical Split Master-Detail View layout component for NexaBiz ERP screens.
///
/// Provides a split-pane interface (Master list on the left/right according to RTL,
/// detail view on the right/left). On compact screens, automatically collapses into
/// single pane navigation.
class AppMasterDetailPage extends StatelessWidget {
  const AppMasterDetailPage({
    super.key,
    required this.title,
    required this.master,
    required this.detail,
    this.subtitle,
    this.breadcrumbs,
    this.headerActions,
    this.masterWidth = 360.0,
    this.showDetailOnCompact = false,
    this.maxWidth = AppLayoutTokens.maxPageWidth,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? headerActions;

  final Widget master;
  final Widget detail;
  final double masterWidth;
  final bool showDetailOnCompact;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      maxWidth: maxWidth,
      scrollable: false,
      header: AppPageHeader(
        title: title,
        subtitle: subtitle,
        breadcrumbs: breadcrumbs,
        actions: headerActions,
      ),
      child: ResponsiveBuilder(
        builder: (context, constraints, tier) {
          if (tier == AppBreakpointTier.compact) {
            return showDetailOnCompact ? detail : master;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: masterWidth,
                child: master,
              ),
              const SizedBox(width: AppLayoutTokens.sectionGap),
              Expanded(
                child: detail,
              ),
            ],
          );
        },
      ),
    );
  }
}
