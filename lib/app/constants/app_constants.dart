import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'NexaBiz';

  /// Prefer [AppRadius] / [AppSpacing] in new code; kept for existing call sites.
  static const double borderRadius = AppRadius.control;
  static const double pagePadding = AppSpacing.page;

  /// Maximum content width cap for large screens / desktop / web.
  static const double maxContentWidth = 900.0;

  /// Page content insets that clear shell chrome and keep a trailing margin so
  /// the bottom navigation (when present) is the last visible surface.
  ///
  /// Relies on [AppShell] injecting the chrome height into
  /// [MediaQueryData.padding.bottom] on primary shell tabs.
  static EdgeInsets pageInsets(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    return EdgeInsets.fromLTRB(
      pagePadding,
      pagePadding,
      pagePadding,
      pagePadding + mediaPadding.bottom,
    );
  }

  static const Locale englishLocale = Locale('en');
  static const Locale arabicLocale = Locale('ar');
}
