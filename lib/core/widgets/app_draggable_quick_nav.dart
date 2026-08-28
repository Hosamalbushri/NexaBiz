import 'package:flutter/material.dart';

import 'app_quick_navigation_sheet.dart';

/// Floating quick navigation button (compact 48x48 circle without text)
/// that can be dragged and moved anywhere on the screen by the user.
class AppDraggableQuickNav extends StatefulWidget {
  const AppDraggableQuickNav({
    super.key,
    this.initialOffset,
    this.child,
  });

  final Offset? initialOffset;
  final Widget? child;

  /// Global overlay helper to insert the draggable floating navigation button on top of the active navigator overlay.
  static OverlayEntry? _overlayEntry;

  static void showOverlay(BuildContext context) {
    hideOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(
      builder: (ctx) => const AppDraggableQuickNav(),
    );
    overlay.insert(_overlayEntry!);
  }

  static void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  State<AppDraggableQuickNav> createState() => _AppDraggableQuickNavState();
}

class _AppDraggableQuickNavState extends State<AppDraggableQuickNav> {
  Offset? _offset;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Initialize default position (top-left area)
    _offset ??= widget.initialOffset ??
        Offset(
          16.0,
          padding.top + 12.0,
        );

    final theme = Theme.of(context);

    return Positioned(
      left: _offset!.dx,
      top: _offset!.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            double newX = _offset!.dx + details.delta.dx;
            double newY = _offset!.dy + details.delta.dy;

            // Clamp within screen boundaries for 36x36 button
            const minX = 12.0;
            final maxX = screenSize.width - 48.0;
            final minY = padding.top + 12.0;
            final maxY = screenSize.height - padding.bottom - 48.0;

            newX = newX.clamp(minX, maxX > minX ? maxX : minX);
            newY = newY.clamp(minY, maxY > minY ? maxY : minY);

            _offset = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const AppQuickNavigationSheet(),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          transform: Matrix4.diagonal3Values(_isDragging ? 1.12 : 1.0, _isDragging ? 1.12 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: _isDragging ? 0.9 : 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: _isDragging ? 0.8 : 0.35),
              width: _isDragging ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: _isDragging ? 0.35 : 0.12),
                blurRadius: _isDragging ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.widgets_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
