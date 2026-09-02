import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Heights for standardized form field density.
enum AppFieldDensity {
  /// Compact density (38px height) — ideal for table cells or dense headers.
  compact,

  /// Standard density (48px height) — default for standard ERP forms.
  standard,

  /// Large density (56px height) — ideal for primary touch / search inputs.
  large,
}

extension AppFieldDensityX on AppFieldDensity {
  double get height => switch (this) {
        AppFieldDensity.compact => 38.0,
        AppFieldDensity.standard => 48.0,
        AppFieldDensity.large => 56.0,
      };

  EdgeInsetsGeometry get contentPadding => switch (this) {
        AppFieldDensity.compact => const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        AppFieldDensity.standard => const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        AppFieldDensity.large => const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      };
}

/// Canonical presentation shell for NexaBiz ERP form fields.
///
/// Standardizes:
/// - Label typography, required asterisk (`*`)
/// - Field heights & content padding via [AppFieldDensity]
/// - Helper text & error text presentation
/// - Focus, error, disabled, and read-only visual decorations
/// - Accessibility [Semantics]
class AppFieldShell extends StatelessWidget {
  const AppFieldShell({
    super.key,
    required this.child,
    this.label,
    this.required = false,
    this.helperText,
    this.errorText,
    this.density = AppFieldDensity.standard,
    this.enabled = true,
    this.readOnly = false,
    this.focused = false,
    this.prefix,
    this.suffix,
    this.onTap,
  });

  final Widget child;
  final String? label;
  final bool required;
  final String? helperText;
  final String? errorText;
  final AppFieldDensity density;
  final bool enabled;
  final bool readOnly;
  final bool focused;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final borderColor = hasError
        ? scheme.error
        : focused
            ? scheme.primary
            : scheme.outlineVariant.withValues(alpha: 0.5);

    final fillColor = !enabled
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : readOnly
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.15)
            : scheme.surface;

    return Semantics(
      label: label,
      enabled: enabled,
      readOnly: readOnly,
      hint: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && label!.isNotEmpty) ...[
            Text.rich(
              TextSpan(
                text: label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: !enabled
                      ? scheme.onSurface.withValues(alpha: 0.38)
                      : scheme.onSurface,
                ),
                children: [
                  if (required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          InkWell(
            onTap: enabled && !readOnly ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: BoxConstraints(minHeight: density.height),
              padding: density.contentPadding,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: borderColor,
                  width: focused || hasError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: AppSpacing.xs + 2),
                  ],
                  Expanded(child: child),
                  if (suffix != null) ...[
                    const SizedBox(width: AppSpacing.xs + 2),
                    suffix!,
                  ],
                ],
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (helperText != null && helperText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
