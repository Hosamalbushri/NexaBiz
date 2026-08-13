import 'package:flutter/material.dart';

/// Shared navigator keys for the platform GoRouter.
///
/// Reassigned whenever [appRouterProvider] creates a new [GoRouter] so
/// go_router's `GlobalObjectKey(navigatorKey.hashCode)` cannot collide while
/// an old router is still disposing (hot reload / provider refresh).
GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'app-root',
);

GlobalKey<NavigatorState> appShellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'app-shell',
);
