import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_failure.dart';
import 'sync_api_config.dart';
import 'token_store.dart';

/// Central authenticated HTTP client with one-shot refresh-on-401.
///
/// SyncManager never talks to this directly — [HttpRemoteSyncApi] uses it.
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    required SyncApiConfig config,
    required TokenStore tokenStore,
    http.Client? client,
    Future<bool> Function()? onRefresh,
    void Function()? onSessionExpired,
  }) : _config = config,
       _tokenStore = tokenStore,
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _onRefresh = onRefresh,
       _onSessionExpired = onSessionExpired;

  SyncApiConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;
  final bool _ownsClient;
  final Future<bool> Function()? _onRefresh;
  final void Function()? _onSessionExpired;

  bool _refreshing = false;

  void updateConfig(SyncApiConfig config) {
    _config = config;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Uri uri(String path, [Map<String, String>? query]) {
    final base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final access = await _tokenStore.readAccessToken() ?? _config.apiToken;
    return {
      'Authorization': 'Bearer $access',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      'X-Device-Id': _config.deviceId,
    };
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
  }) {
    return _send(() async {
      return _client
          .get(uri(path, query), headers: await _headers(jsonBody: false))
          .timeout(_config.timeout);
    });
  }

  Future<http.Response> post(String path, {Object? body}) {
    return _send(() async {
      return _client
          .post(
            uri(path),
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_config.timeout);
    });
  }

  Future<http.Response> patch(String path, {Object? body}) {
    return _send(() async {
      return _client
          .patch(
            uri(path),
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_config.timeout);
    });
  }

  Future<http.Response> delete(String path) {
    return _send(() async {
      return _client
          .delete(uri(path), headers: await _headers(jsonBody: false))
          .timeout(_config.timeout);
    });
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request();
      if (response.statusCode != 401) {
        return response;
      }
      if (_refreshing || _onRefresh == null) {
        _onSessionExpired?.call();
        return response;
      }
      final refresh = _onRefresh;
      _refreshing = true;
      try {
        final ok = await refresh();
        if (!ok) {
          _onSessionExpired?.call();
          return response;
        }
        response = await request();
        if (response.statusCode == 401) {
          _onSessionExpired?.call();
        }
        return response;
      } finally {
        _refreshing = false;
      }
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message, e);
    }
  }

  Future<http.Response> postPublic(String path, {Object? body}) async {
    try {
      return await _client
          .post(
            uri(path),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_config.timeout);
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message, e);
    }
  }

  AppFailure mapFailure(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final err = Map<String, dynamic>.from(decoded['error'] as Map);
        final code = err['code'] as String? ?? 'server_error';
        final message = err['message'] as String? ?? 'Request failed';
        switch (code) {
          case 'unauthorized':
            return AuthenticationFailure(message);
          case 'forbidden':
          case 'permission_denied':
            return AuthorizationFailure.withDetails(
              message: message,
              code: code,
            );
          case 'validation_error':
            return ValidationFailure(message);
          case 'conflict':
            return SyncConflictFailure(message);
          default:
            return ServerFailure.withCode(
              message: message,
              statusCode: response.statusCode,
            );
        }
      }
    } catch (_) {}
    if (response.statusCode == 401) {
      return const AuthenticationFailure();
    }
    if (response.statusCode == 403) {
      return const AuthorizationFailure();
    }
    return ServerFailure.withCode(
      message: 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> decodeData(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw mapFailure(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const ServerFailure('Invalid response');
  }
}
