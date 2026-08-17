import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/network/sync_api_config.dart';

void main() {
  group('SyncApiConfig.resolve', () {
    test('defaults keep HTTP sync disabled without URL/token', () {
      final config = SyncApiConfig.resolve(
        enabledFlag: false,
        baseUrl: '',
        apiToken: '',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
      );
      expect(config.enabled, isFalse);
      expect(config.hasUsableHttpEndpoint, isFalse);
      expect(config.modeLabel, contains('Local only'));
    });

    test('rejects enabled flag when URL or token missing', () {
      final missingToken = SyncApiConfig.resolve(
        enabledFlag: true,
        baseUrl: 'https://sync.example.com',
        apiToken: '',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
      );
      expect(missingToken.enabled, isFalse);

      final missingUrl = SyncApiConfig.resolve(
        enabledFlag: true,
        baseUrl: '',
        apiToken: 'secret',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
      );
      expect(missingUrl.enabled, isFalse);
    });

    test('rejects plain HTTP unless allowInsecureHttp is set', () {
      final blocked = SyncApiConfig.resolve(
        enabledFlag: true,
        baseUrl: 'http://192.168.8.110:8000',
        apiToken: 'secret',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
      );
      expect(blocked.enabled, isFalse);
      expect(blocked.hasUsableHttpEndpoint, isFalse);

      final allowed = SyncApiConfig.resolve(
        enabledFlag: true,
        baseUrl: 'http://192.168.8.110:8000',
        apiToken: 'secret',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
        allowInsecureHttp: true,
      );
      expect(allowed.enabled, isTrue);
      expect(allowed.hasUsableHttpEndpoint, isTrue);
    });

    test('accepts HTTPS with token when enabled', () {
      final config = SyncApiConfig.resolve(
        enabledFlag: true,
        baseUrl: 'https://sync.example.com',
        apiToken: 'secret',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
      );
      expect(config.enabled, isTrue);
      expect(config.hasUsableHttpEndpoint, isTrue);
    });

    test('copyWith re-validates endpoint usability', () {
      final base = SyncApiConfig.resolve(
        enabledFlag: true,
        baseUrl: 'https://sync.example.com',
        apiToken: 'secret',
        companyId: 'c',
        userId: 'u',
        deviceId: 'd',
      );
      final downgraded = base.copyWith(baseUrl: 'http://localhost:8000');
      expect(downgraded.enabled, isFalse);

      final lan = base.copyWith(
        baseUrl: 'http://localhost:8000',
        allowInsecureHttp: true,
      );
      expect(lan.enabled, isTrue);
    });
  });
}
