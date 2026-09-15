import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_colors.dart';
import 'app_typography.dart';

/// Central Design System Theme Architecture for NexaBiz ERP.
///
/// Built on top of [shadcn_flutter] as the sole canonical visual authority.
class AppTheme {
  const AppTheme._();

  /// Canonical Native shadcn_flutter Light ThemeData
  static shadcn.ThemeData light({
    double radius = 0.5,
    double surfaceOpacity = 0.95,
    double surfaceBlur = 4.0,
    shadcn.Density density = shadcn.Density.defaultDensity,
  }) {
    final baseColorScheme = shadcn.ColorSchemes.lightSlate;
    return shadcn.ThemeData(
      colorScheme: baseColorScheme.copyWith(
        primary: () => AppColors.primaryBlue,
        primaryForeground: () => Colors.white,
        secondary: () => AppColors.secondaryTeal,
        secondaryForeground: () => Colors.white,
        background: () => AppColors.lightBackground,
        card: () => AppColors.lightSurface,
        popover: () => AppColors.lightSurface,
        border: () => AppColors.borderLight,
        input: () => AppColors.borderLight,
        ring: () => AppColors.primaryBlue,
        destructive: () => AppColors.error,
        destructiveForeground: () => Colors.white,
      ),
      typography: AppTypography.shadcnTypography(),
      density: density,
      radius: radius,
      surfaceOpacity: surfaceOpacity,
      surfaceBlur: surfaceBlur,
    );
  }

  /// Canonical Native shadcn_flutter Dark ThemeData
  static shadcn.ThemeData dark({
    double radius = 0.5,
    double surfaceOpacity = 0.95,
    double surfaceBlur = 4.0,
    shadcn.Density density = shadcn.Density.defaultDensity,
  }) {
    final baseColorScheme = shadcn.ColorSchemes.darkSlate;
    return shadcn.ThemeData.dark(
      colorScheme: baseColorScheme.copyWith(
        primary: () => AppColors.primaryBlue,
        primaryForeground: () => Colors.white,
        secondary: () => AppColors.secondaryTeal,
        secondaryForeground: () => Colors.white,
        background: () => AppColors.darkBackground,
        card: () => AppColors.darkSurface,
        popover: () => AppColors.darkSurface,
        border: () => AppColors.borderDark,
        input: () => AppColors.borderDark,
        ring: () => AppColors.primaryBlue,
        destructive: () => AppColors.error,
        destructiveForeground: () => Colors.white,
      ),
      typography: AppTypography.shadcnTypography(),
      density: density,
      radius: radius,
      surfaceOpacity: surfaceOpacity,
      surfaceBlur: surfaceBlur,
    );
  }

  /// Backwards-compatible alias for light shadcn theme.
  static shadcn.ThemeData shadcnLight({
    double radius = 0.5,
    double surfaceOpacity = 0.95,
    double surfaceBlur = 4.0,
    shadcn.Density density = shadcn.Density.defaultDensity,
  }) =>
      light(
        radius: radius,
        surfaceOpacity: surfaceOpacity,
        surfaceBlur: surfaceBlur,
        density: density,
      );

  /// Backwards-compatible alias for dark shadcn theme.
  static shadcn.ThemeData shadcnDark({
    double radius = 0.5,
    double surfaceOpacity = 0.95,
    double surfaceBlur = 4.0,
    shadcn.Density density = shadcn.Density.defaultDensity,
  }) =>
      dark(
        radius: radius,
        surfaceOpacity: surfaceOpacity,
        surfaceBlur: surfaceBlur,
        density: density,
      );

  /// Supplementary Material ThemeData for infrastructure interoperability.
  static ThemeData materialLight() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.secondaryTeal,
        error: AppColors.error,
        surface: AppColors.lightSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: AppTypography.fontFamily,
    );
  }

  /// Supplementary Material ThemeData for infrastructure interoperability.
  static ThemeData materialDark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryBlue,
        secondary: AppColors.secondaryTeal,
        error: AppColors.error,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: AppTypography.fontFamily,
    );
  }
}
