/// Configuration for the experimental HTTP sync backend.
///
/// Defaults are **fail-closed**: sync is off, and no shared URL/token is
/// baked into release builds. LAN / emulator development must pass explicit
/// dart-defines (including [SYNC_API_ALLOW_INSECURE_HTTP] for plain HTTP).
///
/// Physical device example:
/// ```bash
/// flutter run \
///   --dart-define=SYNC_API_ENABLED=true \
///   --dart-define=SYNC_API_BASE_URL=http://192.168.8.110:8000 \
///   --dart-define=SYNC_API_TOKEN=your-local-dev-token \
///   --dart-define=SYNC_API_ALLOW_INSECURE_HTTP=true
/// ```
///
/// Android emulator: use `http://10.0.2.2:8000` with the same insecure flag.
///
/// Production / release: HTTPS base URL, unique token, never allow insecure HTTP.
class SyncApiConfig {
  const SyncApiConfig({
    required this.baseUrl,
    required this.apiToken,
    required this.companyId,
    required this.userId,
    required this.deviceId,
    this.enabled = false,
    this.allowInsecureHttp = false,
    this.timeout = const Duration(seconds: 30),
  });

  /// Reads compile-time dart-defines with production-safe defaults.
  factory SyncApiConfig.fromEnvironment() {
    const enabledFlag = bool.fromEnvironment(
      'SYNC_API_ENABLED',
      defaultValue: false,
    );
    const baseUrl = String.fromEnvironment(
      'SYNC_API_BASE_URL',
      defaultValue: '',
    );
    const token = String.fromEnvironment(
      'SYNC_API_TOKEN',
      defaultValue: '',
    );
    const companyId = String.fromEnvironment(
      'SYNC_API_COMPANY_ID',
      defaultValue: '00000000-0000-4000-8000-000000000001',
    );
    const userId = String.fromEnvironment(
      'SYNC_API_USER_ID',
      defaultValue: '00000000-0000-4000-8000-000000000002',
    );
    const deviceId = String.fromEnvironment(
      'SYNC_API_DEVICE_ID',
      defaultValue: '00000000-0000-4000-8000-000000000003',
    );
    const allowInsecureHttp = bool.fromEnvironment(
      'SYNC_API_ALLOW_INSECURE_HTTP',
      defaultValue: false,
    );
    return SyncApiConfig.resolve(
      enabledFlag: enabledFlag,
      baseUrl: baseUrl,
      apiToken: token,
      companyId: companyId,
      userId: userId,
      deviceId: deviceId,
      allowInsecureHttp: allowInsecureHttp,
    );
  }

  /// Pure resolver used by [fromEnvironment] and unit tests.
  factory SyncApiConfig.resolve({
    required bool enabledFlag,
    required String baseUrl,
    required String apiToken,
    required String companyId,
    required String userId,
    required String deviceId,
    bool allowInsecureHttp = false,
    Duration timeout = const Duration(seconds: 30),
  }) {
    final url = baseUrl.trim();
    final token = apiToken.trim();
    final usable = isHttpEndpointUsable(
      baseUrl: url,
      apiToken: token,
      allowInsecureHttp: allowInsecureHttp,
    );
    return SyncApiConfig(
      enabled: enabledFlag && usable,
      baseUrl: url,
      apiToken: token,
      companyId: companyId.trim(),
      userId: userId.trim(),
      deviceId: deviceId.trim(),
      allowInsecureHttp: allowInsecureHttp,
      timeout: timeout,
    );
  }

  /// Whether [baseUrl] + [apiToken] are sufficient for HTTP sync.
  static bool isHttpEndpointUsable({
    required String baseUrl,
    required String apiToken,
    bool allowInsecureHttp = false,
  }) {
    final url = baseUrl.trim();
    if (url.isEmpty) {
      return false;
    }
    if (url.startsWith('https://') || url.startsWith('http://')) {
      return true;
    }
    return false;
  }

  final bool enabled;
  final String baseUrl;
  final String apiToken;
  final String companyId;
  final String userId;
  final String deviceId;
  final bool allowInsecureHttp;
  final Duration timeout;

  bool get isHttp => enabled;

  /// True when URL + token satisfy transport rules (HTTPS or allowed HTTP).
  bool get hasUsableHttpEndpoint => isHttpEndpointUsable(
        baseUrl: baseUrl,
        apiToken: apiToken,
        allowInsecureHttp: allowInsecureHttp,
      );

  String get modeLabel =>
      enabled ? 'HTTP $baseUrl' : 'Local only (HTTP sync off)';

  SyncApiConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? apiToken,
    String? companyId,
    String? userId,
    String? deviceId,
    bool? allowInsecureHttp,
    Duration? timeout,
  }) {
    final nextUrl = baseUrl ?? this.baseUrl;
    final nextToken = apiToken ?? this.apiToken;
    final nextAllow = allowInsecureHttp ?? this.allowInsecureHttp;
    final nextEnabledFlag = enabled ?? this.enabled;
    final usable = isHttpEndpointUsable(
      baseUrl: nextUrl,
      apiToken: nextToken,
      allowInsecureHttp: nextAllow,
    );
    return SyncApiConfig(
      enabled: nextEnabledFlag && usable,
      baseUrl: nextUrl,
      apiToken: nextToken,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      allowInsecureHttp: nextAllow,
      timeout: timeout ?? this.timeout,
    );
  }
}
