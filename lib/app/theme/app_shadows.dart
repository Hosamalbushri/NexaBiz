import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation / shadow tokens used by themed surfaces.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.18 : 0.10),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> card(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> none = const [];
}
