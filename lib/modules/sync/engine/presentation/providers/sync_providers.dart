import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/database/encrypted_hive_box.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/network/http_client_providers.dart';
import 'package:stock_count/core/network/http_remote_sync_api.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import 'package:stock_count/modules/sync/engine/data/stores/sync_cursor_store.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_manager.dart';
import 'package:stock_count/modules/sync/engine/data/stores/sync_metrics_store.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/data/stores/sync_os_background_bridge.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_overview.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_context_providers.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';
import 'package:stock_count/core/time/domain/trusted_clock.dart';
import 'package:stock_count/modules/sync/engine/data/repositories/sync_repository_impl.dart';
import 'package:stock_count/modules/sync/engine/domain/repositories/sync_repository.dart';
import 'package:stock_count/modules/sync/engine/domain/usecases/execute_sync_usecase.dart';


final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService(
    internetProbe: () {
      final url = ref.read(syncApiConfigProvider).baseUrl.trim();
      final host = Uri.tryParse(url)?.host ?? '';
      return dnsInternetProbe(host.isNotEmpty ? host : 'one.one.one.one');
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

final syncQueueProvider = Provider<SyncQueue>((ref) {
  final companyId = ref.watch(sessionCompanyIdProvider);
  final config = ref.watch(syncApiConfigProvider);
  final queue = SyncQueue(
    companyId: companyId,
    deviceId: config.deviceId,
    encryptedBoxName: tenantScopedName(HiveBoxes.syncQueueEncrypted, companyId),
    legacyPlainBoxName: tenantScopedName(HiveBoxes.syncQueue, companyId),
  );
  ref.onDispose(queue.dispose);
  return queue;
});

final syncCursorStoreProvider = Provider<SyncCursorStore>((ref) {
  final companyId = ref.watch(sessionCompanyIdProvider);
  return SyncCursorStore(
    boxName: tenantScopedName(HiveBoxes.syncCursors, companyId),
  );
});

final syncMetricsStoreProvider = Provider<SyncMetricsStore>((ref) {
  final companyId = ref.watch(sessionCompanyIdProvider);
  return SyncMetricsStore(
    boxName: tenantScopedName(HiveBoxes.syncMetrics, companyId),
  );
});

/// OS background wake scheduler (no-op; in-app auto-sync covers foreground).
final syncOsBackgroundBridgeProvider = Provider<SyncOsBackgroundBridge>((ref) {
  return const NoOpSyncOsBackgroundBridge();
});

/// Experimental sync API config (fail-closed: sync off until configured).
///
/// [AppBootstrap] overwrites [deviceId] with a per-install UUID from Hive and
/// may apply a saved server URL/token from settings.
final syncApiConfigProvider = StateProvider<SyncApiConfig>((ref) {
  return SyncApiConfig.fromEnvironment();
});

/// Remote sync API. Uses HTTP only when the endpoint is usable (URL + token +
/// HTTPS, or plain HTTP when [SyncApiConfig.allowInsecureHttp] is true).
///
/// Important: do **not** key this off [SyncApiConfig.enabled]. That flag is
/// flipped when the user opts into sync; watching it would recreate
/// [SyncManager] / [SyncEnabledController] and reset the enable toggle.
final remoteSyncApiProvider = Provider<RemoteSyncApi>((ref) {
  final config = ref.watch(syncApiConfigProvider);
  final authClient = ref.watch(syncAuthenticatedHttpClientProvider);

  // After login the config token is cleared (JWT lives in SecureStorage),
  // so accept either a config token or an injected auth client as credential.
  final url = config.baseUrl.trim();
  final hasUrl = url.isNotEmpty &&
      (url.startsWith('https://') || url.startsWith('http://'));
  final hasAuth =
      config.apiToken.trim().isNotEmpty || authClient != null;

  if (!hasUrl || !hasAuth) {
    return InMemoryRemoteSyncApi();
  }

  final api = HttpRemoteSyncApi(
    config: config,
    authenticatedClient: authClient,
    cursorStore: ref.watch(syncCursorStoreProvider),
    clock: ref.watch(trustedClockProvider),
  );
  ref.onDispose(api.dispose);
  return api;
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    queue: ref.watch(syncQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    remoteProvider: () => ref.read(remoteSyncApiProvider),
    metricsStore: ref.watch(syncMetricsStoreProvider),
    hasSyncCapability: () {
      final service = ref.read(entitlementServiceProvider);
      return service.hasCapability(EntitlementCapability.sync);
    },
    // G5 fix: also require sync.execute permission on the user's session.
    // Fail closed: if authState has no session, sync is denied.
    hasSyncPermission: () {
      final context = ref.read(authorizationContextProvider);
      if (context.userId.isEmpty) return false;
      return context.permissions.contains('sync.execute') ||
          context.permissions.contains('sync.view');
    },
    readCompanyId: () => ref.read(sessionCompanyIdProvider) ?? '',
    readClockState: () {
      final service = ref.read(clockIntegrityServiceProvider);
      return service.checkIntegrity();
    },
    isTimeTrusted: () {
      final context = ref.read(authorizationContextProvider);
      return context.isTimeTrusted;
    },
    requiresReverification: () {
      final context = ref.read(authorizationContextProvider);
      return context.requiresReverification;
    },
    isOfflineGraceActive: () {
      final context = ref.read(authorizationContextProvider);
      return context.isOfflineGraceActive;
    },
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    syncManager: ref.watch(syncManagerProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

final executeSyncUseCaseProvider = Provider<ExecuteSyncUseCase>((ref) {
  return ExecuteSyncUseCase(ref.watch(syncRepositoryProvider));
});

final syncOverviewProvider = StreamProvider<SyncOverview>((ref) {

  return ref.watch(syncManagerProvider).overviewStream;
});

final latestSyncPassMetricsProvider = StreamProvider<SyncPassMetrics?>((
  ref,
) async* {
  final store = ref.watch(syncMetricsStoreProvider);
  yield await store.latest();
  await for (final _ in ref.watch(syncManagerProvider).meaningfulPasses) {
    yield await store.latest();
  }
});

/// Opens the durable (AES-encrypted) sync queue box during app bootstrap.
Future<void> openSyncQueueBox() async {
  await SyncQueue.registerAdapter();
  if (!Hive.isBoxOpen(HiveBoxes.syncQueueEncrypted)) {
    await EncryptedHive.openMigrated<SyncOperation>(
      encryptedBoxName: HiveBoxes.syncQueueEncrypted,
      legacyPlainBoxName: HiveBoxes.syncQueue,
    );
  }
}
