import 'package:flutter/material.dart';

import '../app_radius.dart';
import '../app_spacing.dart';

/// Text field / input decoration theme.
class AppInputThemes {
  const AppInputThemes._();

  static InputDecorationTheme input(ColorScheme scheme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: scheme.outline),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    );
  }
}
