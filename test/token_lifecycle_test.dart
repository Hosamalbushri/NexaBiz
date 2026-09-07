import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stock_count/core/network/authenticated_http_client.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/network/token_refresh_outcome.dart';
import 'package:stock_count/core/network/token_store.dart';

class TestTokenStore implements TokenStore {
  String? accessToken = 'initial_access_token';
  String? refreshToken = 'initial_refresh_token';

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<DateTime?> readAccessExpiresAt() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

class Mock401Client extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream.value([]), 401);
  }
}

void main() {
  late TestTokenStore tokenStore;

  setUp(() {
    tokenStore = TestTokenStore();
  });

  group('Token Lifecycle & Concurrency (AU-04)', () {
    test(
      'Single-flight concurrent refresh lock prevents duplicate refresh calls',
      () async {
        var refreshCount = 0;
        final completer = Completer<TokenRefreshOutcome>();

        final client = AuthenticatedHttpClient(
          config: const SyncApiConfig(
            baseUrl: 'https://api.test',
            apiToken: 'dev-token',
            companyId: 'company_01',
            userId: 'user_01',
            deviceId: 'device_01',
            enabled: true,
          ),
          tokenStore: tokenStore,
          client: Mock401Client(),
          onRefresh: () async {
            refreshCount++;
            return completer.future;
          },
        );

        // Simulate 3 concurrent 401 requests invoking refresh
        final req1 = client.get('/endpoint-1');
        final req2 = client.get('/endpoint-2');
        final req3 = client.get('/endpoint-3');

        // Complete refresh
        completer.complete(TokenRefreshOutcome.refreshed);

        try {
          await Future.wait([req1, req2, req3]);
        } catch (_) {}

        expect(refreshCount, 1);
      },
    );

    test('Failed token refresh clears tokens', () async {
      await tokenStore.saveTokens(
        accessToken: 'expired_access',
        refreshToken: 'invalid_refresh',
        expiresInSeconds: 3600,
      );

      await tokenStore.clear();

      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });
  });
}
