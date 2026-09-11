import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Semantic color tokens for NexaBiz ERP System.
///
/// Supports Light and Dark modes with semantic role names rather than color values.
class AppColors {
  const AppColors._();

  // Brand Palette
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color secondaryTeal = Color(0xFF00897B);
  static const Color tertiaryIndigo = Color(0xFF5C6BC0);

  // Surface & Background Tokens
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E293B);

  // Border & Divider Tokens
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Text & Content Muted Tokens
  static const Color mutedTextLight = Color(0xFF64748B);
  static const Color mutedTextDark = Color(0xFF94A3B8);

  // Semantic Status Color Tokens
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
  static const Color neutral = Color(0xFF616161);

  // Status Soft Container Overlays (Alpha blended)
  static const Color successContainer = Color(0x1A2E7D32);
  static const Color warningContainer = Color(0x1AE65100);
  static const Color errorContainer = Color(0x1AC62828);
  static const Color infoContainer = Color(0x1A1565C0);
  static const Color neutralContainer = Color(0x1A616161);

  /// Dynamic helper to resolve border color by brightness.
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : borderLight;

  /// Dynamic helper to resolve muted text color by brightness.
  static Color mutedText(Brightness brightness) =>
      brightness == Brightness.dark ? mutedTextDark : mutedTextLight;

  /// Dynamic context-aware shadcn color scheme accessor
  static shadcn.ColorScheme colorSchemeOf(BuildContext context) {
    return shadcn.Theme.of(context).colorScheme;
  }

  /// Context-aware background color
  static Color backgroundOf(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.background;

  /// Context-aware foreground color
  static Color foregroundOf(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.foreground;

  /// Context-aware primary color
  static Color primaryOf(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.primary;

  /// Context-aware card color
  static Color cardOf(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.card;

  /// Context-aware border color
  static Color borderOf(BuildContext context) =>
      shadcn.Theme.of(context).colorScheme.border;
}
