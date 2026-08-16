import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../connectivity/connectivity_service.dart';
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

/// Experimental sync API config (HTTP by default → LAN backend).
///
/// [AppBootstrap] overwrites [deviceId] with a per-install UUID from Hive.
final syncApiConfigProvider = StateProvider<SyncApiConfig>((ref) {
  return SyncApiConfig.fromEnvironment();
});

/// Remote sync API. Uses HTTP whenever a base URL is configured.
///
/// Important: do **not** key this off [SyncApiConfig.enabled]. That flag is
/// flipped when the user opts into sync; watching it would recreate
/// [SyncManager] / [SyncEnabledController] and reset the enable toggle.
final remoteSyncApiProvider = Provider<RemoteSyncApi>((ref) {
  final baseUrl = ref.watch(
    syncApiConfigProvider.select((c) => c.baseUrl.trim()),
  );
  if (baseUrl.isEmpty) {
    return InMemoryRemoteSyncApi();
  }

  final config = ref.read(syncApiConfigProvider);
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

/// Opens the durable sync queue box during app bootstrap.
Future<void> openSyncQueueBox() async {
  await SyncQueue.registerAdapter();
  if (!Hive.isBoxOpen(HiveBoxes.syncQueue)) {
    await Hive.openBox<SyncOperation>(HiveBoxes.syncQueue);
  }
}
