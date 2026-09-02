import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// High-level connectivity for sync (online vs offline).
enum ConnectivityStatus { offline, online }

typedef InternetProbe = Future<bool> Function();

/// DNS probe used when Android reports [ConnectivityResult.none] incorrectly
/// (common when `getActiveNetwork()` is null but Wi‑Fi still works).
Future<bool> dnsInternetProbe(String host) async {
  final trimmed = host.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  try {
    final result = await InternetAddress.lookup(trimmed).timeout(
      const Duration(seconds: 3),
    );
    return result.any((address) => address.rawAddress.isNotEmpty);
  } catch (_) {
    return false;
  }
}

/// Reusable connectivity service — event-driven, with a fallback probe.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    Stream<List<ConnectivityResult>>? connectivityStream,
    List<ConnectivityResult>? initialResults,
    this._internetProbe,
  }) : _connectivity = connectivity ?? Connectivity(),
       _streamOverride = connectivityStream,
       _initialOverride = initialResults;

  final Connectivity _connectivity;
  final Stream<List<ConnectivityResult>>? _streamOverride;
  final List<ConnectivityResult>? _initialOverride;
  final InternetProbe? _internetProbe;

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _status = ConnectivityStatus.offline;
  var _started = false;

  ConnectivityStatus get current => _status;

  bool get isOnline => _status == ConnectivityStatus.online;

  Stream<ConnectivityStatus> get onStatusChanged => _controller.stream;

  bool get _canProbe =>
      _internetProbe != null &&
      _streamOverride == null &&
      _initialOverride == null;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    final initial = _initialOverride ?? await _connectivity.checkConnectivity();
    await _applyResults(initial);

    final stream = _streamOverride ?? _connectivity.onConnectivityChanged;
    _subscription = stream.listen((results) {
      unawaited(_applyResults(results));
    });
  }

  /// Test / manual override without waiting for platform events.
  void debugSetStatus(ConnectivityStatus status) {
    _emit(status);
  }

  Future<void> _applyResults(List<ConnectivityResult> results) async {
    var status = mapResults(results);
    if (status == ConnectivityStatus.offline && _canProbe) {
      if (await _internetProbe!()) {
        status = ConnectivityStatus.online;
      }
    }
    _emit(status);
  }

  /// Visible for tests. Any transport except a lone `none` counts as online.
  static ConnectivityStatus mapResults(List<ConnectivityResult> results) {
    return results.hasConnectivity
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  void _emit(ConnectivityStatus status) {
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
