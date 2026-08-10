import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

enum AppStatusTone { success, warning, error, info, neutral }

/// Status badge that always pairs color with a text label.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.animate = true,
  });

  final String label;
  final AppStatusTone tone;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(tone);
    final badge = Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );

    if (!animate) {
      return badge;
    }

    return badge
        .animate()
        .fadeIn(duration: 160.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 180.ms,
          curve: Curves.easeOutBack,
        );
  }

  _ToneColors _colorsFor(AppStatusTone tone) {
    switch (tone) {
      case AppStatusTone.success:
        return const _ToneColors(
          background: AppColors.successContainer,
          foreground: AppColors.success,
        );
      case AppStatusTone.warning:
        return const _ToneColors(
          background: AppColors.warningContainer,
          foreground: AppColors.warning,
        );
      case AppStatusTone.error:
        return const _ToneColors(
          background: AppColors.errorContainer,
          foreground: AppColors.error,
        );
      case AppStatusTone.info:
        return const _ToneColors(
          background: AppColors.infoContainer,
          foreground: AppColors.info,
        );
      case AppStatusTone.neutral:
        return const _ToneColors(
          background: AppColors.neutralContainer,
          foreground: AppColors.neutral,
        );
    }
  }
}

class _ToneColors {
  const _ToneColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
