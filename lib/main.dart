import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap/module_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(
    overrides: [...moduleRegistryOverrides()],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BusinessPlatformApp(),
    ),
  );
}
