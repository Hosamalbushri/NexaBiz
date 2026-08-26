import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/entities/entitlement.dart';

class CommercialPlan {
  const CommercialPlan({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingInterval,
    required this.isFree,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final double price;
  final String currency;
  final String billingInterval;
  final bool isFree;
  final int sortOrder;

  factory CommercialPlan.fromJson(Map<String, dynamic> json) {
    return CommercialPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0.0).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      billingInterval: json['billing_interval'] as String? ?? 'monthly',
      isFree: json['is_free'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class AddonPackage {
  const AddonPackage({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.description,
    required this.price,
    required this.currency,
    required this.isAddon,
  });

  final String id;
  final String name;
  final String code;
  final String category;
  final String description;
  final double price;
  final String currency;
  final bool isAddon;

  factory AddonPackage.fromJson(Map<String, dynamic> json) {
    return AddonPackage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      category: json['category'] as String? ?? 'core',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0.0).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      isAddon: json['is_addon'] as bool? ?? false,
    );
  }
}

class UsageMeterSummary {
  const UsageMeterSummary({
    required this.meterKey,
    required this.limit,
    required this.used,
    required this.remaining,
  });

  final String meterKey;
  final int limit;
  final int used;
  final int? remaining;

  factory UsageMeterSummary.fromJson(Map<String, dynamic> json) {
    return UsageMeterSummary(
      meterKey: json['meter_key'] as String? ?? '',
      limit: (json['limit'] as num? ?? 0).toInt(),
      used: (json['used'] as num? ?? 0).toInt(),
      remaining: json['remaining'] != null ? (json['remaining'] as num).toInt() : null,
    );
  }
}

abstract class SubscriptionRepository {
  Future<List<CommercialPlan>> fetchPlans();
  Future<List<AddonPackage>> fetchPackages();
  Future<Entitlement> changeSubscription({
    required String companyId,
    required String planId,
    required List<String> packageCodes,
    required String baseUrl,
    required String token,
    String? idempotencyKey,
  });
  Future<List<UsageMeterSummary>> fetchUsage({
    required String companyId,
    required String baseUrl,
    required String token,
  });
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<List<CommercialPlan>> fetchPlans() async {
    // Returns default static fallback if server is unreachable locally
    return const [
      CommercialPlan(
        id: 'plan_free',
        name: 'Free Plan',
        code: 'free',
        description: 'Full local POS & double-entry accounting. 100% offline enabled.',
        price: 0.0,
        currency: 'USD',
        billingInterval: 'forever',
        isFree: true,
        sortOrder: 1,
      ),
      CommercialPlan(
        id: 'plan_starter',
        name: 'Starter Plan',
        code: 'starter',
        description: 'Cloud sync, multi-device access, and automated cloud backup.',
        price: 49.0,
        currency: 'USD',
        billingInterval: 'monthly',
        isFree: false,
        sortOrder: 2,
      ),
      CommercialPlan(
        id: 'plan_business',
        name: 'Business Plan',
        code: 'business',
        description: 'Full cloud suite, multi-branch management, team users, and advanced analytics.',
        price: 99.0,
        currency: 'USD',
        billingInterval: 'monthly',
        isFree: false,
        sortOrder: 3,
      ),
    ];
  }

  @override
  Future<List<AddonPackage>> fetchPackages() async {
    return const [
      AddonPackage(
        id: 'pkg_sync',
        name: 'Cloud Data Synchronization',
        code: 'cloud_sync',
        category: 'core',
        description: 'Real-time multi-device cloud synchronization.',
        price: 29.0,
        currency: 'USD',
        isAddon: false,
      ),
      AddonPackage(
        id: 'pkg_multi_device',
        name: 'Multi-Device Access',
        code: 'multi_device',
        category: 'add_on',
        description: 'Connect multiple active terminal devices.',
        price: 15.0,
        currency: 'USD',
        isAddon: true,
      ),
      AddonPackage(
        id: 'pkg_multi_branch',
        name: 'Multi-Branch Management',
        code: 'multi_branch',
        category: 'add_on',
        description: 'Manage multiple physical branches and transfers.',
        price: 49.0,
        currency: 'USD',
        isAddon: true,
      ),
    ];
  }

  @override
  Future<Entitlement> changeSubscription({
    required String companyId,
    required String planId,
    required List<String> packageCodes,
    required String baseUrl,
    required String token,
    String? idempotencyKey,
  }) async {
    final cleanUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanUrl/api/v1/subscription/change');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Company-Id': companyId,
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      },
      body: jsonEncode({
        'plan_id': planId,
        'packages': packageCodes,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rawEntitlement = body['entitlement'] as Map<String, dynamic>? ?? body;
      return Entitlement.fromJson(rawEntitlement);
    } else {
      throw Exception('Failed to update subscription: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<List<UsageMeterSummary>> fetchUsage({
    required String companyId,
    required String baseUrl,
    required String token,
  }) async {
    try {
      final cleanUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$cleanUrl/api/v1/usage');

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
        final list = body['data'] as List? ?? [];
        return list.map((item) => UsageMeterSummary.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }
}
