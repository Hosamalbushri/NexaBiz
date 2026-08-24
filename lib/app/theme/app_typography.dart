import 'package:flutter/material.dart';

/// Typography tokens built on Cairo for EN/AR readability using local font assets.
class AppTypography {
  const AppTypography._();

  static const String fontFamilyName = 'Cairo';

  static String? get fontFamily => fontFamilyName;

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base.apply(fontFamily: fontFamilyName).copyWith(
      displayLarge: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      displayMedium: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      displaySmall: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.15,
      ),
      headlineLarge: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      labelLarge: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: const TextStyle(
        fontFamily: fontFamilyName,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  static TextStyle appBarTitle(Color color) {
    return TextStyle(
      fontFamily: fontFamilyName,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: color,
    );
  }
}
