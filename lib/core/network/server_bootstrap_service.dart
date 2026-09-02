import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_error_domain.dart';

/// Client DTO for `GET /api/v1/bootstrap` response.
class ServerBootstrapStatus {
  const ServerBootstrapStatus({
    required this.initialized,
    required this.companyId,
    required this.companyName,
    required this.version,
    required this.takenAt,
    required this.snapshotSequence,
    required this.entityCounts,
  });

  final bool initialized;
  final String companyId;
  final String companyName;
  final int version;
  final DateTime takenAt;
  final int snapshotSequence;
  final Map<String, int> entityCounts;

  int get totalMasterEntities =>
      entityCounts.values.fold(0, (sum, count) => sum + count);
}

/// Client DTO for `GET /api/v1/bootstrap/data` response.
class ServerBootstrapPage {
  const ServerBootstrapPage({
    required this.entityType,
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final String entityType;
  final List<Map<String, dynamic>> items;
  final String? nextCursor;
  final bool hasMore;
}

/// Network service handling server health check and bootstrap snapshot downloads.
class ServerBootstrapService {
  const ServerBootstrapService({this._client});

  final http.Client? _client;

  http.Client get client => _client ?? http.Client();

  /// Validates server reachability and API health probe (`GET /api/v1/health`).
  Future<bool> checkHealth(String baseUrl) async {
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanUrl/api/v1/health');
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        return body?['status'] == 'ok';
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Fetches bootstrap status for the authenticated user/company (`GET /api/v1/bootstrap`).
  Future<ServerBootstrapStatus> fetchStatus({
    required String baseUrl,
    required String token,
  }) async {
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanUrl/api/v1/bootstrap');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw classifyAppError(
          'Authentication failed for server bootstrap check',
          category: AppErrorCategory.authentication,
          severity: FailureSeverity.fatal,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw classifyAppError(
          'Server bootstrap check failed with HTTP status ${response.statusCode}',
          category: AppErrorCategory.server,
          severity: FailureSeverity.recoverable,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? json;

      final initialized = data['initialized'] == true;
      final company = (data['company'] as Map<String, dynamic>?) ?? {};
      final initialization = (data['initialization'] as Map<String, dynamic>?) ?? {};
      final snapshot = (data['snapshot'] as Map<String, dynamic>?) ?? {};
      final countsRaw = (data['counts'] as Map<String, dynamic>?) ?? {};

      final counts = <String, int>{};
      countsRaw.forEach((key, val) {
        if (val is num) {
          counts[key] = val.toInt();
        }
      });

      final takenAtStr = snapshot['taken_at'] as String?;
      final takenAt = takenAtStr != null
          ? DateTime.tryParse(takenAtStr)?.toUtc() ?? DateTime.now().toUtc()
          : DateTime.now().toUtc();

      return ServerBootstrapStatus(
        initialized: initialized,
        companyId: company['id']?.toString() ?? '',
        companyName: company['name']?.toString() ?? '',
        version: (initialization['version'] as num?)?.toInt() ?? 1,
        takenAt: takenAt,
        snapshotSequence: (snapshot['sequence'] as num?)?.toInt() ?? 0,
        entityCounts: counts,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw classifyAppError(e, category: AppErrorCategory.network);
    }
  }

  /// Downloads one page of bootstrap items for a specific [entityType] (`GET /api/v1/bootstrap/data`).
  Future<ServerBootstrapPage> fetchEntityPage({
    required String baseUrl,
    required String token,
    required String entityType,
    required DateTime takenAt,
    String? cursor,
    int limit = 200,
  }) async {
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final queryParams = <String, String>{
      'entity_type': entityType,
      'taken_at': takenAt.toIso8601String(),
      'limit': limit.toString(),
    };
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final uri = Uri.parse('$cleanUrl/api/v1/bootstrap/data')
        .replace(queryParameters: queryParams);
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw classifyAppError(
          'Failed to download bootstrap data for $entityType: status ${response.statusCode}',
          category: AppErrorCategory.network,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (json['data'] as Map<String, dynamic>?) ?? json;

      final itemsRaw = (data['items'] as List<dynamic>?) ?? [];
      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      final nextCursor = data['next_cursor'] as String?;
      final hasMore = data['has_more'] == true;

      return ServerBootstrapPage(
        entityType: entityType,
        items: items,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      throw classifyAppError(e, category: AppErrorCategory.network);
    }
  }
}
