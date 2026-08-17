import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/database/hive_boxes.dart';
import '../../core/database/hive_initializer.dart';
import '../../core/di/app_providers.dart';
import '../../core/network/sync_api_config.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_cursor_store.dart';
import '../../core/sync/sync_metrics_store.dart';
import '../../core/sync/sync_os_wake_signal.dart';
import '../../modules/accounting/data/sync/accounting_sync_bootstrap.dart';
import '../../modules/accounting/presentation/providers/account_providers.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../modules/customers/data/sync/customers_sync_bootstrap.dart';
import '../../modules/customers/presentation/providers/customer_providers.dart';
import '../../modules/inventory/data/sync/inventory_sync_bootstrap.dart';
import '../../modules/receipts_payments/data/sync/receipts_payments_sync_bootstrap.dart';
import '../../modules/sales/data/sync/sales_sync_bootstrap.dart';
import '../customers/customer_remote_account_ensure.dart';
import '../notifications/data/notification_hive.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../settings/settings_repository.dart';
import '../sync/sync_background_scheduler.dart';
import '../sync/sync_enabled_provider.dart';

/// Application-level bootstrap: core services + optional sync wiring.
///
/// Splash coordinates this flow; module-specific setup stays in each module.
class AppBootstrap {
  const AppBootstrap._();

  /// Runs required platform initialization once per process (idempotent boxes).
  static Future<void> initialize(Ref ref) async {
    await HiveInitializer.initialize();
    await NotificationHive.openBox();
    await openSyncQueueBox();
    await openSyncCursorBox();
    await openSyncMetricsBox();
    await openSyncOsWakeBox();

    final settingsRepository = SettingsRepository();
    final themeMode = await settingsRepository.loadThemeMode();
    final locale = await settingsRepository.loadLocale();
    final deviceId = await settingsRepository.loadOrCreateSyncDeviceId();
    final syncEnabled = await settingsRepository.loadSyncEnabled();
    final syncServerUrl = await settingsRepository.loadSyncServerBaseUrl();
    final syncServerToken = await settingsRepository.loadSyncServerToken();

    ref.read(themeModeProvider.notifier).state = themeMode;
    ref.read(localeProvider.notifier).state = locale;

    final envConfig = ref.read(syncApiConfigProvider);
    final resolvedUrl = (syncServerUrl ?? envConfig.baseUrl).trim();
    final resolvedToken = (syncServerToken ?? envConfig.apiToken).trim();
    final endpointUsable = SyncApiConfig.isHttpEndpointUsable(
      baseUrl: resolvedUrl,
      apiToken: resolvedToken,
      allowInsecureHttp: envConfig.allowInsecureHttp,
    );
    ref.read(syncApiConfigProvider.notifier).state = envConfig.copyWith(
      deviceId: deviceId,
      baseUrl: resolvedUrl,
      apiToken: resolvedToken,
      enabled: syncEnabled && endpointUsable,
    );

    await ref.read(localAuthStoreProvider).ensureSeeded();
    await ref.read(authStateProvider.notifier).bootstrap(
          preferRemote: syncEnabled,
        );
    await ref.read(appLockControllerProvider.notifier).hydrate();

    registerInventorySyncHandlers(ref);
    registerAccountingSyncHandlers(ref);
    final customerAccountEnsure = CustomerRemoteAccountEnsure(
      accounts: ref.read(accountRepositoryImplProvider),
      accountLink: ref.read(customerAccountLinkPortProvider),
      settings: ref.read(settingsRepositoryProvider),
    );
    registerCustomersSyncHandlers(
      ref,
      ensureLinkedAccount: customerAccountEnsure.ensureFromCustomerPayload,
    );
    registerSalesSyncHandlers(ref);
    registerReceiptsPaymentsSyncHandlers(ref);
    // Hydrate sync preference (kept even if remote session needs renewal).
    await ref.read(syncEnabledProvider.notifier).hydrate(syncEnabled);
    final syncActuallyEnabled = ref.read(syncEnabledProvider) &&
        ref.read(authStateProvider).canUseRemoteSync;
    await ref.read(syncManagerProvider).start(enabled: syncActuallyEnabled);
    await ref.read(syncAutoPreferencesProvider.notifier).hydrate();
    // Keep the provider alive and start background / auto passes.
    ref.read(syncBackgroundSchedulerProvider).start();
  }

  /// Whether the platform settings box is open (bootstrap completed storage step).
  static bool get isStorageReady => Hive.isBoxOpen(HiveBoxes.settings);
}
