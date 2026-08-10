import 'package:flutter/material.dart';

import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// Material 3 button themes for the design system.
class AppButtonThemes {
  const AppButtonThemes._();

  static const Size _minimumSize = Size(64, 48);

  static RoundedRectangleBorder get _shape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );

  static ElevatedButtonThemeData elevated(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: _minimumSize,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: _shape,
        textStyle: AppTypography.textTheme(Brightness.light).labelLarge,
        elevation: 0,
      ),
    );
  }

  static FilledButtonThemeData filled(ColorScheme scheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: _minimumSize,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: _shape,
        textStyle: AppTypography.textTheme(Brightness.light).labelLarge,
      ),
    );
  }

  static OutlinedButtonThemeData outlined(ColorScheme scheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: _minimumSize,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: _shape,
        textStyle: AppTypography.textTheme(Brightness.light).labelLarge,
        side: BorderSide(color: scheme.outline),
      ),
    );
  }

  static TextButtonThemeData text(ColorScheme scheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: _minimumSize,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: _shape,
        textStyle: AppTypography.textTheme(Brightness.light).labelLarge,
      ),
    );
  }
}
