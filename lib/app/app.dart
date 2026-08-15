import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/notifications/notification_type.dart';
import '../core/sync/sync_overview.dart';
import '../core/sync/sync_providers.dart';
import '../core/widgets/app_snackbar.dart';
import '../core/widgets/loading_overlay.dart';
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

  @override
  void initState() {
    super.initState();
    registerAppSnackBarHandler(_bridgeSnackBar);
    _syncPassSub = ref
        .read(syncManagerProvider)
        .meaningfulPasses
        .listen(_onMeaningfulSyncPass);
  }

  @override
  void dispose() {
    unawaited(_syncPassSub?.cancel());
    super.dispose();
  }

  void _onMeaningfulSyncPass(SyncPassResult result) {
    final locale =
        ref.read(localeProvider) ?? AppLocalizations.supportedLocales.first;
    final l10n = lookupAppLocalizations(locale);
    final notifications = ref.read(notificationServiceProvider);

    switch (result.outcome) {
      case SyncPassOutcome.completed:
        unawaited(
          notifications.showSuccess(
            title: l10n.syncCompletedTitle,
            message: l10n.syncCompletedMessage,
            category: NotificationCategory.sync,
          ),
        );
      case SyncPassOutcome.partialFailure:
        unawaited(
          notifications.showWarning(
            title: l10n.syncPartialTitle,
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
      case SyncPassOutcome.idle:
      case SyncPassOutcome.skippedOffline:
        break;
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
    // Read once: provider must not watch mutable deps (see app_router.dart).
    // Caching here while the provider disposes on invalidate left a live
    // MaterialApp on a disposed GoRouter and invited duplicate navigator keys.
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
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
          child: NotificationToastHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
