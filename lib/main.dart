import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap/module_bootstrap.dart';
import 'app/settings/settings_repository.dart';
import 'core/database/hive_initializer.dart';
import 'core/di/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.initialize();

  final container = ProviderContainer(
    overrides: [
      ...moduleRegistryOverrides(),
    ],
  );

  final settingsRepository = SettingsRepository();
  final themeMode = await settingsRepository.loadThemeMode();
  final locale = await settingsRepository.loadLocale();
  container.read(themeModeProvider.notifier).state = themeMode;
  container.read(localeProvider.notifier).state = locale;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BusinessPlatformApp(),
    ),
  );
}
