import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/notifications/notification_type.dart';
import '../core/widgets/app_snackbar.dart';
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
  @override
  void initState() {
    super.initState();
    registerAppSnackBarHandler(_bridgeSnackBar);
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
        return NotificationToastHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
