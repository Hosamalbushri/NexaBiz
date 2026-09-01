enum EntitlementTier {
  free,
  premium,
  trial,
  enterprise,
}

enum EntitlementStatus {
  active,
  expired,
  grace,
  cancelled,
}

enum EntitlementCapability {
  sync,
  cloudBackup,
  multiDevice,
  advancedReports,
  multiBranch,
  teamUsers,
  cloudStorage,
}

enum EntitlementSource {
  localDefault,
  cachedServer,
  activeServer,
}

/// Domain entity representing a company's purchased capabilities and subscription status.
class Entitlement {
  const Entitlement({
    required this.companyId,
    required this.tier,
    required this.status,
    required this.capabilities,
    required this.source,
    required this.lastVerifiedAt,
    this.planId = 'plan_free',
    this.packageCodes = const {},
    this.limits = const {},
    this.usage = const {},
    this.validFrom,
    this.validUntil,
    this.graceUntil,
  });

  final String companyId;
  final String planId;
  final EntitlementTier tier;
  final EntitlementStatus status;
  final Set<EntitlementCapability> capabilities;
  final Set<String> packageCodes;
  final Map<String, int> limits;
  final Map<String, int> usage;
  final EntitlementSource source;
  final DateTime lastVerifiedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? graceUntil;

  /// Returns whether the entitlement is active (either actively valid or in grace period).
  bool get isActive =>
      status == EntitlementStatus.active || status == EntitlementStatus.grace;

  /// Returns true if this entitlement grants the specified [capability].
  bool hasCapability(EntitlementCapability capability) {
    if (!isActive) {
      return false;
    }
    return capabilities.contains(capability);
  }

  /// Returns true if usage has not exceeded configured quota limit for [meterKey].
  bool hasQuotaRemaining(String meterKey, [int requested = 1]) {
    final limit = limits[meterKey];
    if (limit == null || limit <= 0) return true; // Unlimited
    final current = usage[meterKey] ?? 0;
    return (current + requested) <= limit;
  }

  /// Active commercial enterprise entitlement for a company.
  factory Entitlement.freeLocal(String companyId) {
    return Entitlement(
      companyId: companyId,
      planId: 'plan_business_commercial',
      tier: EntitlementTier.enterprise,
      status: EntitlementStatus.active,
      capabilities: const {
        EntitlementCapability.cloudBackup,
        EntitlementCapability.multiDevice,
        EntitlementCapability.advancedReports,
        EntitlementCapability.multiBranch,
        EntitlementCapability.teamUsers,
        EntitlementCapability.cloudStorage,
      },
      packageCodes: const {
        'commercial_suite',
        'multi_device',
        'multi_branch',
        'advanced_reports',
        'cloud_backup',
        'team_users',
        'accounting',
        'sales',
        'inventory',
        'purchases',
        'customers',
        'reports',
        'receipts_payments',
      },
      limits: const {
        'max_devices': 99,
        'max_users': 99,
      },
      usage: const {
        'active_devices': 1,
        'active_users': 1,
      },
      source: EntitlementSource.localDefault,
      lastVerifiedAt: DateTime.now().toUtc(),
    );
  }

  /// Active Premium entitlement for a company.
  factory Entitlement.premiumActive(
    String companyId, {
    String? planId,
    DateTime? validUntil,
    DateTime? graceUntil,
    Set<EntitlementCapability>? capabilities,
    Set<String>? packageCodes,
    Map<String, int>? limits,
    Map<String, int>? usage,
  }) {
    return Entitlement(
      companyId: companyId,
      planId: planId ?? 'plan_starter',
      tier: EntitlementTier.premium,
      status: EntitlementStatus.active,
      capabilities: capabilities ??
          const {
            EntitlementCapability.sync,
            EntitlementCapability.cloudBackup,
            EntitlementCapability.multiDevice,
            EntitlementCapability.advancedReports,
            EntitlementCapability.teamUsers,
          },
      packageCodes: packageCodes ?? const {'cloud_sync'},
      limits: limits ?? const {'max_devices': 5},
      usage: usage ?? const {'active_devices': 1},
      source: EntitlementSource.activeServer,
      lastVerifiedAt: DateTime.now().toUtc(),
      validFrom: DateTime.now().toUtc(),
      validUntil: validUntil,
      graceUntil: graceUntil,
    );
  }

  /// Expired entitlement state.
  factory Entitlement.expired(
    String companyId, {
    required EntitlementTier tier,
    DateTime? validUntil,
  }) {
    return Entitlement(
      companyId: companyId,
      planId: 'plan_expired',
      tier: tier,
      status: EntitlementStatus.expired,
      capabilities: const {},
      packageCodes: const {},
      limits: const {},
      usage: const {},
      source: EntitlementSource.cachedServer,
      lastVerifiedAt: DateTime.now().toUtc(),
      validUntil: validUntil,
    );
  }

  Entitlement copyWith({
    String? companyId,
    String? planId,
    EntitlementTier? tier,
    EntitlementStatus? status,
    Set<EntitlementCapability>? capabilities,
    Set<String>? packageCodes,
    Map<String, int>? limits,
    Map<String, int>? usage,
    EntitlementSource? source,
    DateTime? lastVerifiedAt,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? graceUntil,
  }) {
    return Entitlement(
      companyId: companyId ?? this.companyId,
      planId: planId ?? this.planId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      packageCodes: packageCodes ?? this.packageCodes,
      limits: limits ?? this.limits,
      usage: usage ?? this.usage,
      source: source ?? this.source,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      graceUntil: graceUntil ?? this.graceUntil,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'planId': planId,
        'tier': tier.name,
        'status': status.name,
        'capabilities': capabilities.map((c) => c.name).toList(),
        'packageCodes': packageCodes.toList(),
        'limits': limits,
        'usage': usage,
        'source': source.name,
        'lastVerifiedAt': lastVerifiedAt.toIso8601String(),
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'graceUntil': graceUntil?.toIso8601String(),
      };

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    final capList = json['capabilities'] as List? ?? [];
    final pkgList = json['package_codes'] ?? json['packageCodes'] as List? ?? [];
    final rawLimits = json['limits'] as Map? ?? {};
    final rawUsage = json['usage'] as Map? ?? {};

    final parsedLimits = <String, int>{};
    rawLimits.forEach((key, val) {
      if (key is String && val is num) {
        parsedLimits[key] = val.toInt();
      }
    });

    final parsedUsage = <String, int>{};
    rawUsage.forEach((key, val) {
      if (key is String && val is num) {
        parsedUsage[key] = val.toInt();
      }
    });

    final companyId = json['companyId'] ?? json['company_id'] as String? ?? '';
    final planId = json['planId'] ?? json['plan_id'] as String? ?? 'plan_free';

    return Entitlement(
      companyId: companyId,
      planId: planId,
      tier: EntitlementTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () {
          final t = (json['tier'] as String?)?.toLowerCase();
          if (t == 'business' || t == 'starter' || t == 'commercial' || t == 'premium') {
            return EntitlementTier.premium;
          }
          return EntitlementTier.free;
        },
      ),
      status: EntitlementStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EntitlementStatus.active,
      ),
      capabilities: {
        for (final item in capList)
          if (item is String)
            EntitlementCapability.values.firstWhere(
              (c) => c.name == item,
              orElse: () => EntitlementCapability.sync,
            ),
      },
      packageCodes: {
        for (final item in pkgList)
          if (item is String) item,
      },
      limits: parsedLimits,
      usage: parsedUsage,
      source: EntitlementSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => EntitlementSource.localDefault,
      ),
      lastVerifiedAt: DateTime.tryParse(json['lastVerifiedAt'] ?? json['verified_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      validFrom: json['validFrom'] != null || json['valid_from'] != null
          ? DateTime.tryParse((json['validFrom'] ?? json['valid_from']) as String)
          : null,
      validUntil: json['validUntil'] != null || json['valid_until'] != null
          ? DateTime.tryParse((json['validUntil'] ?? json['valid_until']) as String)
          : null,
      graceUntil: json['graceUntil'] != null || json['grace_until'] != null
          ? DateTime.tryParse((json['graceUntil'] ?? json['grace_until']) as String)
          : null,
    );
  }
}
