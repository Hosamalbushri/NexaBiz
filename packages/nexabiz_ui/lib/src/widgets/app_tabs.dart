import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Styling mode for [AppTabs].
enum AppTabStyle {
  /// Segmented rounded pill-style tabs (built on [shadcn.Tabs]).
  pills,

  /// Horizontal underline-style tabs (built on [shadcn.TabList]).
  underline,
}

/// Model defining a single tab item in [AppTabs].
class AppTabItem {
  /// Tab label text.
  final String label;

  /// Optional leading icon.
  final Widget? icon;

  /// Optional count or status badge string.
  final String? badge;

  /// Content panel widget associated with this tab.
  final Widget child;

  /// Creates an [AppTabItem].
  const AppTabItem({
    required this.label,
    required this.child,
    this.icon,
    this.badge,
  });
}

/// A canonical NexaBiz tabbed interface component for content panel switching.
///
/// Supports [AppTabStyle.pills] and [AppTabStyle.underline] styles while managing
/// header layout and content switching (with state preservation options).
class AppTabs extends StatelessWidget {
  /// Zero-based active tab index.
  final int index;

  /// Callback invoked when selected tab changes.
  final ValueChanged<int> onChanged;

  /// List of tab items defining header labels, icons, badges, and content panels.
  final List<AppTabItem> items;

  /// Styling mode ([AppTabStyle.pills] or [AppTabStyle.underline]).
  final AppTabStyle style;

  /// Whether tabs should expand horizontally to fill available width.
  final bool expand;

  /// Whether inactive tab content state is preserved in memory using an [IndexedStack].
  ///
  /// When false, only the active tab's child is mounted.
  final bool preserveState;

  /// Custom padding for tab headers.
  final EdgeInsetsGeometry? padding;

  /// Creates an [AppTabs] component.
  const AppTabs({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
    this.style = AppTabStyle.pills,
    this.expand = false,
    this.preserveState = true,
    this.padding,
  });

  Widget _buildTabLabel(AppTabItem item) {
    final labelWidget = Text(item.label);
    if (item.icon == null && item.badge == null) {
      return labelWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          item.icon!,
          const SizedBox(width: 6),
        ],
        labelWidget,
        if (item.badge != null) ...[
          const SizedBox(width: 6),
          shadcn.SecondaryBadge(
            child: Text(item.badge!),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex = index.clamp(0, items.length - 1);

    Widget header;
    if (style == AppTabStyle.pills) {
      header = shadcn.Tabs(
        index: safeIndex,
        onChanged: onChanged,
        expand: expand,
        padding: padding,
        children: items.map<shadcn.TabChild>((item) {
          return shadcn.TabItem(
            child: _buildTabLabel(item),
          );
        }).toList(),
      );
    } else {
      header = shadcn.TabList(
        index: safeIndex,
        onChanged: onChanged,
        children: items.map<shadcn.TabChild>((item) {
          return shadcn.TabItem(
            child: _buildTabLabel(item),
          );
        }).toList(),
      );
    }

    final Widget body = preserveState
        ? IndexedStack(
            index: safeIndex,
            children: items.map((e) => e.child).toList(),
          )
        : items[safeIndex].child;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 12),
        Expanded(child: body),
      ],
    );
  }
}
