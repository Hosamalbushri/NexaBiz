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
int _backEventSeq = 0;

/// Tracks visited shell tab locations to allow navigating back through tab history.
class ShellHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [AppRoutes.dashboard];

  void pushLocation(String path) {
    if (!isRootDestination(path)) {
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

  void reset() {
    state = [AppRoutes.dashboard];
  }
}

final shellHistoryProvider =
    NotifierProvider<ShellHistoryNotifier, List<String>>(
      ShellHistoryNotifier.new,
    );

/// Resolves the immediate logical parent route for any given path in the app.
String getLogicalParentRoute(String path) {
  if (path == AppRoutes.dashboard) {
    return AppRoutes.dashboard; // App exit boundary
  }

  // 1. Module roots & primary shell tab roots -> return Dashboard
  if (path == AppRoutes.services ||
      path == AppRoutes.reports ||
      path == AppRoutes.settings ||
      path == AppRoutes.notifications ||
      path == '/inventory' ||
      path == '/sales' ||
      path == '/customers' ||
      path == '/accounting' ||
      path == '/receipts-payments' ||
      path == '/administration') {
    return AppRoutes.dashboard;
  }

  // 2. Settings sub-routes -> return /settings
  if (path.startsWith('${AppRoutes.settings}/')) {
    return AppRoutes.settings;
  }

  // 3. Reports sub-routes -> return /reports or parent
  if (path.startsWith('${AppRoutes.reports}/') ||
      path.startsWith('/module-reports')) {
    if (path == AppRoutes.reportsModules || path == '/module-reports') {
      return AppRoutes.reports;
    }
    if (path.startsWith('/module-reports/')) {
      return AppRoutes.reports;
    }
    return AppRoutes.reportsModules;
  }

  // 4. Administration sub-routes -> return /administration
  if (path.startsWith('/administration/')) {
    return '/administration';
  }

  // 5. Inventory sub-routes
  if (path.startsWith('/inventory/')) {
    if (path.startsWith('/inventory/products/')) {
      return '/inventory/products';
    }
    if (path == '/inventory/products') return '/inventory';
    if (path.startsWith('/inventory/stock-count/count/')) {
      return '/inventory/stock-count/count';
    }
    if (path.startsWith('/inventory/stock-count/')) {
      return '/inventory/stock-count';
    }
    if (path == '/inventory/stock-count') return '/inventory';
    if (path.startsWith('/inventory/stock-movements/receipts/')) {
      return '/inventory/stock-movements/receipts';
    }
    if (path.startsWith('/inventory/stock-movements/issues/')) {
      return '/inventory/stock-movements/issues';
    }
    if (path.startsWith('/inventory/stock-movements/')) {
      return '/inventory/stock-movements';
    }
    if (path == '/inventory/stock-movements') return '/inventory';
    if (path.startsWith('/inventory/stock-transfers/')) {
      return '/inventory/stock-transfers';
    }
    if (path == '/inventory/stock-transfers') return '/inventory';
    return '/inventory';
  }

  // 6. Sales sub-routes
  if (path.startsWith('/sales/')) {
    if (path == '/sales/create' ||
        path == '/sales/list' ||
        path == '/sales/invoice-preview') {
      return '/sales';
    }
    return '/sales';
  }

  // 7. Customers sub-routes
  if (path.startsWith('/customers/')) {
    return '/customers';
  }

  // 8. Accounting sub-routes
  if (path.startsWith('/accounting/')) {
    if (path.startsWith('/accounting/accounts/')) {
      return '/accounting/accounts';
    }
    if (path.startsWith('/accounting/journals/')) {
      return '/accounting/journals';
    }
    if (path.startsWith('/accounting/voucher-books/')) {
      return '/accounting/voucher-books';
    }
    if (path.startsWith('/accounting/fiscal-years/')) {
      return '/accounting/fiscal-years';
    }
    return '/accounting';
  }

  // 9. Receipts & Payments sub-routes
  if (path.startsWith('/receipts-payments/')) {
    if (path.startsWith('/receipts-payments/receipts/')) {
      return '/receipts-payments/receipts';
    }
    if (path.startsWith('/receipts-payments/payments/')) {
      return '/receipts-payments/payments';
    }
    return '/receipts-payments';
  }

  // Fallback -> Dashboard
  return AppRoutes.dashboard;
}

/// Handles a system-back attempt at the application shell root.
///
/// Walks the navigator stack hierarchy (branches → shell → root → GoRouter)
/// and pops the deepest possible navigator. If nothing can pop:
/// - if on any root destination other than Dashboard, returns to Dashboard.
/// - if on the Dashboard, shows the exit-confirmation dialog and exits on confirm.
Future<void> handleRootSystemBack(
  BuildContext context,
  dynamic ref, [
  int? eventId,
]) async {
  final id = eventId ?? ++_backEventSeq;
  debugPrint('[NAV-BACK][event=$id] === handleRootSystemBack ENTER ===');

  if (!context.mounted) {
    return;
  }

  final router = GoRouter.maybeOf(context);
  if (router == null) {
    debugPrint('[NAV-BACK][event=$id] handleRootSystemBack: GoRouter is NULL');
    return;
  }

  // 1. Try popping nested navigators first (shell navigator or root navigator)
  final shellNav = appShellNavigatorKey.currentState;
  if (shellNav != null && shellNav.mounted && shellNav.canPop()) {
    debugPrint('[NAV-BACK][event=$id] handleRootSystemBack: popping appShellNavigatorKey');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shellNav.mounted && shellNav.canPop()) {
        shellNav.pop();
      }
    });
    return;
  }

  final rootNav = appRootNavigatorKey.currentState;
  if (rootNav != null && rootNav.mounted && rootNav.canPop()) {
    debugPrint('[NAV-BACK][event=$id] handleRootSystemBack: popping appRootNavigatorKey');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootNav.mounted && rootNav.canPop()) {
        rootNav.pop();
      }
    });
    return;
  }

  final path = router.routerDelegate.currentConfiguration.uri.path;
  debugPrint('[NAV-BACK][event=$id] handleRootSystemBack: current path=$path');

  if (path == AppRoutes.splash) {
    debugPrint(
      '[NAV-BACK][event=$id] handleRootSystemBack: Splash page, ignoring back',
    );
    return;
  }

  if (path == AppRoutes.dashboard) {
    debugPrint(
      '[NAV-BACK][event=$id] handleRootSystemBack: Dashboard root reached, exiting app directly',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemNavigator.pop();
    });
    return;
  }

  final parentRoute = getLogicalParentRoute(path);
  debugPrint(
    '[NAV-BACK][event=$id] handleRootSystemBack: Navigating to logical parent: $parentRoute',
  );
  if (context.mounted) {
    router.go(parentRoute);
  }
}

/// [AppExitPopScope] on the main shell so Android back is handled without activity finish.
class AppExitPopScope extends ConsumerStatefulWidget {
  const AppExitPopScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppExitPopScope> createState() => _AppExitPopScopeState();
}

class _AppExitPopScopeState extends ConsumerState<AppExitPopScope>
    with WidgetsBindingObserver {
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPop(int eventId) {
    if (_handling) {
      return;
    }
    _handling = true;

    if (ref.read(quickActionsOpenProvider)) {
      ref.read(quickActionsOpenProvider.notifier).state = false;
      _resetHandling();
      return;
    }

    handleRootSystemBack(context, ref, eventId).whenComplete(() {
      _resetHandling();
    });
  }

  void _resetHandling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handling = false;
      }
    });
  }

  @override
  Future<bool> didPopRoute() async {
    final eventId = ++_backEventSeq;
    if (_handling) {
      return true; // Reentrancy guard
    }

    _onPop(eventId);
    return true; // CONSUMED! Explicitly return true to Flutter Engine & Android OS!
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        final eventId = ++_backEventSeq;
        if (didPop) {
          return;
        }
        _onPop(eventId);
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
      if (confirmed && mounted && context.mounted) {
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
