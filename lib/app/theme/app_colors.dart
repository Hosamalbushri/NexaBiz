import 'package:flutter/material.dart';

/// Brand and semantic color tokens for the Business Platform.
///
/// Prefer [ColorScheme] from the active theme in UI code. Use these tokens
/// only when building [ThemeData] or rare one-off brand accents.
class AppColors {
  const AppColors._();

  // Brand
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color secondaryTeal = Color(0xFF00897B);
  static const Color tertiaryIndigo = Color(0xFF5C6BC0);

  // Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E293B);

  // Semantic status (paired with text labels in UI — never color alone)
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
  static const Color neutral = Color(0xFF616161);

  // Status soft backgrounds
  static const Color successContainer = Color(0x1A2E7D32);
  static const Color warningContainer = Color(0x1AE65100);
  static const Color errorContainer = Color(0x1AC62828);
  static const Color infoContainer = Color(0x1A1565C0);
  static const Color neutralContainer = Color(0x1A616161);
}
