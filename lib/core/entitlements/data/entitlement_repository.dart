import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../domain/entities/entitlement.dart';

abstract class EntitlementRepository {
  Future<Entitlement?> getCachedEntitlement(String companyId);

  Future<void> saveCachedEntitlement(Entitlement entitlement);

  Future<Entitlement> fetchRemoteEntitlement({
    required String companyId,
    required String baseUrl,
    required String token,
  });
}

class EntitlementRepositoryImpl implements EntitlementRepository {
  EntitlementRepositoryImpl({
    FlutterSecureStorage? storage,
    http.Client? httpClient,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _httpClient;

  static String _storageKey(String companyId) => 'entitlement_$companyId';

  @override
  Future<Entitlement?> getCachedEntitlement(String companyId) async {
    try {
      final raw = await _storage.read(key: _storageKey(companyId));
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Entitlement.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCachedEntitlement(Entitlement entitlement) async {
    try {
      final raw = jsonEncode(entitlement.toJson());
      await _storage.write(
        key: _storageKey(entitlement.companyId),
        value: raw,
      );
    } catch (_) {
      // Ignored if secure storage write fails offline
    }
  }

  @override
  Future<Entitlement> fetchRemoteEntitlement({
    required String companyId,
    required String baseUrl,
    required String token,
  }) async {
    final cleanUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanUrl/api/v1/entitlements');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Company-Id': companyId,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final remote = Entitlement.fromJson({
        'companyId': companyId,
        ...body,
        'source': EntitlementSource.activeServer.name,
        'lastVerifiedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await saveCachedEntitlement(remote);
      return remote;
    } else {
      throw Exception(
        'Failed to fetch entitlement from server: ${response.statusCode} ${response.body}',
      );
    }
  }
}
