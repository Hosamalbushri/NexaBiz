import 'package:flutter/material.dart';

import '../app_radius.dart';
import '../app_spacing.dart';

/// Dialog and bottom-sheet related theme fragments.
class AppDialogThemes {
  const AppDialogThemes._();

  static DialogThemeData dialog(ColorScheme scheme) {
    return DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
    );
  }

  static BottomSheetThemeData bottomSheet(ColorScheme scheme) {
    return BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      showDragHandle: true,
    );
  }
}
