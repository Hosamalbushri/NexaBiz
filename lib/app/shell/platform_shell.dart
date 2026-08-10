import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';

/// Responsive platform chrome around home/settings routes.
///
/// Mobile: content only (actions live in AppBar).
/// Tablet: [NavigationRail].
/// Desktop: persistent [NavigationDrawer]-style side panel.
class PlatformShell extends StatelessWidget {
  const PlatformShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final location = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context);

    if (AppBreakpoints.isMobile(width)) {
      return child;
    }

    final selectedIndex = location.startsWith(AppRoutes.settings) ? 1 : 0;

    void onSelect(int index) {
      if (index == 0) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.settings);
      }
    }

    if (AppBreakpoints.isTablet(width)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.apps_outlined),
                  selectedIcon: const Icon(Icons.apps_rounded),
                  label: Text(l10n.navigationHome),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: Text(l10n.settingsTitle),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DrawerTile(
                      selected: selectedIndex == 0,
                      icon: Icons.apps_rounded,
                      label: l10n.navigationHome,
                      onTap: () => onSelect(0),
                    ),
                    _DrawerTile(
                      selected: selectedIndex == 1,
                      icon: Icons.settings_rounded,
                      label: l10n.settingsTitle,
                      onTap: () => onSelect(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.12),
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}
