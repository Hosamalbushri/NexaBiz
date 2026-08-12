import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/database/hive_boxes.dart';
import '../../core/database/hive_initializer.dart';
import '../../core/di/app_providers.dart';
import '../../core/sync/sync_providers.dart';
import '../../modules/inventory/data/sync/inventory_sync_bootstrap.dart';
import '../notifications/data/notification_hive.dart';
import '../settings/settings_repository.dart';

/// Application-level bootstrap: core services + sync wiring.
///
/// Splash coordinates this flow; module-specific setup stays in each module.
class AppBootstrap {
  const AppBootstrap._();

  /// Runs required platform initialization once per process (idempotent boxes).
  static Future<void> initialize(Ref ref) async {
    await HiveInitializer.initialize();
    await NotificationHive.openBox();
    await openSyncQueueBox();

    final settingsRepository = SettingsRepository();
    final themeMode = await settingsRepository.loadThemeMode();
    final locale = await settingsRepository.loadLocale();

    ref.read(themeModeProvider.notifier).state = themeMode;
    ref.read(localeProvider.notifier).state = locale;

    registerInventorySyncHandlers(ref);
    await ref.read(syncManagerProvider).start();
  }

  /// Whether the platform settings box is open (bootstrap completed storage step).
  static bool get isStorageReady => Hive.isBoxOpen(HiveBoxes.settings);
}
