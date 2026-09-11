import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Style of overlay handler used by [AppSwiperSheet].
enum AppSwiperStyle {
  /// Swiper opens content using sheet mechanics.
  sheet,

  /// Swiper opens content using drawer mechanics (supports backdrop scale transform).
  drawer,
}

/// Canonical gesture-swipable overlay wrapper built on `shadcn_flutter`'s [shadcn.Swiper].
///
/// Wraps a [child] widget (e.g., a card, list item, or action edge) and opens
/// overlay content when swiped in the specified [position] direction.
class AppSwiperSheet extends StatelessWidget {
  const AppSwiperSheet({
    super.key,
    required this.child,
    required this.overlayBuilder,
    this.position = shadcn.OverlayPosition.bottom,
    this.style = AppSwiperStyle.sheet,
    this.enabled = true,
    this.draggable = true,
    this.barrierDismissible = true,
    this.showDragHandle = true,
    this.transformBackdrop = true,
    this.borderRadius,
  });

  /// Trigger child widget that receives gesture interaction.
  final Widget child;

  /// Builder for the overlay content revealed on swipe gesture.
  final WidgetBuilder overlayBuilder;

  /// Overlay edge position (bottom, start/left, end/right, top).
  final shadcn.OverlayPosition position;

  /// Style of overlay (sheet or drawer).
  final AppSwiperStyle style;

  /// Whether the swiper gesture is enabled.
  final bool enabled;

  /// Whether the overlay itself can be dragged to dismiss.
  final bool draggable;

  /// Whether clicking the barrier dismisses the overlay.
  final bool barrierDismissible;

  /// Whether to display a drag handle on the overlay container.
  final bool showDragHandle;

  /// Whether to apply scale transform to the backdrop window.
  final bool transformBackdrop;

  /// Custom border radius for the overlay container.
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final handler = style == AppSwiperStyle.drawer
        ? shadcn.SwiperHandler.drawer
        : shadcn.SwiperHandler.sheet;

    return shadcn.Swiper(
      enabled: enabled,
      position: position,
      handler: handler,
      builder: overlayBuilder,
      draggable: draggable,
      barrierDismissible: barrierDismissible,
      showDragHandle: showDragHandle,
      transformBackdrop: transformBackdrop,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
