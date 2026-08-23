import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../connectivity/connectivity_service.dart';
import '../database/encrypted_hive_box.dart';
import '../database/hive_boxes.dart';
import '../database/tenant_database_name.dart';
import '../network/http_client_providers.dart';
import '../network/http_remote_sync_api.dart';
import '../network/remote_sync_api.dart';
import '../network/sync_api_config.dart';
import '../tenancy/session_company.dart';
import 'sync_cursor_store.dart';
import 'sync_manager.dart';
import 'sync_metrics_store.dart';
import 'sync_operation.dart';
import 'sync_os_background_bridge.dart';
import 'sync_overview.dart';
import 'sync_queue.dart';

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
  final queue = SyncQueue(
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
  );
  ref.onDispose(manager.dispose);
  return manager;
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
