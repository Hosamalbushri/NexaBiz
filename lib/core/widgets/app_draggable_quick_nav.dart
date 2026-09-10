import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/presentation/providers/quick_nav_settings_provider.dart';
import 'app_quick_navigation_sheet.dart';

/// Floating quick navigation button (compact 48x48 circle without text)
/// that can be dragged and moved anywhere on the screen by the user.
///
/// Automatically respects user enable/disable preferences and persists
/// custom X, Y screen positions.
class AppDraggableQuickNav extends ConsumerStatefulWidget {
  const AppDraggableQuickNav({super.key, this.initialOffset, this.child});

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
  ConsumerState<AppDraggableQuickNav> createState() => _AppDraggableQuickNavState();
}

class _AppDraggableQuickNavState extends ConsumerState<AppDraggableQuickNav> {
  Offset? _offset;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(quickNavSettingsProvider);

    // Completely hidden when disabled in user settings
    if (!settings.enabled) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Use persisted user position, explicit initialOffset, or default bottom-left
    _offset ??= settings.position ??
        widget.initialOffset ??
        Offset(
          16.0,
          screenSize.height - padding.bottom - 100.0,
        );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

            // Clamp within screen boundaries for 44x44 button
            const minX = 12.0;
            final maxX = screenSize.width - 56.0;
            final minY = padding.top + 12.0;
            final maxY = screenSize.height - padding.bottom - 56.0;

            newX = newX.clamp(minX, maxX > minX ? maxX : minX);
            newY = newY.clamp(minY, maxY > minY ? maxY : minY);

            _offset = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
          if (_offset != null) {
            ref.read(quickNavSettingsProvider.notifier).updatePosition(
                  _offset!.dx,
                  _offset!.dy,
                );
          }
        },
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const AppQuickNavigationSheet(),
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isDragging ? 1.0 : 0.70,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            transform: Matrix4.diagonal3Values(
              _isDragging ? 1.10 : 1.0,
              _isDragging ? 1.10 : 1.0,
              1.0,
            ),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isDark
                      ? theme.colorScheme.surfaceContainerHigh
                      : theme.colorScheme.surface)
                  .withValues(alpha: _isDragging ? 0.98 : 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(
                  alpha: _isDragging ? 0.90 : 0.45,
                ),
                width: _isDragging ? 2.0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(
                    alpha: isDark ? 0.35 : 0.12,
                  ),
                  blurRadius: _isDragging ? 14 : 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.widgets_rounded,
                size: 22,
                color: theme.colorScheme.primary.withValues(
                  alpha: _isDragging ? 1.0 : 0.90,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
