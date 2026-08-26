import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/app_providers.dart';
import '../core/entitlements/domain/entities/entitlement.dart';
import '../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../core/notifications/notification_type.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../core/widgets/app_snackbar.dart';
import '../core/widgets/app_update_gate.dart';
import '../core/widgets/loading_overlay.dart';
import '../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../core/auth/presentation/providers/auth_state_core.dart';
import 'localization/app_localizations.dart';
import 'notifications/presentation/providers/notifications_provider.dart';
import 'notifications/presentation/widgets/notification_toast_host.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root application widget for the modular business platform.
class BusinessPlatformApp extends ConsumerStatefulWidget {
  const BusinessPlatformApp({super.key});

  @override
  ConsumerState<BusinessPlatformApp> createState() =>
      _BusinessPlatformAppState();
}

class _BusinessPlatformAppState extends ConsumerState<BusinessPlatformApp> {
  StreamSubscription<SyncPassResult>? _syncPassSub;
  AppLifecycleListener? _lifecycleListener;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    registerAppSnackBarHandler(_bridgeSnackBar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPassSub = ref
          .read(syncManagerProvider)
          .meaningfulPasses
          .listen(_onMeaningfulSyncPass);
    });
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref.read(appLockControllerProvider.notifier).onAppPaused();
      },
      onHide: () {
        ref.read(appLockControllerProvider.notifier).onAppPaused();
      },
      onResume: () {
        ref.read(appLockControllerProvider.notifier).onAppResumed();
        final entitlement = ref.read(entitlementServiceProvider);
        final auth = ref.read(authStateProvider);
        if (entitlement.hasCapability(EntitlementCapability.sync) && auth.canUseRemoteSync) {
          final syncManager = ref.read(syncManagerProvider);
          if (syncManager.isEnabled && !syncManager.overview.isSyncing) {
            unawaited(
              syncManager.syncNow(
                trigger: SyncPassTrigger.auto,
                notify: false,
              ),
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    unawaited(_syncPassSub?.cancel());
    super.dispose();
  }

  void _onMeaningfulSyncPass(SyncPassResult result) {
    if (!result.shouldNotify) {
      return;
    }
    final entitlement = ref.read(entitlementServiceProvider);
    if (!entitlement.hasCapability(EntitlementCapability.sync)) {
      return;
    }
    final locale =
        ref.read(localeProvider) ?? AppLocalizations.supportedLocales.first;
    final l10n = lookupAppLocalizations(locale);
    final notifications = ref.read(notificationServiceProvider);

    switch (result.outcome) {
      case SyncPassOutcome.completed:
        unawaited(
          notifications.showSuccess(
            title: l10n.syncCompletedTitle,
            message: result.hasIncomingFromServer
                ? l10n.syncIncomingCount(result.downloaded)
                : l10n.syncCompletedMessage,
            category: NotificationCategory.sync,
          ),
        );
      case SyncPassOutcome.partialFailure:
        unawaited(
          notifications.showWarning(
            title: l10n.syncPartialTitle,
            message: result.hasIncomingFromServer
                ? l10n.syncIncomingCount(result.downloaded)
                : null,
            category: NotificationCategory.sync,
          ),
        );
      case SyncPassOutcome.failed:
        unawaited(
          notifications.showError(
            title: l10n.syncFailedTitle,
            message: l10n.syncFailedMessage,
            category: NotificationCategory.sync,
          ),
        );
      case SyncPassOutcome.authRequired:
        unawaited(
          notifications.showWarning(
            title: l10n.syncSessionExpired,
            message: l10n.syncSessionExpired,
            category: NotificationCategory.sync,
          ),
        );
      case SyncPassOutcome.idle:
      case SyncPassOutcome.skippedOffline:
      case SyncPassOutcome.skippedDisabled:
        break;
      case SyncPassOutcome.temporalAuthorizationFailed:
      case SyncPassOutcome.clockTampered:
      case SyncPassOutcome.reverificationRequired:
        unawaited(
          notifications.showWarning(
            title: 'Synchronization Paused',
            message: 'Temporal authorization check failed. Verify device clock.',
            category: NotificationCategory.sync,
          ),
        );
    }
  }

  void _bridgeSnackBar(
    BuildContext context, {
    required String message,
    required bool isSuccess,
    Duration? duration,
    bool persistToHistory = false,
  }) {
    final localization = AppLocalizations.of(context);
    ref
        .read(notificationServiceProvider)
        .show(
          type: isSuccess ? NotificationType.success : NotificationType.error,
          title: isSuccess ? localization.success : localization.failure,
          message: message,
          duration: duration,
          persistToHistory: persistToHistory,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Pin one GoRouter instance for the widget lifetime. Watching the provider
    // can recreate GoRouter and reuse the same navigator GlobalKeys → crash.
    _router ??= ref.read(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: _router!,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return LoadingOverlayHost(
          child: NotificationToastHost(
            child: AppUpdateGate(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
