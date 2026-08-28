import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import 'app_quick_navigation_sheet.dart';

/// Floating quick navigation and exit widget.
///
/// Can be used as a [Scaffold.floatingActionButton] or positioned overlay.
class AppFloatingQuickNav extends StatelessWidget {
  const AppFloatingQuickNav({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    if (compact) {
      return FloatingActionButton.small(
        heroTag: 'app_quick_nav_fab_small',
        elevation: 3,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        onPressed: () => AppQuickNavigationSheet.show(context),
        tooltip: isAr ? 'التنقل السريع والخروج' : 'Quick Navigation & Exit',
        child: const Icon(Icons.explore_rounded, size: 20),
      );
    }

    return Material(
      color: Colors.transparent,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => AppQuickNavigationSheet.show(context),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isAr ? 'التنقل والخروج' : 'Nav & Exit',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
