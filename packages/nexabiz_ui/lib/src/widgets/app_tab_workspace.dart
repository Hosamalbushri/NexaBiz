import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// A canonical NexaBiz advanced workspace tab container built on [shadcn.TabPane].
///
/// Supports drag-and-drop sortable tabs, closable tab items, add-tab buttons,
/// and leading/trailing tab-bar action controls.
class AppTabWorkspace<T> extends StatelessWidget {
  /// List of tab pane items.
  final List<shadcn.TabPaneData<T>> items;

  /// Currently focused tab index.
  final int focused;

  /// Callback when focused tab index changes.
  final ValueChanged<int> onFocused;

  /// Callback when tabs are reordered through drag-and-drop.
  final ValueChanged<List<shadcn.TabPaneData<T>>>? onSort;

  /// Function mapping item data model to tab title label string.
  final String Function(T item) titleBuilder;

  /// Optional badge text builder for tab items.
  final String? Function(T item)? badgeBuilder;

  /// Optional leading icon/widget builder for tab items.
  final Widget? Function(T item)? leadingBuilder;

  /// Callback when close action button on a tab is tapped.
  final ValueChanged<T>? onCloseTab;

  /// Callback when add-tab button is tapped.
  final VoidCallback? onAddTab;

  /// Additional widgets displayed at the leading edge of the tab bar.
  final List<Widget> leadingActions;

  /// Additional widgets displayed at the trailing edge of the tab bar.
  final List<Widget> trailingActions;

  /// Active tab content display area.
  final Widget child;

  /// Custom bar height.
  final double? barHeight;

  /// Creates an [AppTabWorkspace].
  const AppTabWorkspace({
    super.key,
    required this.items,
    required this.focused,
    required this.onFocused,
    required this.titleBuilder,
    required this.child,
    this.onSort,
    this.badgeBuilder,
    this.leadingBuilder,
    this.onCloseTab,
    this.onAddTab,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeFocused = focused.clamp(0, items.length - 1);

    final resolvedTrailing = [
      ...trailingActions,
      if (onAddTab != null)
        shadcn.GhostButton(
          density: shadcn.ButtonDensity.compact,
          onPressed: onAddTab,
          child: const Icon(Icons.add_rounded, size: 16),
        ),
    ];

    return shadcn.TabPane<T>(
      items: items,
      focused: safeFocused,
      onFocused: onFocused,
      onSort: onSort,
      leading: leadingActions,
      trailing: resolvedTrailing,
      barHeight: barHeight,
      itemBuilder: (context, itemData, index) {
        final data = itemData.data;
        final title = titleBuilder(data);
        final badge = badgeBuilder?.call(data);
        final leading = leadingBuilder?.call(data);

        return shadcn.TabItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 6),
              ],
              Text(title),
              if (badge != null) ...[
                const SizedBox(width: 6),
                shadcn.SecondaryBadge(
                  child: Text(badge),
                ),
              ],
              if (onCloseTab != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onCloseTab!(data),
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(Icons.close_rounded, size: 14),
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
