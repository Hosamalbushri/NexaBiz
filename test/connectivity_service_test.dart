import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';

void main() {
  test('wifi / mobile / vpn / bluetooth / satellite count as online', () {
    expect(
      ConnectivityService.mapResults(const [ConnectivityResult.wifi]),
      ConnectivityStatus.online,
    );
    expect(
      ConnectivityService.mapResults(const [ConnectivityResult.bluetooth]),
      ConnectivityStatus.online,
    );
    expect(
      ConnectivityService.mapResults(const [ConnectivityResult.satellite]),
      ConnectivityStatus.online,
    );
    expect(
      ConnectivityService.mapResults(const [ConnectivityResult.vpn]),
      ConnectivityStatus.online,
    );
  });

  test('only none counts as offline', () {
    expect(
      ConnectivityService.mapResults(const [ConnectivityResult.none]),
      ConnectivityStatus.offline,
    );
  });

  test('empty list is treated as online (plugin hasConnectivity)', () {
    expect(
      ConnectivityService.mapResults(const []),
      ConnectivityStatus.online,
    );
  });

  test('start with none stays offline when probe is skipped in tests', () async {
    final stream = StreamController<List<ConnectivityResult>>.broadcast();
    final service = ConnectivityService(
      connectivityStream: stream.stream,
      initialResults: const [ConnectivityResult.none],
    );
    await service.start();
    expect(service.isOnline, isFalse);
    await service.dispose();
    await stream.close();
  });
}
