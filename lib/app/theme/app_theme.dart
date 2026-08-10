import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'components/button_theme.dart';
import 'components/card_theme.dart';
import 'components/chip_theme.dart';
import 'components/dialog_theme.dart';
import 'components/input_theme.dart';
import 'components/navigation_theme.dart';

/// Central Material 3 theme built with FlexColorScheme + design tokens.
class AppTheme {
  const AppTheme._();

  static const FlexSchemeColor _brand = FlexSchemeColor(
    primary: AppColors.primaryBlue,
    primaryContainer: Color(0xFFD6E4FF),
    secondary: AppColors.secondaryTeal,
    secondaryContainer: Color(0xFFB2DFDB),
    tertiary: AppColors.tertiaryIndigo,
    tertiaryContainer: Color(0xFFC5CAE9),
    error: AppColors.error,
  );

  static ThemeData light() {
    final base = FlexThemeData.light(
      colors: _brand,
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 8,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      fontFamily: AppTypography.fontFamily,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: false,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
      ),
    );

    return _applyDesignSystem(base, Brightness.light);
  }

  static ThemeData dark() {
    final base = FlexThemeData.dark(
      colors: _brand,
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      fontFamily: AppTypography.fontFamily,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: false,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
      ),
    );

    return _applyDesignSystem(base, Brightness.dark);
  }

  static ThemeData _applyDesignSystem(ThemeData base, Brightness brightness) {
    final scheme = base.colorScheme;
    final textTheme = AppTypography.textTheme(brightness).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppNavigationThemes.appBar(scheme, brightness),
      navigationBarTheme: AppNavigationThemes.navigationBar(scheme),
      navigationRailTheme: AppNavigationThemes.navigationRail(scheme),
      cardTheme: AppCardThemes.card(scheme),
      inputDecorationTheme: AppInputThemes.input(scheme),
      elevatedButtonTheme: AppButtonThemes.elevated(scheme),
      filledButtonTheme: AppButtonThemes.filled(scheme),
      outlinedButtonTheme: AppButtonThemes.outlined(scheme),
      textButtonTheme: AppButtonThemes.text(scheme),
      dialogTheme: AppDialogThemes.dialog(scheme),
      bottomSheetTheme: AppDialogThemes.bottomSheet(scheme),
      chipTheme: AppChipThemes.chip(scheme),
    );
  }
}
