import 'package:flutter/material.dart';
import '../theme/tokens/app_radii.dart';

enum AppIconAvatarTone { primary, secondary, success, warning, error, info, neutral }
enum AppIconAvatarSize { sm, md, lg }

/// Canonical icon tile avatar widget for NexaBiz ERP.
///
/// Displays icons inside structured, rounded surface tiles with
/// soft tint backgrounds and crisp borders.
class AppIconAvatar extends StatelessWidget {
  const AppIconAvatar({
    super.key,
    required this.icon,
    this.tone = AppIconAvatarTone.primary,
    this.size = AppIconAvatarSize.md,
    this.customColor,
  });

  final IconData icon;
  final AppIconAvatarTone tone;
  final AppIconAvatarSize size;
  final Color? customColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double dimension = switch (size) {
      AppIconAvatarSize.sm => 36.0,
      AppIconAvatarSize.md => 44.0,
      AppIconAvatarSize.lg => 56.0,
    };

    final double iconSize = switch (size) {
      AppIconAvatarSize.sm => 18.0,
      AppIconAvatarSize.md => 22.0,
      AppIconAvatarSize.lg => 28.0,
    };

    final Color baseColor = customColor ?? switch (tone) {
      AppIconAvatarTone.primary => colorScheme.primary,
      AppIconAvatarTone.secondary => colorScheme.secondary,
      AppIconAvatarTone.success => Colors.green,
      AppIconAvatarTone.warning => Colors.amber.shade700,
      AppIconAvatarTone.error => colorScheme.error,
      AppIconAvatarTone.info => Colors.lightBlue,
      AppIconAvatarTone.neutral => colorScheme.onSurface.withValues(alpha: 0.6),
    };

    final Color bgColor = baseColor.withValues(alpha: 0.12);
    final Color borderColor = baseColor.withValues(alpha: 0.24);

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: baseColor,
        ),
      ),
    );
  }
}
