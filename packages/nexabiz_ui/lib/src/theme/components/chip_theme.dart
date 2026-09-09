import 'package:flutter/material.dart';

import '../app_radius.dart';
import '../app_spacing.dart';

/// Chip themes for filters and status affordances.
class AppChipThemes {
  const AppChipThemes._();

  static ChipThemeData chip(ColorScheme scheme) {
    return ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primary.withValues(alpha: 0.14),
      disabledColor: scheme.onSurface.withValues(alpha: 0.08),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      side: BorderSide(color: scheme.outlineVariant),
      showCheckmark: false,
    );
  }
}
