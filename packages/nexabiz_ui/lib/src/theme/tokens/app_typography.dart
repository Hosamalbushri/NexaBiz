import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Typography tokens for NexaBiz ERP System built on Cairo font family.
class AppTypography {
  const AppTypography._();

  static const String fontFamilyName = 'Cairo';

  static String? get fontFamily => fontFamilyName;

  /// Canonical native shadcn Typography instance configured with Cairo font family.
  static shadcn.Typography shadcnTypography() {
    return const shadcn.Typography(
      sans: TextStyle(fontFamily: fontFamilyName),
      mono: TextStyle(fontFamily: fontFamilyName),
      xSmall: TextStyle(fontFamily: fontFamilyName, fontSize: 12),
      small: TextStyle(fontFamily: fontFamilyName, fontSize: 14),
      base: TextStyle(fontFamily: fontFamilyName, fontSize: 16),
      large: TextStyle(fontFamily: fontFamilyName, fontSize: 18),
      xLarge: TextStyle(fontFamily: fontFamilyName, fontSize: 20),
      x2Large: TextStyle(fontFamily: fontFamilyName, fontSize: 24),
      x3Large: TextStyle(fontFamily: fontFamilyName, fontSize: 30),
      x4Large: TextStyle(fontFamily: fontFamilyName, fontSize: 36),
      x5Large: TextStyle(fontFamily: fontFamilyName, fontSize: 48),
      x6Large: TextStyle(fontFamily: fontFamilyName, fontSize: 60),
      x7Large: TextStyle(fontFamily: fontFamilyName, fontSize: 72),
      x8Large: TextStyle(fontFamily: fontFamilyName, fontSize: 96),
      x9Large: TextStyle(fontFamily: fontFamilyName, fontSize: 144),
      thin: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w100),
      light: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w300),
      extraLight: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w200),
      normal: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w400),
      medium: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w500),
      semiBold: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w600),
      bold: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w700),
      extraBold: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w800),
      black: TextStyle(fontFamily: fontFamilyName, fontWeight: FontWeight.w900),
      italic: TextStyle(fontFamily: fontFamilyName, fontStyle: FontStyle.italic),
      h1: TextStyle(fontFamily: fontFamilyName, fontSize: 36, fontWeight: FontWeight.w800),
      h2: TextStyle(fontFamily: fontFamilyName, fontSize: 30, fontWeight: FontWeight.w600),
      h3: TextStyle(fontFamily: fontFamilyName, fontSize: 24, fontWeight: FontWeight.w600),
      h4: TextStyle(fontFamily: fontFamilyName, fontSize: 18, fontWeight: FontWeight.w600),
      p: TextStyle(fontFamily: fontFamilyName, fontSize: 16, fontWeight: FontWeight.w400),
      blockQuote: TextStyle(fontFamily: fontFamilyName, fontSize: 16, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
      inlineCode: TextStyle(fontFamily: fontFamilyName, fontSize: 14, fontWeight: FontWeight.w600),
      lead: TextStyle(fontFamily: fontFamilyName, fontSize: 20),
      textLarge: TextStyle(fontFamily: fontFamilyName, fontSize: 20, fontWeight: FontWeight.w600),
      textSmall: TextStyle(fontFamily: fontFamilyName, fontSize: 14, fontWeight: FontWeight.w500),
      textMuted: TextStyle(fontFamily: fontFamilyName, fontSize: 14, fontWeight: FontWeight.w400),
    );
  }

  /// Dynamic context-aware shadcn typography accessor.
  static shadcn.Typography typographyOf(BuildContext context) {
    return shadcn.Theme.of(context).typography;
  }

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base
        .apply(fontFamily: fontFamilyName)
        .copyWith(
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

