import 'package:flutter/animation.dart';

/// Animation duration and curve tokens for micro-interactions in NexaBiz.
class AppMotion {
  const AppMotion._();

  /// Fast interaction (hover, press feedback, simple toggles): 150ms.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard interaction (page transitions, expand/collapse, dialog fade): 250ms.
  static const Duration normal = Duration(milliseconds: 250);

  /// Slow interaction (modal slide, sheet reveal, complex layout shifts): 350ms.
  static const Duration slow = Duration(milliseconds: 350);

  /// Stagger delay between sequential list animations: 50ms.
  static const Duration stagger = Duration(milliseconds: 50);

  /// Standard easing curve.
  static const Curve curveStandard = Curves.easeInOut;

  /// Deceleration curve for entering elements.
  static const Curve curveDecelerate = Curves.easeOut;

  /// Acceleration curve for exiting elements.
  static const Curve curveAccelerate = Curves.easeIn;
}
