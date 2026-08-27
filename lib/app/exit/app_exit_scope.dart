import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_dialog.dart';
import '../localization/app_localizations.dart';
import '../navigation/app_navigation_items.dart';
import '../presentation/providers/quick_actions_panel_provider.dart';
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

/// Confirms whether the user wants to discard unsaved changes.
Future<bool> confirmDiscardChanges(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppDialog(
    context: context,
    title: l10n.unsavedChangesTitle,
    message: l10n.unsavedChangesMessage,
    confirmLabel: l10n.leave,
    cancelLabel: l10n.cancel,
    isDestructive: true,
  );
}

/// Tries the navigator stack hierarchy from innermost to outermost and pops
/// the first navigator that can pop.  Returns `true` if a pop happened.
bool _tryPopNavigators(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  final path = router?.routerDelegate.currentConfiguration.uri.path;
  if (path == null) return false;

  final isBranchRoot = path == AppRoutes.dashboard ||
      path == AppRoutes.services ||
      path == AppRoutes.reports ||
      path == AppRoutes.settings;

  // 1. Branch navigator — only pop the branch that owns the current path.
  GlobalKey<NavigatorState>? activeBranch;
  if (path.startsWith(AppRoutes.dashboard)) {
    activeBranch = appDashboardBranchKey;
  } else if (path.startsWith(AppRoutes.services)) {
    activeBranch = appServicesBranchKey;
  } else if (path.startsWith(AppRoutes.reports)) {
    activeBranch = appReportsBranchKey;
  } else if (path.startsWith(AppRoutes.settings)) {
    activeBranch = appSettingsBranchKey;
  }

  if (activeBranch != null) {
    final nav = activeBranch.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return true;
    }
  }

  // 2. Shell navigator — only pop if we are NOT on a branch root tab.
  //    On branch roots the shell navigator holds module routes that should be
  //    cleaned up by GoRouter (go) rather than popped blindly.
  if (!isBranchRoot) {
    final shellNav = appShellNavigatorKey.currentState;
    if (shellNav != null && shellNav.canPop()) {
      shellNav.pop();
      return true;
    }
  }

  // 3. Root navigator.
  final rootNav = appRootNavigatorKey.currentState;
  if (rootNav != null && rootNav.canPop()) {
    rootNav.pop();
    return true;
  }

  // 4. GoRouter itself (walks the full tree).
  if (router != null && router.canPop()) {
    router.pop();
    return true;
  }

  return false;
}

/// Tracks visited shell tab locations to allow navigating back through tab history.
class ShellHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [AppRoutes.dashboard];

  void pushLocation(String path) {
    if (!isPrimaryShellLocation(path)) {
      return;
    }
    if (state.isNotEmpty && state.last == path) {
      return;
    }
    final filtered = state.where((p) => p != path).toList();
    state = [...filtered, path];
  }

  String? popLocation() {
    if (state.length <= 1) {
      return null;
    }
    final nextState = List<String>.from(state)..removeLast();
    state = nextState;
    return state.last;
  }
}

final shellHistoryProvider =
    NotifierProvider<ShellHistoryNotifier, List<String>>(
  ShellHistoryNotifier.new,
);

/// Handles a system-back attempt at the application shell root.
///
/// Walks the navigator stack hierarchy (branches → shell → root → GoRouter)
/// and pops the deepest possible navigator.  If nothing can pop:
/// - pops the previous top-level shell tab from history stack if available.
/// - on the Dashboard, shows the exit-confirmation dialog.
Future<void> handleRootSystemBack(BuildContext context, WidgetRef ref) async {
  if (_tryPopNavigators(context)) {
    return;
  }

  final router = GoRouter.maybeOf(context);
  if (router == null) {
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
///
/// Also intercepts back when the quick-actions panel is open, closing it
/// instead of navigating.
class AppExitPopScope extends ConsumerStatefulWidget {
  const AppExitPopScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppExitPopScope> createState() => _AppExitPopScopeState();
}

class _AppExitPopScopeState extends ConsumerState<AppExitPopScope> {
  bool _handling = false;

  Future<void> _onPop() async {
    if (_handling) {
      return;
    }

    // If the quick-actions panel is open, just close it.
    if (ref.read(quickActionsOpenProvider)) {
      ref.read(quickActionsOpenProvider.notifier).state = false;
      return;
    }

    _handling = true;
    try {
      await handleRootSystemBack(context, ref);
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

/// Wraps a form page to intercept back navigation when there are unsaved
/// changes.  Shows a discard-confirmation dialog before allowing the pop.
///
/// Usage:
/// ```dart
/// PopScope(
///   canPop: false,
///   onPopInvokedWithResult: (didPop, result) async {
///     if (didPop) return;
///     if (hasUnsavedChanges && !await confirmDiscardChanges(context)) return;
///     Navigator.of(context).pop();
///   },
///   child: ...,
/// )
/// ```
///
/// Or use [UnsavedChangesScope] for a self-contained widget.
class UnsavedChangesScope extends StatefulWidget {
  const UnsavedChangesScope({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
  });

  /// Returns `true` when the form contains modifications that have not been
  /// saved.  Called on every back-button / pop attempt.
  final ValueGetter<bool> hasUnsavedChanges;

  final Widget child;

  @override
  State<UnsavedChangesScope> createState() => _UnsavedChangesScopeState();
}

class _UnsavedChangesScopeState extends State<UnsavedChangesScope> {
  bool _handling = false;

  Future<void> _onPop() async {
    if (_handling) {
      return;
    }
    if (!widget.hasUnsavedChanges()) {
      Navigator.of(context).pop();
      return;
    }
    _handling = true;
    try {
      final confirmed = await confirmDiscardChanges(context);
      if (confirmed && context.mounted) {
        Navigator.of(context).pop();
      }
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
