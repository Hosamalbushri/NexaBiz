import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/custom_bottom_nav.dart';
import '../localization/app_localizations.dart';
import '../navigation/app_navigation_items.dart';
import '../presentation/pages/quick_actions_sheet.dart';
import '../presentation/providers/quick_actions_panel_provider.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';

/// Key for the shell quick-actions (add) control — used in widget tests.
const Key kQuickActionsNavButtonKey = ValueKey<String>('quick_actions_nav');

/// Persistent platform chrome around shell branches and module pages.
///
/// Mobile: [BottomAppBar] ([CustomBottomNav] + rounded-square notch) with
/// center-docked [QuickActionsFab]
/// Tablet: [NavigationRail] with leading add
/// Desktop: persistent side panel with quick-actions entry
///
/// Chrome is shown only on primary shell tabs (Dashboard / Services / Reports /
/// Settings). Module routes render full-bleed with their own app bars.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  static const Duration _panelDuration = Duration(milliseconds: 260);
  static const Curve _panelCurve = Curves.easeOutCubic;

  late final AnimationController _panelController;
  late final Animation<double> _panelAnimation;

  /// Intent flag — flips immediately on tap so the FAB icon stays responsive
  /// even while the panel animation is still catching up.
  var _quickActionsOpen = false;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: _panelDuration,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: _panelCurve,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location && _quickActionsOpen) {
      _closeQuickActions();
    }
  }

  bool get _showShellChrome => isPrimaryShellLocation(widget.location);

  void _onSelect(BuildContext context, int index) {
    final items = appNavigationItems();
    if (index < 0 || index >= items.length) {
      return;
    }
    final target = items[index].path;
    final currentIndex = selectedNavigationIndex(widget.location);
    if (index == currentIndex && widget.location == target) {
      return;
    }
    if (_quickActionsOpen) {
      _closeQuickActions();
    }
    context.go(target);
  }

  void _toggleQuickActions() {
    if (_quickActionsOpen) {
      _closeQuickActions();
    } else {
      _openQuickActions();
    }
  }

  void _openQuickActions() {
    if (_quickActionsOpen && _panelController.isCompleted) {
      return;
    }
    setState(() => _quickActionsOpen = true);
    _panelController.forward();
  }

  void _closeQuickActions() {
    if (!_quickActionsOpen && _panelController.isDismissed) {
      return;
    }
    setState(() => _quickActionsOpen = false);
    _panelController.reverse();
  }

  Widget _animatedQuickActionIcon({required bool mini}) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _quickActionsOpen ? Icons.close_rounded : Icons.add_rounded;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Icon(
        icon,
        key: ValueKey<bool>(_quickActionsOpen),
        size: mini ? 20 : 24,
        color: mini ? colorScheme.onPrimary : null,
      ),
    );
  }

  Widget _buildQuickActionsLayer({
    required Widget child,
    required double navHeight,
  }) {
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, _) {
        final t = _panelAnimation.value;
        final colorScheme = Theme.of(context).colorScheme;

        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (t > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: navHeight,
                child: GestureDetector(
                  onTap: _closeQuickActions,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: colorScheme.scrim.withValues(alpha: 0.45 * t),
                  ),
                ),
              ),
            if (t > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: navHeight,
                child: FractionalTranslation(
                  translation: Offset(0, 1 - t),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: _DismissibleQuickActionsPanel(
                      animationValue: t,
                      onClose: _closeQuickActions,
                      onDragClose: (progress) {
                        // progress 0 = fully open, 1 = fully dismissed
                        _panelController.value = (1 - progress).clamp(0.0, 1.0);
                      },
                      onDragEnd: (dismiss) {
                        if (dismiss) {
                          _closeQuickActions();
                        } else {
                          _openQuickActions();
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(quickActionsCloseRequestProvider, (previous, next) {
      if (previous != next && _quickActionsOpen) {
        _closeQuickActions();
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final l10n = AppLocalizations.of(context);
    final items = appNavigationItems();
    final selectedIndex = selectedNavigationIndex(widget.location);
    final railIndex = selectedIndex < 0 ? null : selectedIndex;
    final media = MediaQuery.of(context);
    // Use viewPadding (not padding): padding.bottom collapses when the keyboard
    // opens, which would shrink/jump the shell chrome.
    final systemBottomInset = media.viewPadding.bottom;
    final showChrome = _showShellChrome;
    final navHeight = showChrome
        ? CustomBottomNav.contentHeight(systemBottomInset)
        : 0.0;
    final bodyBottomPadding = showChrome
        ? CustomBottomNav.bodyBottomInset(systemBottomInset)
        : media.padding.bottom;

    if (AppBreakpoints.isMobile(width)) {
      final keyboardOpen = media.viewInsets.bottom > 0;
      if (keyboardOpen && _quickActionsOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _quickActionsOpen) {
            _closeQuickActions();
          }
        });
      }

      return PopScope(
        canPop: !_quickActionsOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _closeQuickActions();
          }
        },
        child: Scaffold(
          // Keep docked FAB + BottomAppBar fixed when the keyboard opens.
          resizeToAvoidBottomInset: false,
          // Required so the notched BottomAppBar reveals body through the cutout.
          extendBody: showChrome,
          body: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(bottom: bodyBottomPadding),
            ),
            child: _buildQuickActionsLayer(
              navHeight: navHeight,
              child: widget.child,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: showChrome && !keyboardOpen
              ? QuickActionsFab(
                  key: kQuickActionsNavButtonKey,
                  tooltip: l10n.quickActionsTitle,
                  isOpen: _quickActionsOpen,
                  onPressed: _toggleQuickActions,
                )
              : null,
          bottomNavigationBar: showChrome
              ? CustomBottomNav(
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  onDestinationSelected: (i) => _onSelect(context, i),
                  destinations: [
                    for (final item in items)
                      CustomBottomNavDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: item.label(l10n),
                      ),
                  ],
                  // Drop the notch while the FAB is hidden for the keyboard.
                  shape: keyboardOpen ? null : QuickActionsFab.barNotchShape,
                )
              : null,
        ),
      );
    }

    if (AppBreakpoints.isTablet(width)) {
      if (!showChrome) {
        return PopScope(
          canPop: !_quickActionsOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _closeQuickActions();
            }
          },
          child: Scaffold(
            body: _buildQuickActionsLayer(navHeight: 0, child: widget.child),
          ),
        );
      }

      return PopScope(
        canPop: !_quickActionsOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _closeQuickActions();
          }
        },
        child: Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: railIndex,
                onDestinationSelected: (i) => _onSelect(context, i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: FloatingActionButton(
                    key: kQuickActionsNavButtonKey,
                    mini: true,
                    tooltip: l10n.quickActionsTitle,
                    onPressed: _toggleQuickActions,
                    child: _animatedQuickActionIcon(mini: true),
                  ),
                ),
                destinations: [
                  for (final item in items)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label(l10n)),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildQuickActionsLayer(
                  navHeight: 0,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!showChrome) {
      return PopScope(
        canPop: !_quickActionsOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _closeQuickActions();
          }
        },
        child: Scaffold(
          body: _buildQuickActionsLayer(navHeight: 0, child: widget.child),
        ),
      );
    }

    return PopScope(
      canPop: !_quickActionsOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closeQuickActions();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 260,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          0,
                          AppSpacing.sm,
                          AppSpacing.md,
                        ),
                        child: FilledButton.tonalIcon(
                          key: kQuickActionsNavButtonKey,
                          onPressed: _toggleQuickActions,
                          icon: _animatedQuickActionIcon(mini: false),
                          label: Text(l10n.quickActionsTitle),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (var i = 0; i < items.length; i++)
                        _DrawerTile(
                          selected: selectedIndex == i,
                          icon: selectedIndex == i
                              ? items[i].selectedIcon
                              : items[i].icon,
                          label: items[i].label(l10n),
                          onTap: () => _onSelect(context, i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _buildQuickActionsLayer(
                navHeight: 0,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-actions panel with downward drag-to-dismiss from the grabber area.
class _DismissibleQuickActionsPanel extends StatelessWidget {
  const _DismissibleQuickActionsPanel({
    required this.animationValue,
    required this.onClose,
    required this.onDragClose,
    required this.onDragEnd,
  });

  final double animationValue;
  final VoidCallback onClose;
  final ValueChanged<double> onDragClose;
  final ValueChanged<bool> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.58;

    return Stack(
      children: [
        QuickActionsPanel(onClose: onClose),
        // Drag handle hit target at the top — avoids fighting the grid scroll.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 56,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              final delta = details.primaryDelta ?? 0;
              if (delta == 0) {
                return;
              }
              final next = (1 - animationValue) + (delta / maxHeight);
              onDragClose(next.clamp(0.0, 1.0));
            },
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              final dismiss = velocity > 700 || animationValue < 0.55;
              onDragEnd(dismiss);
            },
          ),
        ),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: ListTile(
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.12),
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}
