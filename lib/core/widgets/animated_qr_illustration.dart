import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Decorative scan / QR microinteraction for idle barcode surfaces.
///
/// Uses a bundled Lottie asset with all strokes remapped to white.
class AnimatedQrIllustration extends StatelessWidget {
  const AnimatedQrIllustration({
    super.key,
    this.size = 180,
    this.animate = true,
  });

  /// Bundled Lottie microinteraction.
  static const String animationAsset = 'assets/animations/barcode_scan.json';

  /// Outer size of the illustration.
  final double size;

  /// When false, freezes on the first frame (respects reduced motion).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldAnimate =
        animate && !MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Barcode scan illustration',
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : colorScheme.primary.withValues(alpha: 0.88),
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: Lottie.asset(
              animationAsset,
              fit: BoxFit.contain,
              repeat: shouldAnimate,
              animate: shouldAnimate,
              frameRate: FrameRate.max,
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.strokeColor(
                    const ['**'],
                    value: Colors.white,
                  ),
                ],
              ),
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.qr_code_scanner_rounded,
                  size: size * 0.45,
                  color: Colors.white,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
