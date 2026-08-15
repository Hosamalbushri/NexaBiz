import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_failure.dart';
import '../sync/sync_entity_handler.dart';
import '../sync/sync_operation.dart';
import 'remote_sync_api.dart';
import 'sync_api_config.dart';

/// HTTP implementation of [RemoteSyncApi] for the experimental FastAPI backend.
///
/// Contract mapping (unchanged SyncManager / handlers):
/// - [push] → POST /api/v1/sync/push
/// - [pull] → GET  /api/v1/sync/pull  (cursor preferred; `since` for SyncManager)
/// - [getMeta] → GET /api/v1/sync/meta/{entityType}/{entityId}
///
/// 409 `conflict` responses become [SyncConflictFailure].
class HttpRemoteSyncApi implements RemoteSyncApi {
  HttpRemoteSyncApi({
    required SyncApiConfig config,
    http.Client? client,
  }) : _config = config,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final SyncApiConfig _config;
  final http.Client _client;
  final bool _ownsClient;

  /// Per-entity-type change-log cursors (experimental; in-memory only).
  final Map<String, int> _cursors = {};

  /// Cursor values waiting for successful local apply before commit.
  final Map<String, int> _stagedCursors = {};

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  void acknowledgePull(String entityType) {
    final staged = _stagedCursors.remove(entityType);
    if (staged != null) {
      _cursors[entityType] = staged;
    }
  }

  @override
  void abandonPull(String entityType) {
    _stagedCursors.remove(entityType);
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_config.apiToken}',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Company-Id': _config.companyId,
    'X-User-Id': _config.userId,
    'X-Device-Id': _config.deviceId,
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    try {
      final body = {
        'entity_type': entityType,
        'operation': {
          'operation_id': operation.id,
          'entity_type': entityType,
          'entity_id': operation.entityId,
          'type': operation.type.name,
          'payload': operation.payload,
          'base_version': operation.baseVersion,
        },
      };

      final response = await _client
          .post(
            _uri('/api/v1/sync/push'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_config.timeout);

      if (response.statusCode == 409) {
        throw _conflictFromBody(response.body, entityType, operation.entityId);
      }
      _ensureSuccess(response);

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      return SyncUploadAck(
        entityId: map['entity_id'] as String? ?? operation.entityId,
        remoteVersion: (map['remote_version'] as num?)?.toInt() ?? 0,
        remoteUpdatedAt: _parseDate(map['remote_updated_at']),
        serverPayload: map['server_payload'] is Map
            ? Map<String, dynamic>.from(map['server_payload'] as Map)
            : null,
      );
    } on AppFailure {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message, e);
    } on FormatException catch (e) {
      throw ServerFailure('Invalid sync response', e);
    }
  }

  @override
  Future<List<SyncRemoteChange>> pull({
    required String entityType,
    DateTime? since,
  }) async {
    try {
      final query = <String, String>{'entity_type': entityType};
      // Full catch-up when SyncManager has no watermark yet.
      if (since == null) {
        _cursors.remove(entityType);
      }
      final cursor = _cursors[entityType];
      if (cursor != null) {
        query['cursor'] = '$cursor';
      } else if (since != null) {
        query['since'] = since.toUtc().toIso8601String();
      } else {
        query['cursor'] = '0';
      }

      final all = <SyncRemoteChange>[];
      var guard = 0;
      while (guard < 50) {
        guard++;
        final response = await _client
            .get(_uri('/api/v1/sync/pull', query), headers: _headers)
            .timeout(_config.timeout);
        _ensureSuccess(response);
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final changes = map['changes'];
        if (changes is List) {
          for (final raw in changes) {
            if (raw is! Map) {
              continue;
            }
            final item = Map<String, dynamic>.from(raw);
            all.add(
              SyncRemoteChange(
                entityId: item['entity_id'] as String? ?? '',
                version: (item['version'] as num?)?.toInt() ?? 0,
                updatedAt:
                    _parseDate(item['updated_at']) ?? DateTime.now().toUtc(),
                payload: item['payload'] is Map
                    ? Map<String, dynamic>.from(item['payload'] as Map)
                    : <String, dynamic>{},
                deleted: item['deleted'] == true,
              ),
            );
          }
        }
        final nextCursor = (map['next_cursor'] as num?)?.toInt();
        if (nextCursor != null) {
          _stagedCursors[entityType] = nextCursor;
          query['cursor'] = '$nextCursor';
          query.remove('since');
        }
        final hasMore = map['has_more'] == true;
        if (!hasMore) {
          break;
        }
      }
      return all;
    } on AppFailure {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message, e);
    } on FormatException catch (e) {
      throw ServerFailure('Invalid sync response', e);
    }
  }

  @override
  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final response = await _client
          .get(
            _uri('/api/v1/sync/meta/$entityType/$entityId'),
            headers: _headers,
          )
          .timeout(_config.timeout);

      if (response.statusCode == 404) {
        return null;
      }
      _ensureSuccess(response);
      if (response.body.isEmpty || response.body == 'null') {
        return null;
      }
      final map = jsonDecode(response.body);
      if (map == null) {
        return null;
      }
      final data = Map<String, dynamic>.from(map as Map);
      return RemoteEntityMeta(
        entityId: data['entity_id'] as String? ?? entityId,
        version: (data['version'] as num?)?.toInt() ?? 0,
        updatedAt: _parseDate(data['updated_at']) ?? DateTime.now().toUtc(),
        payload: data['payload'] is Map
            ? Map<String, dynamic>.from(data['payload'] as Map)
            : null,
      );
    } on AppFailure {
      rethrow;
    } on http.ClientException catch (e) {
      throw NetworkFailure(e.message, e);
    } on FormatException catch (e) {
      throw ServerFailure('Invalid sync response', e);
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final failure = _failureFromBody(response);
    throw failure;
  }

  AppFailure _failureFromBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final err = Map<String, dynamic>.from(decoded['error'] as Map);
        final code = err['code'] as String? ?? 'server_error';
        final message = err['message'] as String? ?? 'Request failed';
        switch (code) {
          case 'unauthorized':
          case 'forbidden':
            return AuthenticationFailure(message);
          case 'validation_error':
            return ValidationFailure(message);
          case 'not_found':
            return ServerFailure.withCode(
              message: message,
              statusCode: response.statusCode,
            );
          case 'conflict':
            final details = err['details'] is Map
                ? Map<String, dynamic>.from(err['details'] as Map)
                : const <String, dynamic>{};
            return SyncConflictFailure.forEntity(
              message: message,
              entityType: details['entity_type'] as String?,
              entityId: details['entity_id'] as String?,
            );
          case 'network_error':
            return NetworkFailure(message);
          default:
            return ServerFailure.withCode(
              message: message,
              statusCode: response.statusCode,
            );
        }
      }
    } catch (_) {
      // Fall through to status-based mapping.
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return const AuthenticationFailure();
    }
    return ServerFailure.withCode(
      message: 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  SyncConflictFailure _conflictFromBody(
    String body,
    String entityType,
    String entityId,
  ) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final err = Map<String, dynamic>.from(decoded['error'] as Map);
        final details = err['details'] is Map
            ? Map<String, dynamic>.from(err['details'] as Map)
            : const <String, dynamic>{};
        return SyncConflictFailure.forEntity(
          message: err['message'] as String? ?? 'Synchronization conflict',
          entityType: details['entity_type'] as String? ?? entityType,
          entityId: details['entity_id'] as String? ?? entityId,
        );
      }
    } catch (_) {
      // ignore parse errors
    }
    return SyncConflictFailure.forEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
