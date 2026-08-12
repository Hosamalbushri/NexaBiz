import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../connectivity/connectivity_service.dart';
import '../database/hive_boxes.dart';
import '../network/remote_sync_api.dart';
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

final remoteSyncApiProvider = Provider<RemoteSyncApi>((ref) {
  // Replace with HTTP-backed implementation when the backend is available.
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
