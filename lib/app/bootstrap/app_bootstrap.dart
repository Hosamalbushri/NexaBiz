import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/database/hive_boxes.dart';
import '../../core/database/hive_initializer.dart';
import '../../core/di/app_providers.dart';
import '../../core/entitlements/domain/entities/entitlement.dart';
import '../../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../../core/logging/app_error_log.dart';
import '../../core/network/sync_api_config.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_cursor_store.dart';
import '../../core/sync/sync_metrics_store.dart';
import '../../core/sync/sync_os_wake_signal.dart';
import '../../core/tenancy/tenant_context.dart';
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
import '../settings/company/company_profile_sync_bootstrap.dart';
import '../settings/settings_repository.dart';
import '../sync/sync_background_scheduler.dart';
import '../sync/sync_enabled_provider.dart';

/// Application-level bootstrap divided into independent, resilient stages.
class AppBootstrap {
  const AppBootstrap._();

  /// Stage B: Local Storage Initialization
  static Future<void> bootstrapStorage() async {
    await HiveInitializer.initialize();
    await NotificationHive.openBox();
  }

  /// Stage C: Local Database & Sync Boxes Initialization
  static Future<void> bootstrapDatabase() async {
    await openSyncQueueBox();
    await openSyncCursorBox();
    await openSyncMetricsBox();
    await openSyncOsWakeBox();
  }

  /// Stage D: Configuration Initialization
  static Future<void> bootstrapConfig(Ref ref) async {
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
  }

  /// Stage E: Local Auth Hydration (Non-blocking for remote network failures)
  static Future<void> bootstrapAuth(Ref ref) async {
    await ref.read(localAuthStoreProvider).ensureSeeded();
    final syncEnabled = await SettingsRepository().loadSyncEnabled();
    try {
      await ref.read(authStateProvider.notifier).bootstrap(
            preferRemote: syncEnabled,
          );
    } catch (e, stack) {
      AppErrorLog.record(e, stack, source: 'bootstrapAuth');
      // Falling back to unauthenticated / local mode instead of throwing fatal init exception
    }
    try {
      await ref.read(appLockControllerProvider.notifier).hydrate();
    } catch (e, stack) {
      AppErrorLog.record(e, stack, source: 'hydrateAppLock');
    }
  }

  /// Stage F: Synchronization Wiring & Scheduler
  static Future<void> bootstrapSync(dynamic ref) async {
    registerCompanyProfileSyncHandlers(ref);
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

    final currentCompanyId = ref.read(currentCompanyIdProvider);
    final cloudState = await SettingsRepository().loadCompanyCloudState(currentCompanyId);

    final syncEnabled = await SettingsRepository().loadSyncEnabled();
    await ref.read(syncEnabledProvider.notifier).hydrate(syncEnabled);
    final entitlementService = ref.read(entitlementServiceProvider);
    final hasSyncCapability = entitlementService.hasCapability(EntitlementCapability.sync);
    final authState = ref.read(authStateProvider);
    final syncActuallyEnabled = ref.read(syncEnabledProvider) &&
        authState.canUseRemoteSync &&
        hasSyncCapability &&
        cloudState.isCloudReady;

    if (!syncActuallyEnabled) {
      await ref.read(syncManagerProvider).start(enabled: false);
      ref.read(syncBackgroundSchedulerProvider).stop();
    } else {
      await ref.read(syncManagerProvider).start(enabled: true);
      await ref.read(syncAutoPreferencesProvider.notifier).hydrate();
      ref.read(syncBackgroundSchedulerProvider).start();
    }
  }

  /// Explicitly stops synchronization (e.g. during logout or switching to a Free company).
  static Future<void> stopSync(dynamic ref) async {
    try {
      final syncManager = ref.read(syncManagerProvider);
      await syncManager.start(enabled: false);
      ref.read(syncBackgroundSchedulerProvider).stop();
    } catch (_) {}
  }

  /// Master runner for backwards-compatibility callers.
  static Future<void> initialize(Ref ref) async {
    await bootstrapStorage();
    await bootstrapDatabase();
    await bootstrapConfig(ref);
    await bootstrapAuth(ref);
    await bootstrapSync(ref);
  }

  /// Whether the platform settings box is open (bootstrap completed storage step).
  static bool get isStorageReady => Hive.isBoxOpen(HiveBoxes.settings);
}

