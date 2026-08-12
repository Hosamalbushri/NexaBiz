import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// High-level connectivity for sync (online vs offline).
enum ConnectivityStatus { offline, online }

/// Reusable connectivity service — event-driven, no server polling.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    Stream<List<ConnectivityResult>>? connectivityStream,
    List<ConnectivityResult>? initialResults,
  }) : _connectivity = connectivity ?? Connectivity(),
       _streamOverride = connectivityStream,
       _initialOverride = initialResults;

  final Connectivity _connectivity;
  final Stream<List<ConnectivityResult>>? _streamOverride;
  final List<ConnectivityResult>? _initialOverride;

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _status = ConnectivityStatus.offline;
  var _started = false;

  ConnectivityStatus get current => _status;

  bool get isOnline => _status == ConnectivityStatus.online;

  Stream<ConnectivityStatus> get onStatusChanged => _controller.stream;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final initial = _initialOverride ?? await _connectivity.checkConnectivity();
    _emit(_map(initial));

    final stream = _streamOverride ?? _connectivity.onConnectivityChanged;
    _subscription = stream.listen((results) {
      _emit(_map(results));
    });
  }

  /// Test / manual override without waiting for platform events.
  void debugSetStatus(ConnectivityStatus status) {
    _emit(status);
  }

  ConnectivityStatus _map(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    final online = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );
    return online ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  void _emit(ConnectivityStatus status) {
    if (_status == status && _controller.hasListener) {
      // Still publish first value after start even if unchanged for new listeners.
    }
    final changed = _status != status;
    _status = status;
    if (changed || !_controller.isClosed) {
      _controller.add(status);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
