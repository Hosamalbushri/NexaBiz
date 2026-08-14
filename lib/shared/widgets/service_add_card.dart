import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Empty / add placeholder matching [ServiceCard] proportions.
class ServiceAddCard extends StatelessWidget {
  const ServiceAddCard({
    super.key,
    required this.onTap,
    this.label,
    this.compact = false,
    this.dashboardStyle = false,
    this.walletStyle = false,
  });

  final VoidCallback onTap;
  final String? label;
  final bool compact;
  final bool dashboardStyle;
  final bool walletStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = colorScheme.outline.withValues(alpha: 0.45);
    final radius = AppRadius.md;
    final preferredIconBox = compact
        ? 36.0
        : walletStyle
        ? 40.0
        : dashboardStyle
        ? 48.0
        : 44.0;
    final preferredIconSize = compact
        ? 20.0
        : walletStyle || dashboardStyle
        ? 24.0
        : 26.0;

    final fill = walletStyle
        ? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F4F7))
              .withValues(alpha: isDark ? 0.85 : 0.9)
        : colorScheme.surface.withValues(alpha: isDark ? 0.4 : 0.5);

    return Semantics(
      button: true,
      label: label,
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: CustomPaint(
              painter: _DashedRRectPainter(color: borderColor, radius: radius),
              child: Ink(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final titleReserve = label == null ? 0.0 : 32.0;
                      final gap = label == null ? 0.0 : 6.0;
                      final iconBox =
                          (constraints.maxHeight - titleReserve - gap)
                              .clamp(24.0, preferredIconBox)
                              .toDouble();
                      final iconSize =
                          (iconBox * (preferredIconSize / preferredIconBox))
                              .clamp(14.0, preferredIconSize)
                              .toDouble();

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: iconSize,
                            color: colorScheme.primary,
                          ),
                          if (label != null) ...[
                            SizedBox(height: gap),
                            Flexible(
                              child: Text(
                                label!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: dashboardStyle || walletStyle
                                      ? 13.5
                                      : null,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 5.0;
      const gapLength = 3.5;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
