import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap/module_bootstrap.dart';
import 'core/logging/app_error_log.dart';
import 'modules/authentication/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installAppErrorLogging();

  await runZonedGuarded(() async {
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
  }, (error, stack) {
    unawaited(AppErrorLog.record(error, stack, source: 'zone'));
  });
}
