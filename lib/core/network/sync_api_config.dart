/// Configuration for the experimental HTTP sync backend.
///
/// Physical device (same Wi‑Fi as the host running Docker):
/// ```bash
/// flutter run \
///   --dart-define=SYNC_API_ENABLED=true \
///   --dart-define=SYNC_API_BASE_URL=http://192.168.8.110:8000 \
///   --dart-define=SYNC_API_TOKEN=dev-sync-token-change-me
/// ```
///
/// Android emulator uses `http://10.0.2.2:8000` instead of the LAN IP.
///
/// Disable for pure offline/unit tests:
/// `--dart-define=SYNC_API_ENABLED=false`
class SyncApiConfig {
  const SyncApiConfig({
    required this.baseUrl,
    required this.apiToken,
    required this.companyId,
    required this.userId,
    required this.deviceId,
    this.enabled = true,
    this.timeout = const Duration(seconds: 30),
  });

  /// Reads compile-time dart-defines.
  ///
  /// Defaults target the experimental LAN backend so physical devices
  /// sync without forgetting `--dart-define` flags.
  factory SyncApiConfig.fromEnvironment() {
    const enabled = bool.fromEnvironment(
      'SYNC_API_ENABLED',
      defaultValue: true,
    );
    const baseUrl = String.fromEnvironment(
      'SYNC_API_BASE_URL',
      defaultValue: 'http://192.168.8.110:8000',
    );
    const token = String.fromEnvironment(
      'SYNC_API_TOKEN',
      defaultValue: 'dev-sync-token-change-me',
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
    return SyncApiConfig(
      enabled: enabled,
      baseUrl: baseUrl,
      apiToken: token,
      companyId: companyId,
      userId: userId,
      deviceId: deviceId,
    );
  }

  final bool enabled;
  final String baseUrl;
  final String apiToken;
  final String companyId;
  final String userId;
  final String deviceId;
  final Duration timeout;

  bool get isHttp => enabled;

  String get modeLabel => enabled ? 'HTTP $baseUrl' : 'In-memory (local only)';

  SyncApiConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? apiToken,
    String? companyId,
    String? userId,
    String? deviceId,
    Duration? timeout,
  }) {
    return SyncApiConfig(
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      apiToken: apiToken ?? this.apiToken,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      timeout: timeout ?? this.timeout,
    );
  }
}
