import 'package:flutter/material.dart';

import '../app_radius.dart';

/// Card surface theme for Material 3.
class AppCardThemes {
  const AppCardThemes._();

  static CardThemeData card(ColorScheme scheme) {
    return CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
    );
  }
}
