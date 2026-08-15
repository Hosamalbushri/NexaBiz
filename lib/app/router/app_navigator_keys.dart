import 'package:flutter/material.dart';

/// Stable navigator keys for the platform [GoRouter].
///
/// These must remain the same instance for the process lifetime. Recreating
/// them while a [Navigator] is still mounted (provider refresh / hot reload)
/// causes "GlobalKey was used multiple times" under [HeroControllerScope].
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'app-root');

final GlobalKey<NavigatorState> appShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'app-shell');

final GlobalKey<NavigatorState> appDashboardBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'branch-dashboard');

final GlobalKey<NavigatorState> appServicesBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'branch-services');

final GlobalKey<NavigatorState> appReportsBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'branch-reports');

final GlobalKey<NavigatorState> appSettingsBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'branch-settings');
