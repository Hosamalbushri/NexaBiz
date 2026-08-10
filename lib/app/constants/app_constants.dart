import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'Business Platform';

  /// Prefer [AppRadius] / [AppSpacing] in new code; kept for existing call sites.
  static const double borderRadius = AppRadius.control;
  static const double pagePadding = AppSpacing.page;

  static const Locale englishLocale = Locale('en');
  static const Locale arabicLocale = Locale('ar');
}
