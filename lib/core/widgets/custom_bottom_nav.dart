import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Shell bottom bar for primary destinations, designed for a center-docked FAB.
///
/// Pair with [Scaffold.floatingActionButton] and
/// [FloatingActionButtonLocation.centerDocked] so Material owns the notched
/// cutout through the bar ([QuickActionsFab.barNotchShape]).
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height = barHeight,
    this.notchMargin = QuickActionsFab.notchMargin,
    this.shape = QuickActionsFab.barNotchShape,
  });

  /// Content height of the tab row (excluding system bottom inset).
  static const double barHeight = 64;

  /// Full reserved height including system bottom inset.
  static double contentHeight(double bottomInset) => barHeight + bottomInset;

  /// Bottom inset pages should clear when the shell chrome is visible.
  ///
  /// Includes the bar, system gesture/home inset, and the FAB overhang so the
  /// last page item sits above the chrome rather than under the docked button.
  static double bodyBottomInset(double systemBottomInset) =>
      barHeight + systemBottomInset + QuickActionsFab.dockOverlap;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<CustomBottomNavDestination> destinations;
  final double height;
  final double notchMargin;

  /// Pass `null` to disable the FAB notch (e.g. while the keyboard is open).
  final NotchedShape? shape;

  /// Width reserved for the docked FAB so tab labels stay clear of it.
  static const double _fabSlotWidth = QuickActionsFab.size + 16;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mid = destinations.length ~/ 2;
    final left = destinations.take(mid).toList(growable: false);
    final right = destinations.skip(mid).toList(growable: false);

    return BottomAppBar(
      // viewPadding keeps chrome stable when the keyboard opens.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      height: height + MediaQuery.viewPaddingOf(context).bottom,
      elevation: 8,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      color: colorScheme.surface,
      shape: shape,
      notchMargin: notchMargin,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
              const SizedBox(width: _fabSlotWidth),
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
    );
  }
}

/// Center-docked quick-actions FAB for the platform shell.
///
/// Rounded-square primary action with a matching [AutomaticNotchedShape] cradle
/// in [CustomBottomNav], plus premium entrance / press micro-interactions.
class QuickActionsFab extends StatefulWidget {
  const QuickActionsFab({
    super.key,
    required this.tooltip,
    required this.isOpen,
    required this.onPressed,
  });

  /// Compact square edge length (drives notch geometry with [notchMargin]).
  static const double size = 56;

  /// Corner radius for the squared FAB ([AppRadius.sm]).
  static const double cornerRadius = AppRadius.sm;

  /// Consistent air gap between FAB edge and the bar notch.
  static const double notchMargin = 8;

  /// How far the docked FAB extends above the bar's top edge.
  static const double dockOverlap = size / 2;

  /// Rounded-rect notch that follows the FAB shape (not a circular cutout).
  ///
  /// Guest corner radius is inflated by [notchMargin] so the cutout stays
  /// concentric with the button.
  static const NotchedShape barNotchShape = AutomaticNotchedShape(
    RoundedRectangleBorder(),
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(cornerRadius + notchMargin),
      ),
    ),
  );

  final String tooltip;
  final bool isOpen;
  final VoidCallback onPressed;

  @override
  State<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends State<QuickActionsFab>
    with SingleTickerProviderStateMixin {
  static const Duration _entranceDuration = Duration(milliseconds: 300);
  static const Duration _pressDuration = Duration(milliseconds: 120);
  static const Duration _releaseDuration = Duration(milliseconds: 160);
  static const Duration _iconDuration = Duration(milliseconds: 220);
  static const Duration _elevationDuration = Duration(milliseconds: 180);

  late final AnimationController _entrance;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _entranceScale;
  late final Animation<Offset> _entranceSlide;

  var _pressed = false;
  var _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    );
    _entranceOpacity = curve;
    _entranceScale = Tween<double>(begin: 0.85, end: 1).animate(curve);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) {
      return;
    }
    _entranceStarted = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entrance.value = 1;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entrance.forward();
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(QuickActionsFab.cornerRadius),
    );

    // Idle floats slightly higher when open; pressed settles toward the bar.
    final elevation = _pressed
        ? 2.0
        : widget.isOpen
        ? 6.0
        : 4.5;

    final pressScale = _pressed ? 0.94 : 1.0;
    final pressSlide = _pressed
        ? Offset.zero
        : (widget.isOpen ? const Offset(0, -0.04) : const Offset(0, -0.02));

    final pressDuration = _pressed ? _pressDuration : _releaseDuration;
    final pressCurve = _pressed ? Curves.easeInOut : Curves.easeOutCubic;

    Widget fab = SizedBox(
      width: QuickActionsFab.size,
      height: QuickActionsFab.size,
      child: AnimatedPhysicalModel(
        duration: reduceMotion ? Duration.zero : _elevationDuration,
        curve: Curves.easeOutCubic,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(QuickActionsFab.cornerRadius),
        elevation: elevation,
        color: colorScheme.primary,
        shadowColor: colorScheme.shadow.withValues(
          alpha: isDark ? 0.42 : 0.20,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: shape,
            onTap: _handleTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Center(
              child: AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : _iconDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final rotated = Tween<double>(begin: 0.85, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: rotated,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  widget.isOpen ? Icons.close_rounded : Icons.add_rounded,
                  key: ValueKey<bool>(widget.isOpen),
                  size: 24,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    fab = AnimatedScale(
      scale: pressScale,
      duration: reduceMotion ? Duration.zero : pressDuration,
      curve: pressCurve,
      child: AnimatedSlide(
        offset: pressSlide,
        duration: reduceMotion ? Duration.zero : pressDuration,
        curve: pressCurve,
        child: fab,
      ),
    );

    return Semantics(
      button: true,
      enabled: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedBuilder(
          animation: _entrance,
          builder: (context, child) {
            return FadeTransition(
              opacity: _entranceOpacity,
              child: SlideTransition(
                position: _entranceSlide,
                child: ScaleTransition(
                  scale: _entranceScale,
                  child: child,
                ),
              ),
            );
          },
          child: fab,
        ),
      ),
    );
  }
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
