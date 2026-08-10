import 'package:flutter/material.dart';

/// Premium bottom navigation bar matching [CustomAppBar] visual language.
///
/// Optional [centerAction] renders a floating add control that sits slightly
/// above the tab row (typical pattern: 2 + add + 2).
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.centerAction,
    this.borderRadius = 24,
    this.elevation = 8,
    this.height = 72,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<CustomBottomNavDestination> destinations;
  final CustomBottomNavCenterAction? centerAction;
  final double borderRadius;
  final double elevation;
  final double height;

  static const double _fabSize = 56;
  static const double _fabLift = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasCenter = centerAction != null;
    final lift = hasCenter ? _fabLift : 0.0;

    final shadowColor =
        colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12);

    final mid = destinations.length ~/ 2;
    final left = destinations.take(mid).toList(growable: false);
    final right = destinations.skip(mid).toList(growable: false);

    return SizedBox(
      height: height + bottomInset + lift,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: elevation * 2.4,
                      offset: Offset(0, -elevation * 0.35),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: height + bottomInset,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 8,
                      end: 8,
                      top: 8,
                      bottom: bottomInset > 0 ? bottomInset : 8,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < left.length; i++)
                          Expanded(
                            child: _NavItem(
                              destination: left[i],
                              selected: i == selectedIndex,
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                        if (hasCenter)
                          const SizedBox(width: _fabSize + 8),
                        for (var i = 0; i < right.length; i++)
                          Expanded(
                            child: _NavItem(
                              destination: right[i],
                              selected: (mid + i) == selectedIndex,
                              onTap: () => onDestinationSelected(mid + i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasCenter)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _FloatingCenterButton(
                  action: centerAction!,
                  size: _fabSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Non-destination center control for [CustomBottomNav] (e.g. quick actions).
@immutable
class CustomBottomNavCenterAction {
  const CustomBottomNavCenterAction({
    required this.onPressed,
    required this.tooltip,
    this.icon = Icons.add_rounded,
    this.key,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Key? key;
}

/// Destination model for [CustomBottomNav].
@immutable
class CustomBottomNavDestination {
  const CustomBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _FloatingCenterButton extends StatelessWidget {
  const _FloatingCenterButton({
    required this.action,
    required this.size,
  });

  final CustomBottomNavCenterAction action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: action.tooltip,
      child: Tooltip(
        message: action.tooltip,
        child: Material(
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          color: colorScheme.primary,
          child: InkWell(
            key: action.key,
            onTap: action.onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                action.icon,
                size: 28,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final CustomBottomNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.62),
          letterSpacing: -0.1,
          height: 1.1,
        );

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 24,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: labelStyle ?? const TextStyle(fontSize: 11),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
