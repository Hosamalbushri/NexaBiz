import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/modules/module_providers.dart';
import '../../core/widgets/app_dialog.dart';
import '../localization/app_localizations.dart';
import '../presentation/pages/service_launcher_page.dart';
import '../settings/platform_settings_page.dart';
import '../shell/platform_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Composes platform shell routes with routes contributed by registered modules.
final appRouterProvider = Provider<GoRouter>((ref) {
  final registry = ref.watch(moduleRegistryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ShellExitScope(child: PlatformShell(child: child));
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const ServiceLauncherPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const PlatformSettingsPage(),
          ),
        ],
      ),
      ...registry.routes,
    ],
  );
});

/// Intercepts Android/iOS system back on the shell route.
///
/// Nested shell pages (e.g. settings pushed from home) are popped first.
/// On the home screen, shows an exit confirmation instead of closing the app.
class _ShellExitScope extends StatefulWidget {
  const _ShellExitScope({required this.child});

  final Widget child;

  @override
  State<_ShellExitScope> createState() => _ShellExitScopeState();
}

class _ShellExitScopeState extends State<_ShellExitScope> {
  bool _exitPromptOpen = false;

  Future<void> _handleSystemBack() async {
    if (_exitPromptOpen || !mounted) {
      return;
    }

    final shellNavigator = _shellNavigatorKey.currentState;
    if (shellNavigator != null && shellNavigator.canPop()) {
      shellNavigator.pop();
      return;
    }

    final location = GoRouterState.of(context).uri.path;
    if (location != AppRoutes.home) {
      GoRouter.of(context).go(AppRoutes.home);
      return;
    }

    _exitPromptOpen = true;
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);
      final confirmed = await showAppDialog(
        context: context,
        title: l10n.exitAppTitle,
        message: l10n.exitAppMessage,
        confirmLabel: l10n.exitAppConfirm,
        isDestructive: true,
      );

      if (confirmed && mounted) {
        await SystemNavigator.pop();
      }
    } finally {
      _exitPromptOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleSystemBack();
      },
      child: widget.child,
    );
  }
}
