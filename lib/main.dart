import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/bootstrap/module_bootstrap.dart';
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

    final container = ProviderContainer(
      overrides: [
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
