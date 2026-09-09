import 'package:flutter/material.dart';

/// Border stroke widths, sides, and outline tokens for NexaBiz.
class AppBorders {
  const AppBorders._();

  static const double thin = 1.0;
  static const double medium = 1.5;
  static const double thick = 2.0;

  /// Standard border side resolving outline color according to active brightness.
  static BorderSide outline(ColorScheme scheme, {double width = thin}) {
    return BorderSide(color: scheme.outline, width: width);
  }

  /// Subtle container outline border side.
  static BorderSide subtle(ColorScheme scheme, {double width = thin}) {
    return BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.55),
      width: width,
    );
  }

  /// Focus state active ring border side.
  static BorderSide focus(ColorScheme scheme, {double width = medium}) {
    return BorderSide(color: scheme.primary, width: width);
  }

  /// Error state active ring border side.
  static BorderSide error(ColorScheme scheme, {double width = medium}) {
    return BorderSide(color: scheme.error, width: width);
  }
}
