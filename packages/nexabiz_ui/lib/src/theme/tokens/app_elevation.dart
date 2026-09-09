import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Surface elevation levels and soft box shadow tokens for NexaBiz.
class AppElevation {
  const AppElevation._();

  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;

  /// Soft ambient shadow for light & dark cards.
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

  /// Glowing brand accent shadow for floating actions & primary buttons.
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

  static const List<BoxShadow> none = [];
}

/// Alias class for [AppElevation] for design token backwards compatibility.
abstract class AppShadows {
  static List<BoxShadow> card(Brightness brightness) =>
      AppElevation.card(brightness);
  static List<BoxShadow> soft(Brightness brightness) =>
      AppElevation.soft(brightness);
  static const List<BoxShadow> none = AppElevation.none;
}
