import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// A canonical NexaBiz index-safe animated content transition container.
///
/// Built on top of [shadcn.Switcher].
/// Provides directional swipe and animated transitions between views, with
/// safe index boundary clamping.
class AppContentSwitcher extends StatelessWidget {
  /// Active child index.
  final int index;

  /// List of child view widgets to switch between.
  final List<Widget> children;

  /// Transition swipe direction (default: [AxisDirection.right]).
  final AxisDirection direction;

  /// Callback when active index changes through gestures.
  final ValueChanged<int>? onIndexChanged;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Creates an [AppContentSwitcher].
  const AppContentSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.direction = AxisDirection.right,
    this.onIndexChanged,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex = index.clamp(0, children.length - 1);

    return shadcn.Switcher(
      index: safeIndex,
      direction: direction,
      onIndexChanged: onIndexChanged,
      duration: duration,
      curve: curve,
      children: children,
    );
  }
}
