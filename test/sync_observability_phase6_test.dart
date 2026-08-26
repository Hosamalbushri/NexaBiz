import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/authenticated_http_client.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/network/token_store.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/database/hive_boxes.dart';

class _HandshakeFailClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw HandshakeException('unable to get local issuer certificate');
  }
}

class _MemoryTokenStore implements TokenStore {
  String? access = 'tok';

  @override
  Future<void> clear() async {
    access = null;
  }

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<DateTime?> readAccessExpiresAt() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    access = accessToken;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_obs_p6_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('SyncRequestContext exposes correlation to zone readers', () async {
    String? seen;
    await SyncRequestContext.run(
      correlationId: 'corr-1',
      trigger: SyncPassTrigger.auto,
      body: () async {
        seen = SyncRequestContext.correlationId;
        expect(SyncRequestContext.trigger, SyncPassTrigger.auto);
      },
    );
    expect(seen, 'corr-1');
    expect(SyncRequestContext.correlationId, isNull);
  });

  test('AuthenticatedHttpClient sends X-Correlation-Id', () async {
    http.Request? captured;
    final client = AuthenticatedHttpClient(
      config: const SyncApiConfig(
        enabled: true,
        baseUrl: 'http://example.test',
        apiToken: 't',
        companyId: '00000000-0000-4000-8000-000000000001',
        userId: '00000000-0000-4000-8000-000000000002',
        deviceId: '00000000-0000-4000-8000-0000000000aa',
      ),
      tokenStore: _MemoryTokenStore(),
      client: MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      }),
    );

    await SyncRequestContext.run(
      correlationId: 'pass-abc',
      body: () => client.get('/api/v1/sync/pull'),
    );

    expect(captured, isNotNull);
    expect(captured!.headers['X-Correlation-Id'], 'pass-abc');
    client.dispose();
  });

  test('AuthenticatedHttpClient maps TLS handshake errors to NetworkFailure',
      () async {
    final client = AuthenticatedHttpClient(
      config: const SyncApiConfig(
        enabled: true,
        baseUrl: 'https://example.test',
        apiToken: 't',
        companyId: '00000000-0000-4000-8000-000000000001',
        userId: '00000000-0000-4000-8000-000000000002',
        deviceId: '00000000-0000-4000-8000-0000000000aa',
      ),
      tokenStore: _MemoryTokenStore(),
      client: _HandshakeFailClient(),
    );

    expect(
      () => client.postPublic('/api/v1/auth/login', body: const {}),
      throwsA(isA<NetworkFailure>()),
    );
    client.dispose();
  });

  test('SyncManager records metrics with correlation and duration', () async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue_p6');
    final metricsBox = await Hive.openBox('sync_metrics_p6');
    final queue = SyncQueue(box: syncBox);
    final metrics = SyncMetricsStore(box: metricsBox);
    final connectivityStream =
        StreamController<List<ConnectivityResult>>.broadcast();
    final connectivity = ConnectivityService(
      connectivityStream: connectivityStream.stream,
      initialResults: const [ConnectivityResult.wifi],
    );
    await connectivity.start();

    final manager = SyncManager(
      queue: queue,
      connectivity: connectivity,
      remoteProvider: () => InMemoryRemoteSyncApi(),
      metricsStore: metrics,
    );
    await manager.start(enabled: true);
    final result = await manager.syncNow(trigger: SyncPassTrigger.manual);
    expect(result.correlationId, isNotNull);
    expect(result.correlationId, isNotEmpty);
    expect(result.durationMs, greaterThanOrEqualTo(0));
    expect(result.trigger, SyncPassTrigger.manual);

    final latest = await metrics.latest();
    expect(latest, isNotNull);
    expect(latest!.correlationId, result.correlationId);

    await manager.dispose();
    await connectivity.dispose();
    await connectivityStream.close();
  });

  test('SyncOsWakeSignal mark and consume', () async {
    await Hive.openBox<int>(HiveBoxes.syncOsWake);
    expect(await SyncOsWakeSignal.isPending(), isFalse);
    await SyncOsWakeSignal.markRequested(
      at: DateTime.utc(2026, 8, 16, 1),
    );
    expect(await SyncOsWakeSignal.isPending(), isTrue);
    final wake = await SyncOsWakeSignal.consume();
    expect(wake, DateTime.utc(2026, 8, 16, 1));
    expect(await SyncOsWakeSignal.isPending(), isFalse);
  });

  test('SyncOverview exports sanitized diagnostic report without secrets', () {
    final overview = SyncOverview.initial().copyWith(
      pendingCount: 3,
      failedCount: 1,
      diagnostics: const SyncDiagnostics(
        lastStatusCode: 429,
        lastStatusMessage: 'Too Many Requests',
        lastErrorCode: 'rate_limited',
        lastErrorMessage: 'Rate limit exceeded. Try again in 5s.',
      ),
    );

    final report = overview.toDiagnosticReport();

    expect(report['sync_phase'], 'offline');
    expect(report['pending_count'], 3);
    expect(report['failed_count'], 1);
    expect(report['diagnostics']['last_status_code'], 429);
    expect(report['diagnostics']['last_error_code'], 'rate_limited');

    // Ensure no sensitive credentials keys exist in output
    expect(report.containsKey('password'), isFalse);
    expect(report.containsKey('api_token'), isFalse);
    expect(report.containsKey('secret'), isFalse);
  });
}
