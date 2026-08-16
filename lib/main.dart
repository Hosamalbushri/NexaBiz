import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap/module_bootstrap.dart';
import 'modules/authentication/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
