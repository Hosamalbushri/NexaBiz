import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Data record for metadata items displayed inside an [AppHoverPreview].
class AppHoverPreviewField {
  const AppHoverPreviewField({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
}

/// Canonical ERP contextual metadata preview trigger built on `shadcn.HoverCard`.
///
/// Automatically handles hover enter/exit with configurable wait/debounce,
/// touch long-press fallback, and positioning via `shadcn_flutter` overlay mechanics.
class AppHoverPreview extends StatelessWidget {
  const AppHoverPreview({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.icon,
    this.badge,
    this.fields = const [],
    this.wait = const Duration(milliseconds: 400),
    this.debounce = const Duration(milliseconds: 300),
    this.popoverAlignment = Alignment.topCenter,
    this.anchorAlignment = Alignment.bottomCenter,
  });

  /// The child widget that triggers the hover preview.
  final Widget child;

  /// Preview title.
  final String title;

  /// Optional preview subtitle.
  final String? subtitle;

  /// Optional leading icon or avatar icon.
  final IconData? icon;

  /// Optional trailing badge text or widget.
  final String? badge;

  /// Key-value metadata fields to display in the preview card.
  final List<AppHoverPreviewField> fields;

  /// Hover wait duration before opening popover.
  final Duration wait;

  /// Hover exit debounce duration before closing popover.
  final Duration debounce;

  /// Popover alignment relative to anchor.
  final AlignmentGeometry popoverAlignment;

  /// Anchor point alignment.
  final AlignmentGeometry anchorAlignment;

  @override
  Widget build(BuildContext context) {
    return shadcn.HoverCard(
      wait: wait,
      debounce: debounce,
      popoverAlignment: popoverAlignment,
      anchorAlignment: anchorAlignment,
      hoverBuilder: (context) {
        final theme = shadcn.Theme.of(context);
        return Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: theme.borderRadiusMd,
            border: Border.all(color: theme.colorScheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted,
                        borderRadius: theme.borderRadiusSm,
                      ),
                      child: Icon(icon, size: 16, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.typography.semiBold.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.typography.small.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null)
                    shadcn.SecondaryBadge(
                      child: Text(badge!),
                    ),
                ],
              ),
              if (fields.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (field.icon != null) ...[
                              Icon(
                                field.icon,
                                size: 12,
                                color: theme.colorScheme.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              field.label,
                              style: theme.typography.small.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            field.value,
                            style: theme.typography.small.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.foreground,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      child: child,
    );
  }
}
