import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/bootstrap/module_bootstrap.dart';
import 'app/settings/settings_repository.dart';
import 'core/database/hive_boxes.dart';
import 'core/di/app_providers.dart';
import 'core/logging/app_error_log.dart';
import 'core/logging/crash_reporting.dart';
import 'core/logging/crash_reporting_config.dart';
import 'core/network/trusted_root_certificates.dart';
import 'modules/authentication/presentation/providers/auth_providers.dart';

Future<void> main() async {
  final crashConfig = CrashReportingConfig.fromEnvironment();
  CrashReporting.configure(crashConfig);

  // Binding.ensureInitialized and runApp must share one zone. Calling
  // ensureInitialized in main() then runApp inside runZonedGuarded throws
  // Flutter's "Zone mismatch" assertion.
  Future<void> startApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await TrustedRootCertificates.install();
    installAppErrorLogging();

    // Pre-load Hive and read theme/locale so the first frame renders with
    // the correct visual configuration (eliminates theme/locale flash).
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.openBox<dynamic>(HiveBoxes.settings);
    }
    final settings = SettingsRepository();
    final themeMode = await settings.loadThemeMode();
    final locale = await settings.loadLocale();
    final isFirstLaunch = !(await settings.appearsPreviouslyConfigured());

    final startupState = AppStartupState(
      themeMode: themeMode,
      locale: locale,
      isFirstLaunch: isFirstLaunch,
    );

    final container = ProviderContainer(
      overrides: [
        startupStateProvider.overrideWithValue(startupState),
        themeModeProvider.overrideWith((_) => startupState.themeMode),
        localeProvider.overrideWith((_) => startupState.locale),
        ...moduleRegistryOverrides(),
        ...authenticationOverrides(),
      ],
    );

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const BusinessPlatformApp(),
      ),
    );
  }

  if (crashConfig.isEnabled) {
    await SentryFlutter.init(crashConfig.applyTo, appRunner: startApp);
  } else {
    await runZonedGuarded(startApp, (error, stack) {
      unawaited(AppErrorLog.record(error, stack, source: 'zone'));
    });
  }
}
