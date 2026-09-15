import 'package:flutter/widgets.dart';

/// Responsive layout breakpoint tiers for NexaBiz UI.
enum AppBreakpointTier {
  /// Mobile (< 600px)
  compact,

  /// Tablet (600px - 999px)
  medium,

  /// Desktop (1000px - 1439px)
  expanded,

  /// Large Desktop (>= 1440px)
  wide,
}

/// Central breakpoint thresholds and responsive helper methods.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double mobile = 600.0;
  static const double tablet = 1000.0;
  static const double desktop = 1200.0;
  static const double largeDesktop = 1440.0;

  static bool isCompact(double width) => width < mobile;
  static bool isMedium(double width) => width >= mobile && width < tablet;
  static bool isExpanded(double width) => width >= tablet && width < largeDesktop;
  static bool isWide(double width) => width >= largeDesktop;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  static AppBreakpointTier getTier(double width) {
    if (width < mobile) return AppBreakpointTier.compact;
    if (width < tablet) return AppBreakpointTier.medium;
    if (width < largeDesktop) return AppBreakpointTier.expanded;
    return AppBreakpointTier.wide;
  }

  static AppBreakpointTier of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getTier(width);
  }
}
