import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Heights for standardized form field density.
enum AppFieldDensity {
  /// Compact density (36px height) — ideal for table cells or dense headers.
  compact,

  /// Standard density (44px height) — default for standard ERP forms.
  standard,

  /// Large density (52px height) — ideal for primary touch / search inputs.
  large,
}

extension AppFieldDensityX on AppFieldDensity {
  double get height => switch (this) {
        AppFieldDensity.compact => 36.0,
        AppFieldDensity.standard => 44.0,
        AppFieldDensity.large => 52.0,
      };

  EdgeInsetsGeometry get contentPadding => switch (this) {
        AppFieldDensity.compact => const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
        AppFieldDensity.standard => const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        AppFieldDensity.large => const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
      };
}

/// Canonical presentation shell for NexaBiz ERP form fields.
///
/// Fully aligned with [AppDropdown] and `shadcn_flutter.Select` design specifications.
class AppFieldShell extends StatefulWidget {
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
    this.focused,
    this.prefix,
    this.showPrefixDivider = false,
    this.suffix,
    this.shortcutHint,
    this.onClear,
    this.onTap,
    this.focusNode,
  });

  final Widget child;
  final String? label;
  final bool required;
  final String? helperText;
  final String? errorText;
  final AppFieldDensity density;
  final bool enabled;
  final bool readOnly;
  final bool? focused;
  final Widget? prefix;
  final bool showPrefixDivider;
  final Widget? suffix;
  final String? shortcutHint;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  @override
  State<AppFieldShell> createState() => _AppFieldShellState();
}

class _AppFieldShellState extends State<AppFieldShell> {
  bool _isHovered = false;
  bool _isFocusedInternal = false;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isFocused = widget.focused ?? _isFocusedInternal;

    final fillColor = !widget.enabled
        ? colorScheme.muted.withValues(alpha: 0.5)
        : widget.readOnly
            ? colorScheme.muted.withValues(alpha: 0.3)
            : colorScheme.card;

    Color borderColor;
    if (hasError) {
      borderColor = colorScheme.destructive;
    } else if (isFocused) {
      borderColor = colorScheme.primary;
    } else if (_isHovered && widget.enabled) {
      borderColor = colorScheme.foreground.withValues(alpha: 0.35);
    } else {
      borderColor = colorScheme.border;
    }

    final effectiveRadius = BorderRadius.circular(theme.radiusSm);

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocusedInternal = focused;
        });
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Semantics(
          label: widget.label,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          hint: widget.errorText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label case final String lbl when lbl.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lbl,
                      style: theme.typography.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.enabled
                            ? colorScheme.foreground
                            : colorScheme.mutedForeground,
                      ),
                    ),
                    if (widget.required) ...[
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                          color: colorScheme.destructive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
              ],
              InkWell(
                onTap: widget.enabled && !widget.readOnly ? widget.onTap : null,
                borderRadius: effectiveRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(minHeight: widget.density.height),
                  padding: widget.density.contentPadding,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: effectiveRadius,
                    border: Border.all(
                      color: borderColor,
                      width: isFocused || hasError ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      if (isFocused && widget.enabled && !hasError)
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      else if (hasError)
                        BoxShadow(
                          color: colorScheme.destructive.withValues(alpha: 0.12),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (widget.prefix != null) ...[
                        widget.prefix!,
                        if (widget.showPrefixDivider) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 14,
                            color: colorScheme.border,
                          ),
                          const SizedBox(width: 8),
                        ] else
                          const SizedBox(width: 8),
                      ],
                      Expanded(child: widget.child),
                      if (widget.onClear != null &&
                          widget.enabled &&
                          !widget.readOnly) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onClear,
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 16,
                            color: colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                      if (widget.suffix != null) ...[
                        const SizedBox(width: 8),
                        widget.suffix!,
                      ],
                    ],
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 4),
                Text(
                  widget.errorText!,
                  style: theme.typography.small.copyWith(
                    color: colorScheme.destructive,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (widget.helperText case final String helper
                  when helper.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  helper,
                  style: theme.typography.small.copyWith(
                    color: colorScheme.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
