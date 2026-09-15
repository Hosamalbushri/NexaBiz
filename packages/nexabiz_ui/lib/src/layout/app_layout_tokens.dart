import 'package:flutter/widgets.dart';

/// Single authoritative source for layout dimensions, max widths, gaps, and spacing tokens across NexaBiz.
class AppLayoutTokens {
  const AppLayoutTokens._();

  // Content Max Widths (px)
  static const double maxPageWidth = 1400.0;
  static const double maxFormWidth = 720.0;
  static const double maxWideFormWidth = 1000.0;
  static const double maxTableWidth = 1600.0;
  static const double maxDashboardWidth = 1600.0;
  static const double maxDetailsWidth = 1400.0;
  static const double maxSettingsWidth = 1000.0;

  // Page Level Spacing (px)
  static const double pagePaddingCompact = 12.0;
  static const double pagePaddingStandard = 16.0;
  static const double pagePaddingSpacious = 24.0;
  static const double pageHeaderGap = 20.0;

  // Section Spacing (px)
  static const double sectionGap = 24.0;
  static const double sectionTitleGap = 12.0;
  static const double sectionInnerGap = 16.0;
  static const double sectionPadding = 16.0;

  // Form Spacing (px)
  static const double formFieldGap = 16.0;
  static const double formGroupGap = 24.0;
  static const double formActionsGap = 16.0;
  static const double formSectionGap = 20.0;

  // Table Spacing (px)
  static const double tableToolbarGap = 16.0;
  static const double tableFilterGap = 12.0;
  static const double tablePaginationGap = 16.0;
  static const double tableHeaderRowGap = 12.0;

  // Dashboard Spacing (px)
  static const double dashboardGridGap = 16.0;
  static const double dashboardCardGap = 16.0;
  static const double dashboardKpiGap = 16.0;
  static const double dashboardSectionGap = 24.0;

  // Navigation Spacing (px)
  static const double navItemGap = 8.0;
  static const double navSidebarWidth = 260.0;
  static const double navCollapsedSidebarWidth = 64.0;

  // EdgeInset Directional Helpers for RTL Compliance
  static const EdgeInsetsGeometry pagePaddingDirectionalCompact =
      EdgeInsetsDirectional.all(pagePaddingCompact);
  static const EdgeInsetsGeometry pagePaddingDirectionalStandard =
      EdgeInsetsDirectional.all(pagePaddingStandard);
  static const EdgeInsetsGeometry pagePaddingDirectionalSpacious =
      EdgeInsetsDirectional.all(pagePaddingSpacious);

  static const EdgeInsetsGeometry sectionPaddingDirectional =
      EdgeInsetsDirectional.all(sectionPadding);
}
