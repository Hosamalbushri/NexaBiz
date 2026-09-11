import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical ERP side/bottom drawer content panel built on top of `shadcn_flutter`.
///
/// Features a standardized header with icon, title, subtitle, close button,
/// scrollable body area, and an optional bottom sticky actions row.
class AppDrawerSheet extends StatelessWidget {
  const AppDrawerSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.onClose,
    this.padding = const EdgeInsets.all(16),
  });

  /// The main body content.
  final Widget child;

  /// Optional header title.
  final String? title;

  /// Optional header subtitle.
  final String? subtitle;

  /// Optional header leading icon.
  final IconData? icon;

  /// Optional list of action buttons displayed in the bottom sticky strip.
  final List<Widget>? actions;

  /// Optional close button override callback. If null, closes the drawer overlay.
  final VoidCallback? onClose;

  /// Internal padding for the main body content.
  final EdgeInsetsGeometry padding;

  /// Opens an [AppDrawerSheet] using [shadcn.openDrawerOverlay].
  static shadcn.DrawerOverlayCompleter<T?> show<T>({
    required BuildContext context,
    required Widget child,
    shadcn.OverlayPosition position = shadcn.OverlayPosition.end,
    String? title,
    String? subtitle,
    IconData? icon,
    List<Widget>? actions,
    bool barrierDismissible = true,
    bool expands = false,
    BoxConstraints? constraints,
  }) {
    return shadcn.openDrawerOverlay<T>(
      context: context,
      position: position,
      barrierDismissible: barrierDismissible,
      expands: expands,
      constraints: constraints,
      builder: (context) {
        return AppDrawerSheet(
          title: title,
          subtitle: subtitle,
          icon: icon,
          actions: actions,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Standard Header
        if (title != null || icon != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: theme.typography.semiBold.copyWith(
                            fontSize: 16,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.typography.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                shadcn.IconButton.ghost(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    if (onClose != null) {
                      onClose!();
                    } else {
                      shadcn.closeDrawer(context);
                    }
                  },
                ),
              ],
            ),
          ),
        // Body Content
        Flexible(
          child: SingleChildScrollView(
            padding: padding,
            child: child,
          ),
        ),
        // Actions Strip
        if (actions != null && actions!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ),
      ],
    );
  }
}
