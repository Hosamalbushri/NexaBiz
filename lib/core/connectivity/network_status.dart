import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/sync/sync.dart';

/// Network connectivity and server sync connection status.
enum NetworkStatus {
  /// App has active internet & server connection.
  online,

  /// App is offline (no network or server unreachable).
  offline,

  /// App is actively attempting server reconnect or sync pass.
  reconnecting;

  bool get isOnline => this == NetworkStatus.online;
  bool get isOffline => this == NetworkStatus.offline;
  bool get isReconnecting => this == NetworkStatus.reconnecting;
}

/// Reactive provider exposing high-level [NetworkStatus].
final networkStatusProvider = Provider<NetworkStatus>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final syncOverviewAsync = ref.watch(syncOverviewProvider);

  if (!connectivity.isOnline) {
    return NetworkStatus.offline;
  }

  final overview = syncOverviewAsync.asData?.value;
  if (overview == null) {
    return NetworkStatus.online;
  }

  if (overview.isSyncing) {
    return NetworkStatus.reconnecting;
  }

  if (!overview.isOnline) {
    return NetworkStatus.offline;
  }

  return NetworkStatus.online;
});
