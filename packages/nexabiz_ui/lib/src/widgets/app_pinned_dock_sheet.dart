import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical ERP staged dock panel built on `shadcn.PinnedSheet` and `shadcn.SheetController`.
///
/// Provides staged bottom or side snap points (peek drag handle, fraction, expanded),
/// header with stage toggle button, and content wrapper.
class AppPinnedDockSheet extends StatelessWidget {
  const AppPinnedDockSheet({
    super.key,
    required this.child,
    this.controller,
    this.title,
    this.subtitle,
    this.icon,
    this.position = shadcn.OverlayPosition.bottom,
    this.stages = const [
      shadcn.SheetStage.peekDragHandle(),
      shadcn.SheetStage.fraction(0.4),
      shadcn.SheetStage.expanded(),
    ],
    this.initialStage,
    this.backdrop,
    this.draggable = true,
    this.showDragHandle = true,
  });

  /// The dock main content.
  final Widget child;

  /// Optional controller driving this sheet.
  final shadcn.SheetController? controller;

  /// Dock header title.
  final String? title;

  /// Dock header subtitle.
  final String? subtitle;

  /// Dock header icon.
  final IconData? icon;

  /// Dock position edge.
  final shadcn.OverlayPosition position;

  /// List of snap stages.
  final List<shadcn.SheetStage> stages;

  /// Initial snap stage.
  final shadcn.SheetStage? initialStage;

  /// Optional background widget transformed by sheet opening.
  final Widget? backdrop;

  /// Whether the sheet can be dragged.
  final bool draggable;

  /// Whether to show the drag handle.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return shadcn.PinnedSheet(
      position: position,
      controller: controller,
      stages: stages,
      initialStage: initialStage,
      backdrop: backdrop,
      draggable: draggable,
      showDragHandle: showDragHandle,
      child: Builder(builder: (context) {
        final theme = shadcn.Theme.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || icon != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
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
                                fontSize: 14,
                                color: theme.colorScheme.foreground,
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.typography.small.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (controller != null)
                      shadcn.IconButton.ghost(
                        icon: const Icon(Icons.unfold_more, size: 16),
                        onPressed: () {
                          if (controller!.fraction > 0.5) {
                            controller!.animateTo(const shadcn.SheetStage.fraction(0.4));
                          } else {
                            controller!.open();
                          }
                        },
                      ),
                  ],
                ),
              ),
            Flexible(child: child),
          ],
        );
      }),
    );
  }
}
