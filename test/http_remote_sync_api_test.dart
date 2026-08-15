import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/http_remote_sync_api.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_status.dart';

void main() {
  const config = SyncApiConfig(
    baseUrl: 'http://example.test',
    apiToken: 'test-token',
    companyId: '00000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-8000-000000000002',
    deviceId: '00000000-0000-4000-8000-000000000003',
  );

  test('push maps success ack', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/sync/push');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode({
          'entity_id': '11111111-1111-4111-8111-111111111111',
          'remote_version': 1,
          'remote_updated_at': '2026-08-14T12:00:00Z',
          'server_payload': {'name': 'Ahmed'},
          'status': 'success',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = HttpRemoteSyncApi(config: config, client: client);
    final ack = await api.push(
      entityType: 'customer',
      operation: SyncOperation(
        id: '22222222-2222-4222-8222-222222222222',
        entityType: 'customer',
        entityId: '11111111-1111-4111-8111-111111111111',
        type: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: const {'name': 'Ahmed'},
        createdAt: DateTime.utc(2026, 8, 14),
        updatedAt: DateTime.utc(2026, 8, 14),
      ),
    );

    expect(ack.remoteVersion, 1);
    expect(ack.serverPayload?['name'], 'Ahmed');
  });

  test('push maps 409 to SyncConflictFailure', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': {
            'code': 'conflict',
            'message': 'Remote version 5 > base 3',
            'details': {
              'status': 'conflict',
              'entity_type': 'customer',
              'entity_id': '11111111-1111-4111-8111-111111111111',
              'server_version': 5,
              'client_base_version': 3,
              'server_record': {'name': 'Server'},
            },
          },
        }),
        409,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = HttpRemoteSyncApi(config: config, client: client);
    expect(
      () => api.push(
        entityType: 'customer',
        operation: SyncOperation(
          id: '22222222-2222-4222-8222-222222222222',
          entityType: 'customer',
          entityId: '11111111-1111-4111-8111-111111111111',
          type: SyncOperationType.update,
          status: SyncStatus.pending,
          payload: const {'name': 'Local'},
          createdAt: DateTime.utc(2026, 8, 14),
          updatedAt: DateTime.utc(2026, 8, 14),
          baseVersion: 3,
        ),
      ),
      throwsA(isA<SyncConflictFailure>()),
    );
  });

  test('pull uses cursor and maps changes', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/sync/pull');
      expect(request.url.queryParameters['entity_type'], 'customer');
      expect(request.url.queryParameters['cursor'], '0');
      return http.Response(
        jsonEncode({
          'changes': [
            {
              'entity_id': '11111111-1111-4111-8111-111111111111',
              'entity_type': 'customer',
              'version': 1,
              'updated_at': '2026-08-14T12:00:00Z',
              'payload': {'name': 'Ahmed'},
              'deleted': false,
              'sequence': 10,
            },
          ],
          'next_cursor': 10,
          'has_more': false,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = HttpRemoteSyncApi(config: config, client: client);
    final changes = await api.pull(entityType: 'customer');
    expect(changes, hasLength(1));
    expect(changes.first.entityId, '11111111-1111-4111-8111-111111111111');
    expect(changes.first.payload['name'], 'Ahmed');
  });
}
