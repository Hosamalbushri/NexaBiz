import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_failure.dart';
import '../../modules/sync/sync.dart';
import 'authenticated_http_client.dart';
import 'remote_sync_api.dart';
import 'sync_api_config.dart';
import '../time/domain/trusted_clock.dart';

/// HTTP implementation of [RemoteSyncApi] for the experimental FastAPI backend.
///
/// Auth is centralized in [AuthenticatedHttpClient] (token + refresh).
/// Pull cursors are persisted via [SyncCursorStore] so restarts resume cleanly.
class HttpRemoteSyncApi implements RemoteSyncApi {
  HttpRemoteSyncApi({
    required this._config,
    AuthenticatedHttpClient? authenticatedClient,
    http.Client? client,
    SyncCursorStore? cursorStore,
    this._clock,
  }) : _authClient = authenticatedClient,
       _client = client ?? http.Client(),
       _ownsClient = authenticatedClient == null && client == null,
       _cursors = cursorStore ?? SyncCursorStore();

  final TrustedClock? _clock;

  final SyncApiConfig _config;
  final AuthenticatedHttpClient? _authClient;
  final http.Client _client;
  final bool _ownsClient;
  final SyncCursorStore _cursors;

  /// Staged next cursor per entity — committed only via [acknowledgePull].
  final Map<String, int> _stagedCursors = {};

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<void> acknowledgePull(String entityType) async {
    final staged = _stagedCursors.remove(entityType);
    if (staged != null) {
      await _cursors.write(entityType, staged);
    }
  }

  @override
  Future<void> abandonPull(String entityType) async {
    _stagedCursors.remove(entityType);
  }

  Future<Map<String, String>> get _legacyHeaders async => {
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

  Future<http.Response> _post(String path, Object body) async {
    final auth = _authClient;
    if (auth != null) {
      return auth.post(path, body: body);
    }
    return _client
        .post(
          _uri(path),
          headers: await _legacyHeaders,
          body: jsonEncode(body),
        )
        .timeout(_config.timeout);
  }

  Future<http.Response> _get(String path, [Map<String, String>? query]) async {
    final auth = _authClient;
    if (auth != null) {
      return auth.get(path, query: query);
    }
    return _client
        .get(_uri(path, query), headers: await _legacyHeaders)
        .timeout(_config.timeout);
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
          'company_id': operation.companyId,
          'device_id': operation.deviceId,
        },
      };

      final response = await _post('/api/v1/sync/push', body);

      if (response.statusCode == 409) {
        throw _conflictFromBody(response.body, entityType, operation.entityId);
      }
      _ensureSuccess(response);

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      _calibrate(map);
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
  Future<List<SyncBatchPushItemResult>> pushBatch(
    List<SyncOperation> operations,
  ) async {
    if (operations.isEmpty) {
      return const [];
    }
    try {
      final body = {
        'operations': [
          for (final op in operations)
            {
              'operation_id': op.id,
              'entity_type': op.entityType,
              'entity_id': op.entityId,
              'type': op.type.name,
              'payload': op.payload,
              'base_version': op.baseVersion,
              'company_id': op.companyId,
              'device_id': op.deviceId,
            },
        ],
      };
      final response = await _post('/api/v1/sync/push/batch', body);
      _ensureSuccess(response);
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      _calibrate(map);
      final rawResults = map['results'];
      if (rawResults is! List) {
        throw const ServerFailure('Invalid batch push response');
      }
      final byId = <String, SyncBatchPushItemResult>{};
      for (final raw in rawResults) {
        if (raw is! Map) {
          continue;
        }
        final item = Map<String, dynamic>.from(raw);
        final operationId = item['operation_id'] as String? ?? '';
        final status = item['status'] as String? ?? 'error';
        SyncUploadAck? ack;
        AppFailure? failure;
        if (status == 'success' && item['ack'] is Map) {
          final ackMap = Map<String, dynamic>.from(item['ack'] as Map);
          ack = SyncUploadAck(
            entityId: ackMap['entity_id'] as String? ?? '',
            remoteVersion: (ackMap['remote_version'] as num?)?.toInt() ?? 0,
            remoteUpdatedAt: _parseDate(ackMap['remote_updated_at']),
            serverPayload: ackMap['server_payload'] is Map
                ? Map<String, dynamic>.from(ackMap['server_payload'] as Map)
                : null,
          );
        } else if (status == 'conflict') {
          final details = item['conflict'] is Map
              ? Map<String, dynamic>.from(item['conflict'] as Map)
              : const <String, dynamic>{};
          final err = item['error'] is Map
              ? Map<String, dynamic>.from(item['error'] as Map)
              : const <String, dynamic>{};
          failure = SyncConflictFailure.forEntity(
            message: err['message'] as String? ?? 'Synchronization conflict',
            entityType: details['entity_type'] as String?,
            entityId: details['entity_id'] as String? ?? operationId,
            serverVersion: (details['server_version'] as num?)?.toInt() ?? 0,
            clientBaseVersion: (details['client_base_version'] as num?)?.toInt() ?? 0,
            serverRecord: details['server_record'] is Map
                ? Map<String, dynamic>.from(details['server_record'] as Map)
                : null,
          );
        } else {
          final err = item['error'] is Map
              ? Map<String, dynamic>.from(item['error'] as Map)
              : const <String, dynamic>{};
          final code = err['code'] as String? ?? 'server_error';
          final message = err['message'] as String? ?? 'Batch item failed';
          failure = switch (code) {
            'unauthorized' => AuthenticationFailure(message),
            'forbidden' || 'permission_denied' =>
              AuthorizationFailure.withDetails(message: message, code: code),
            'validation_error' => ValidationFailure(message),
            _ => ServerFailure(message),
          };
        }
        byId[operationId] = SyncBatchPushItemResult(
          operationId: operationId,
          status: status,
          ack: ack,
          failure: failure,
        );
      }
      // Preserve caller order; fill gaps if server omitted an id.
      return [
        for (final op in operations)
          byId[op.id] ??
              SyncBatchPushItemResult(
                operationId: op.id,
                status: 'error',
                failure: const ServerFailure('Missing batch result'),
              ),
      ];
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
    String? entityType,
    DateTime? since,
  }) async {
    try {
      final query = <String, String>{};
      if (entityType != null && entityType.isNotEmpty) {
        query['entity_type'] = entityType;
      }
      final cursorKey = entityType ?? '__global__';
      // Prefer durable sequence cursor; fall back to since only when unknown.
      final stored = await _cursors.read(cursorKey);
      if (stored != null) {
        query['cursor'] = '$stored';
      } else if (since != null) {
        query['since'] = since.toUtc().toIso8601String();
      } else {
        query['cursor'] = '0';
      }

      final all = <SyncRemoteChange>[];
      var guard = 0;
      while (guard < 50) {
        guard++;
        final response = await _get('/api/v1/sync/pull', query);
        _ensureSuccess(response);
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        _calibrate(map);
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
                entityType: item['entity_type'] as String? ?? entityType ?? '',
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
          _stagedCursors[cursorKey] = nextCursor;
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
      final response = await _get('/api/v1/sync/meta/$entityType/$entityId');

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
    throw _failureFromBody(response);
  }

  AppFailure _failureFromBody(http.Response response) {
    if (_authClient != null) {
      return _authClient.mapFailure(response);
    }
    if (response.statusCode == 429) {
      final retryHeader = response.headers['retry-after'];
      final retryAfter = retryHeader != null ? int.tryParse(retryHeader) : null;
      return RateLimitFailure.withRetryAfter(retryAfterSeconds: retryAfter);
    }
    if (response.statusCode == 422) {
      return const ValidationFailure();
    }
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
              serverVersion: (details['server_version'] as num?)?.toInt() ?? 0,
              clientBaseVersion: (details['client_base_version'] as num?)?.toInt() ?? 0,
              serverRecord: details['server_record'] is Map
                  ? Map<String, dynamic>.from(details['server_record'] as Map)
                  : null,
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
    } catch (_) {}
    if (response.statusCode == 401) {
      return const AuthenticationFailure();
    }
    if (response.statusCode == 403) {
      return const AuthorizationFailure();
    }
    if (response.statusCode == 422) {
      return const ValidationFailure();
    }
    if (response.statusCode == 429) {
      final retryHeader = response.headers['retry-after'];
      final retryAfter = retryHeader != null ? int.tryParse(retryHeader) : null;
      return RateLimitFailure.withRetryAfter(retryAfterSeconds: retryAfter);
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
          serverVersion: (details['server_version'] as num?)?.toInt() ?? 0,
          clientBaseVersion: (details['client_base_version'] as num?)?.toInt() ?? 0,
          serverRecord: details['server_record'] is Map
              ? Map<String, dynamic>.from(details['server_record'] as Map)
              : null,
        );
      }
    } catch (_) {}
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

  void _calibrate(Map<String, dynamic> map) {
    final serverTimeStr = map['server_time'] as String?;
    if (serverTimeStr != null) {
      final serverTime = DateTime.tryParse(serverTimeStr)?.toUtc();
      if (serverTime != null) {
        _clock?.setCheckpoint(
          serverTime: serverTime,
          localWallClock: DateTime.now().toUtc(),
        );
      }
    }
  }
}
