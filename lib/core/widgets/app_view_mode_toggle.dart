import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';

/// Descriptor for an option in an [AppViewModeToggle].
class AppViewModeOption<T> {
  const AppViewModeOption({
    required this.value,
    required this.icon,
    required this.tooltip,
  });

  final T value;
  final IconData icon;
  final String tooltip;
}

/// Generic segmented view mode toggle widget.
///
/// Allows switching between collection view modes (e.g. List, Grid) using styled icon buttons.
class AppViewModeToggle<T> extends StatelessWidget {
  const AppViewModeToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<AppViewModeOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option.value == selected;
          return IconButton(
            tooltip: option.tooltip,
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            style: IconButton.styleFrom(
              backgroundColor: isSelected ? scheme.surface : Colors.transparent,
              foregroundColor: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              elevation: isSelected ? 1 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            icon: Icon(option.icon),
            onPressed: () => onChanged(option.value),
          );
        }).toList(),
      ),
    );
  }
}
