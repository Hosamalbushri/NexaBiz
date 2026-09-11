import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Model representing a single item in an [AppBreadcrumb] trail.
class AppBreadcrumbItem {
  /// Display text for the item.
  final String label;

  /// Navigation tap callback. If null, the item is non-interactive.
  final VoidCallback? onTap;

  /// Optional leading icon.
  final Widget? icon;

  /// Creates an [AppBreadcrumbItem].
  const AppBreadcrumbItem({
    required this.label,
    this.onTap,
    this.icon,
  });
}

/// A canonical NexaBiz route hierarchy breadcrumb trail component.
///
/// Built on top of [shadcn.Breadcrumb].
/// Displays route path items separated by arrows or slashes, with automatic
/// formatting for active and preceding location nodes.
class AppBreadcrumb extends StatelessWidget {
  /// List of breadcrumb trail items.
  final List<AppBreadcrumbItem> items;

  /// Custom separator widget (defaults to [shadcn.Breadcrumb.arrowSeparator]).
  final Widget? separator;

  /// Outer padding.
  final EdgeInsetsGeometry? padding;

  /// Creates an [AppBreadcrumb].
  const AppBreadcrumb({
    super.key,
    required this.items,
    this.separator,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      Widget labelWidget = Text(item.label);
      if (item.icon != null) {
        labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            item.icon!,
            const SizedBox(width: 4),
            labelWidget,
          ],
        );
      }

      if (!isLast && item.onTap != null) {
        labelWidget = GestureDetector(
          onTap: item.onTap,
          child: labelWidget,
        );
      }

      children.add(labelWidget);
    }

    return shadcn.Breadcrumb(
      separator: separator ?? shadcn.Breadcrumb.arrowSeparator,
      padding: padding,
      children: children,
    );
  }
}
