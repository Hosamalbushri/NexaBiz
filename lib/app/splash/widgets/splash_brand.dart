import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_spacing.dart';

/// Professional splash brand content — typography only (no app icon).
class SplashBrandContent extends StatelessWidget {
  const SplashBrandContent({
    super.key,
    required this.appName,
    required this.subtitle,
    required this.loadingLabel,
    this.showLoading = true,
  });

  final String appName;
  final String subtitle;
  final String loadingLabel;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft ambient wash — atmosphere without competing with the brand.
        Positioned(
          top: -80,
          left: -60,
          child: _GlowOrb(
            diameter: 220,
            color: colorScheme.primary.withValues(alpha: 0.10),
          ),
        ),
        Positioned(
          bottom: 40,
          right: -50,
          child: _GlowOrb(
            diameter: 180,
            color: colorScheme.secondary.withValues(alpha: 0.08),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: colorScheme.onSurface,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                    .moveY(
                      begin: 12,
                      end: 0,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 140.ms,
                      duration: 380.ms,
                      curve: Curves.easeOut,
                    )
                    .moveY(
                      begin: 8,
                      end: 0,
                      delay: 140.ms,
                      duration: 380.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const Spacer(flex: 4),
                if (showLoading) ...[
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colorScheme.primary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 280.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    loadingLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 280.ms),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
