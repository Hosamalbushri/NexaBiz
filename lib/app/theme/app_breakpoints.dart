/// Responsive layout breakpoint tiers for the Business Platform shell and components.
enum AppBreakpointTier { compact, medium, expanded }

class AppBreakpoints {
  const AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 1000;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;

  static AppBreakpointTier getTier(double width) {
    if (width < mobile) return AppBreakpointTier.compact;
    if (width < tablet) return AppBreakpointTier.medium;
    return AppBreakpointTier.expanded;
  }
}

