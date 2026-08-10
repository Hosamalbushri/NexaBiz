import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_dialog.dart';
import '../localization/app_localizations.dart';
import '../router/app_navigator_keys.dart';
import '../router/app_routes.dart';

/// Confirms whether the user wants to close the application.
Future<bool> confirmAppExit(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppDialog(
    context: context,
    title: l10n.exitAppTitle,
    message: l10n.exitAppMessage,
    confirmLabel: l10n.exitAppConfirm,
    cancelLabel: l10n.cancel,
    isDestructive: true,
  );
}

/// Handles a system-back attempt at the application shell root.
///
/// Exit confirmation runs only on the Dashboard branch when nothing can pop.
Future<void> handleRootSystemBack(BuildContext context) async {
  final rootNavigator = appRootNavigatorKey.currentState;
  if (rootNavigator != null && rootNavigator.canPop()) {
    rootNavigator.pop();
    return;
  }

  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return;
  }

  if (router.canPop()) {
    router.pop();
    return;
  }

  final path = router.routerDelegate.currentConfiguration.uri.path;
  if (path == AppRoutes.splash) {
    return;
  }

  if (path != AppRoutes.dashboard) {
    router.go(AppRoutes.dashboard);
    return;
  }

  final dialogContext = appRootNavigatorKey.currentContext ?? context;
  if (!dialogContext.mounted) {
    return;
  }

  final confirmed = await confirmAppExit(dialogContext);
  if (confirmed) {
    await SystemNavigator.pop();
  }
}

/// [PopScope] on the main shell so Android back is handled (not activity finish).
class AppExitPopScope extends StatefulWidget {
  const AppExitPopScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppExitPopScope> createState() => _AppExitPopScopeState();
}

class _AppExitPopScopeState extends State<AppExitPopScope> {
  bool _handling = false;

  Future<void> _onPop() async {
    if (_handling) {
      return;
    }
    _handling = true;
    try {
      await handleRootSystemBack(context);
    } finally {
      if (mounted) {
        _handling = false;
      }
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
        _onPop();
      },
      child: widget.child,
    );
  }
}
