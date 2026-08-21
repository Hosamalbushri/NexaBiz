import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../modules/authentication/data/secure_token_storage.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../errors/app_error_domain.dart';

/// Isolated authentication service specifically for server bootstrap access.
///
/// Disconnected from application user authorization, RBAC permissions, and [AuthState].
class ServerBootstrapAuthService {
  ServerBootstrapAuthService({
    required SecureTokenStorage tokenStorage,
    http.Client? client,
  })  : _tokenStorage = tokenStorage,
        _client = client;

  final SecureTokenStorage _tokenStorage;
  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  /// Authenticates against the target server's authentication endpoint specifically
  /// for initialization/bootstrap authorization.
  Future<String> authenticate({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanUrl/api/v1/auth/login');

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw classifyAppError(
          'Invalid server bootstrap credentials',
          category: AppErrorCategory.authentication,
          severity: FailureSeverity.recoverable,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw classifyAppError(
          'Server bootstrap authentication failed with status ${response.statusCode}',
          category: AppErrorCategory.server,
          severity: FailureSeverity.recoverable,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? json;

      final token = (data['access_token'] as String?) ?? (data['token'] as String?);
      if (token == null || token.isEmpty) {
        throw classifyAppError(
          'Server authentication payload missing access token',
          category: AppErrorCategory.authentication,
          severity: FailureSeverity.recoverable,
        );
      }

      await _tokenStorage.saveBootstrapToken(token);
      return token;
    } catch (e) {
      if (e is AppError) rethrow;
      throw classifyAppError(e, category: AppErrorCategory.network);
    }
  }

  /// Retrieves the current stored bootstrap token.
  Future<String?> getBootstrapToken() => _tokenStorage.readBootstrapToken();

  /// Clears the stored bootstrap token.
  Future<void> clearBootstrapToken() => _tokenStorage.clearBootstrapToken();

  /// Checks if a valid bootstrap token exists.
  Future<bool> isAuthenticated() async {
    final token = await getBootstrapToken();
    return token != null && token.isNotEmpty;
  }
}

/// Provider for [ServerBootstrapAuthService].
final serverBootstrapAuthServiceProvider = Provider<ServerBootstrapAuthService>((ref) {
  return ServerBootstrapAuthService(
    tokenStorage: ref.watch(secureTokenStorageProvider),
  );
});
