import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_failure.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'sync_api_config.dart';
import 'token_refresh_outcome.dart';
import 'token_store.dart';

/// Central authenticated HTTP client with single-flight refresh-on-401.
///
/// Concurrent 401s wait for the same refresh attempt instead of immediately
/// treating the session as expired. Network failures during refresh do **not**
/// expire the session (offline work keeps the local permission snapshot).
class AuthenticatedHttpClient {
  AuthenticatedHttpClient({
    required this._config,
    required this._tokenStore,
    http.Client? client,
    this._onRefresh,
    this._onSessionExpired,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  SyncApiConfig _config;
  final TokenStore _tokenStore;
  final http.Client _client;
  final bool _ownsClient;
  final Future<TokenRefreshOutcome> Function()? _onRefresh;
  final void Function()? _onSessionExpired;

  Future<TokenRefreshOutcome>? _refreshInFlight;

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
    final correlation = SyncRequestContext.correlationId;
    return {
      'Authorization': 'Bearer $access',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      'X-Device-Id': _config.deviceId,
      if (correlation != null && correlation.isNotEmpty)
        'X-Correlation-Id': correlation,
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

  Future<TokenRefreshOutcome> _refreshOnce() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final refresh = _onRefresh;
    if (refresh == null) {
      return Future.value(TokenRefreshOutcome.unauthorized);
    }

    final future = () async {
      try {
        return await refresh();
      } on NetworkFailure {
        // Transient network failure during refresh — keep local session
        // instead of forcing re-login. The next request will retry refresh.
        return TokenRefreshOutcome.unavailable;
      } on SocketException {
        return TokenRefreshOutcome.unavailable;
      } on TimeoutException {
        return TokenRefreshOutcome.unavailable;
      } on http.ClientException {
        return TokenRefreshOutcome.unavailable;
      } catch (_) {
        return TokenRefreshOutcome.unauthorized;
      }
    }();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
    return future;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request();
      if (response.statusCode != 401) {
        return response;
      }
      if (_onRefresh == null) {
        _onSessionExpired?.call();
        return response;
      }
      final outcome = await _refreshOnce();
      switch (outcome) {
        case TokenRefreshOutcome.refreshed:
          response = await request();
          if (response.statusCode == 401) {
            _onSessionExpired?.call();
          }
          return response;
        case TokenRefreshOutcome.unavailable:
          // Offline / transient — keep local session; do not force re-login.
          return response;
        case TokenRefreshOutcome.unauthorized:
          _onSessionExpired?.call();
          return response;
        case TokenRefreshOutcome.syncDisableApproved:
          // AuthController already flagged; SyncEnabledController will opt out.
          return response;
      }
    } on HandshakeException catch (e) {
      throw NetworkFailure(_tlsMessage(e), e);
    } on SocketException catch (e) {
      throw NetworkFailure(e.message, e);
    } on TimeoutException catch (e) {
      throw NetworkFailure(e.message ?? 'Request timed out', e);
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
    } on HandshakeException catch (e) {
      throw NetworkFailure(_tlsMessage(e), e);
    } on SocketException catch (e) {
      throw NetworkFailure(e.message, e);
    } on TimeoutException catch (e) {
      throw NetworkFailure(e.message ?? 'Request timed out', e);
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message, e);
    }
  }

  static String _tlsMessage(HandshakeException e) {
    return 'TLS handshake failed. The device does not trust the '
        'server certificate (${e.message}).';
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

  /// Decodes `{ "data": [ ... ] }` list payloads.
  List<dynamic> decodeDataList(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw mapFailure(response);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['data'] is List) {
      return List<dynamic>.from(decoded['data'] as List);
    }
    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }
    throw const ServerFailure('Invalid list response');
  }
}
