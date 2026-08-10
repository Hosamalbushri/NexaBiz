import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/custom_bottom_nav.dart';
import '../localization/app_localizations.dart';
import '../navigation/app_navigation_items.dart';
import '../presentation/pages/quick_actions_sheet.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';

/// Key for the shell quick-actions (add) control — used in widget tests.
const Key kQuickActionsNavButtonKey = ValueKey<String>('quick_actions_nav');

/// Persistent platform chrome around shell branches and module pages.
///
/// Mobile: [CustomBottomNav] with center quick-actions add
/// Tablet: [NavigationRail] with leading add
/// Desktop: persistent side panel with quick-actions entry
///
/// Shown for all authenticated app routes except splash (and error pages).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const Duration _panelDuration = Duration(milliseconds: 480);
  static const Curve _panelCurve = Curves.easeInOutCubic;

  bool _quickActionsOpen = false;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location && _quickActionsOpen) {
      _quickActionsOpen = false;
    }
  }

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
      setState(() => _quickActionsOpen = false);
    }
    context.go(target);
  }

  void _toggleQuickActions() {
    setState(() => _quickActionsOpen = !_quickActionsOpen);
  }

  void _closeQuickActions() {
    if (!_quickActionsOpen) {
      return;
    }
    setState(() => _quickActionsOpen = false);
  }

  Widget _withQuickActionsOverlay(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_quickActionsOpen,
            child: AnimatedOpacity(
              opacity: _quickActionsOpen ? 1 : 0,
              duration: _panelDuration,
              curve: _panelCurve,
              child: GestureDetector(
                onTap: _closeQuickActions,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .scrim
                      .withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            ignoring: !_quickActionsOpen,
            child: AnimatedSlide(
              offset: _quickActionsOpen ? Offset.zero : const Offset(0, 1),
              duration: _panelDuration,
              curve: _panelCurve,
              child: AnimatedOpacity(
                opacity: _quickActionsOpen ? 1 : 0,
                duration: _panelDuration,
                curve: _panelCurve,
                child: QuickActionsPanel(onClose: _closeQuickActions),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _animatedQuickActionIcon({required bool mini}) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _quickActionsOpen ? Icons.close_rounded : Icons.add_rounded;

    return AnimatedScale(
      scale: _quickActionsOpen ? 1.08 : 1,
      duration: _panelDuration,
      curve: _panelCurve,
      child: AnimatedSwitcher(
        duration: _panelDuration,
        switchInCurve: _panelCurve,
        switchOutCurve: _panelCurve,
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.75, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: _panelCurve,
              ),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          icon,
          key: ValueKey<bool>(_quickActionsOpen),
          size: mini ? 20 : 24,
          color: mini ? colorScheme.onPrimary : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final l10n = AppLocalizations.of(context);
    final items = appNavigationItems();
    final selectedIndex = selectedNavigationIndex(widget.location);
    final railIndex = selectedIndex < 0 ? null : selectedIndex;

    if (AppBreakpoints.isMobile(width)) {
      return PopScope(
        canPop: !_quickActionsOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _closeQuickActions();
          }
        },
        child: Scaffold(
          body: _withQuickActionsOverlay(widget.child),
          bottomNavigationBar: CustomBottomNav(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => _onSelect(context, i),
            destinations: [
              for (final item in items)
                CustomBottomNavDestination(
                  icon: item.icon,
                  selectedIcon: item.selectedIcon,
                  label: item.label(l10n),
                ),
            ],
            centerAction: CustomBottomNavCenterAction(
              key: kQuickActionsNavButtonKey,
              tooltip: l10n.quickActionsTitle,
              isOpen: _quickActionsOpen,
              onPressed: _toggleQuickActions,
            ),
          ),
        ),
      );
    }

    if (AppBreakpoints.isTablet(width)) {
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
              Expanded(child: _withQuickActionsOverlay(widget.child)),
            ],
          ),
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
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
            Expanded(child: _withQuickActionsOverlay(widget.child)),
          ],
        ),
      ),
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
