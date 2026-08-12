import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../app_typography.dart';

/// NavigationBar / NavigationRail / AppBar themes.
class AppNavigationThemes {
  const AppNavigationThemes._();

  static AppBarTheme appBar(ColorScheme scheme, Brightness brightness) {
    return AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 3,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: AppSpacing.page,
      titleTextStyle: AppTypography.appBarTitle(scheme.onSurface),
    );
  }

  static NavigationBarThemeData navigationBar(ColorScheme scheme) {
    return NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return AppTypography.textTheme(Brightness.light).labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.62),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.62),
        );
      }),
    );
  }

  static NavigationRailThemeData navigationRail(ColorScheme scheme) {
    return NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurface.withValues(alpha: 0.62),
      ),
      selectedLabelTextStyle: AppTypography.textTheme(Brightness.light)
          .labelMedium
          ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: AppTypography.textTheme(
        Brightness.light,
      ).labelMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.62)),
    );
  }

  static BottomAppBarThemeData bottomAppBar(ColorScheme scheme) {
    return BottomAppBarThemeData(
      color: scheme.surface,
      elevation: 8,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow.withValues(alpha: 0.14),
      padding: EdgeInsets.zero,
    );
  }
}
