import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Descriptor for an option item in an [AppExclusiveToggleGroup].
class ToggleOption<T> {
  const ToggleOption({
    required this.value,
    required this.child,
    this.tooltip,
    this.enabled = true,
  });

  final T value;
  final Widget child;
  final String? tooltip;
  final bool enabled;
}

/// Generic canonical exclusive toggle group component for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.Toggle] primitives to provide exclusive selection
/// behavior over generic type [T] options (e.g. view modes list/grid, text alignment left/center/right,
/// or formatting options).
class AppExclusiveToggleGroup<T> extends StatelessWidget {
  const AppExclusiveToggleGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.orientation = Axis.horizontal,
    this.gap = 4.0,
  });

  final List<ToggleOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final Axis orientation;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final isGroupEnabled = enabled && onChanged != null;

    final toggleButtons = options.map((option) {
      final isSelected = option.value == value;
      final isOptionEnabled = isGroupEnabled && option.enabled;

      Widget toggle = shadcn.Toggle(
        value: isSelected,
        enabled: isOptionEnabled,
        onChanged: isOptionEnabled
            ? (val) {
                if (val && onChanged != null) {
                  onChanged!(option.value);
                }
              }
            : null,
        child: option.child,
      );

      if (option.tooltip != null && option.tooltip!.isNotEmpty) {
        toggle = shadcn.Tooltip(
          tooltip: (context) => shadcn.TooltipContainer(
            child: Text(option.tooltip!),
          ),
          child: toggle,
        );
      }

      return toggle;
    }).toList();

    if (orientation == Axis.horizontal) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(theme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildSpacedChildren(toggleButtons, gap),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(theme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildSpacedChildren(toggleButtons, gap),
        ),
      );
    }
  }

  List<Widget> _buildSpacedChildren(List<Widget> children, double gap) {
    if (children.isEmpty) return [];
    final spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(
          orientation == Axis.horizontal
              ? SizedBox(width: gap)
              : SizedBox(height: gap),
        );
      }
    }
    return spaced;
  }
}
