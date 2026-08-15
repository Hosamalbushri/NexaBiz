import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../connectivity/connectivity_service.dart';
import '../database/hive_boxes.dart';
import '../network/http_remote_sync_api.dart';
import '../network/remote_sync_api.dart';
import '../network/sync_api_config.dart';
import 'sync_manager.dart';
import 'sync_operation.dart';
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

/// Experimental sync API config (HTTP by default → LAN backend).
///
/// [AppBootstrap] overwrites [deviceId] with a per-install UUID from Hive.
final syncApiConfigProvider = StateProvider<SyncApiConfig>((ref) {
  return SyncApiConfig.fromEnvironment();
});

/// Swappable remote: HTTP experimental backend when enabled, else in-memory.
///
/// Unchanged: SyncManager, SyncQueue, entity handlers, repositories.
final remoteSyncApiProvider = Provider<RemoteSyncApi>((ref) {
  final config = ref.watch(syncApiConfigProvider);
  if (config.enabled) {
    final api = HttpRemoteSyncApi(config: config);
    ref.onDispose(api.dispose);
    return api;
  }
  return InMemoryRemoteSyncApi();
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    queue: ref.watch(syncQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final syncOverviewProvider = StreamProvider<SyncOverview>((ref) {
  return ref.watch(syncManagerProvider).overviewStream;
});

/// Opens the durable sync queue box during app bootstrap.
Future<void> openSyncQueueBox() async {
  await SyncQueue.registerAdapter();
  if (!Hive.isBoxOpen(HiveBoxes.syncQueue)) {
    await Hive.openBox<SyncOperation>(HiveBoxes.syncQueue);
  }
}
