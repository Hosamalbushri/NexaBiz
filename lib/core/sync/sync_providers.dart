import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../connectivity/connectivity_service.dart';
import '../database/encrypted_hive_box.dart';
import '../database/hive_boxes.dart';
import '../network/http_client_providers.dart';
import '../network/http_remote_sync_api.dart';
import '../network/remote_sync_api.dart';
import '../network/sync_api_config.dart';
import 'sync_cursor_store.dart';
import 'sync_manager.dart';
import 'sync_metrics_store.dart';
import 'sync_operation.dart';
import 'sync_os_background_bridge.dart';
import 'sync_overview.dart';
import 'sync_queue.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final syncQueueProvider = Provider<SyncQueue>((ref) {
  final queue = SyncQueue();
  ref.onDispose(queue.dispose);
  return queue;
});

final syncCursorStoreProvider = Provider<SyncCursorStore>((ref) {
  return SyncCursorStore();
});

final syncMetricsStoreProvider = Provider<SyncMetricsStore>((ref) {
  return SyncMetricsStore();
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
  if (!config.hasUsableHttpEndpoint) {
    return InMemoryRemoteSyncApi();
  }

  final api = HttpRemoteSyncApi(
    config: config,
    authenticatedClient: ref.watch(syncAuthenticatedHttpClientProvider),
    cursorStore: ref.watch(syncCursorStoreProvider),
  );
  ref.onDispose(api.dispose);
  return api;
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    queue: ref.watch(syncQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    remote: ref.watch(remoteSyncApiProvider),
    metricsStore: ref.watch(syncMetricsStoreProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final syncOverviewProvider = StreamProvider<SyncOverview>((ref) {
  return ref.watch(syncManagerProvider).overviewStream;
});

final latestSyncPassMetricsProvider = StreamProvider<SyncPassMetrics?>((ref) async* {
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
