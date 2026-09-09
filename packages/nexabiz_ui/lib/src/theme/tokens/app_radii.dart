import 'package:flutter/material.dart';

/// Border radius tokens for surfaces, inputs, buttons, and dialogs.
class AppRadii {
  const AppRadii._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  /// Default control radius (buttons, inputs, cards).
  static const double control = sm;

  /// Large surface radius (sheets, elevated panels).
  static const double surface = md;

  /// Dialog corner radius.
  static const double dialog = lg;

  /// Modal bottom sheet top corner radius.
  static const double sheet = xl;

  /// BorderRadius objects for quick instantiation
  static final BorderRadius radiusXs = BorderRadius.circular(xs);
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusPill = BorderRadius.circular(pill);

  static final BorderRadius radiusControl = BorderRadius.circular(control);
  static final BorderRadius radiusSurface = BorderRadius.circular(surface);
  static final BorderRadius radiusDialog = BorderRadius.circular(dialog);
}

/// Alias class for [AppRadii] for design token backwards compatibility.
abstract class AppRadius {
  static const double xs = AppRadii.xs;
  static const double sm = AppRadii.sm;
  static const double md = AppRadii.md;
  static const double lg = AppRadii.lg;
  static const double xl = AppRadii.xl;
  static const double pill = AppRadii.pill;

  static const double control = AppRadii.control;
  static const double surface = AppRadii.surface;
  static const double dialog = AppRadii.dialog;

  static final BorderRadius radiusXs = AppRadii.radiusXs;
  static final BorderRadius radiusSm = AppRadii.radiusSm;
  static final BorderRadius radiusMd = AppRadii.radiusMd;
  static final BorderRadius radiusLg = AppRadii.radiusLg;
  static final BorderRadius radiusXl = AppRadii.radiusXl;
  static final BorderRadius radiusPill = AppRadii.radiusPill;
}
