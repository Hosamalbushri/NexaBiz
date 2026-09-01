import 'package:flutter/foundation.dart';
import '../../../accounting/shared/domain/services/account_mapping_resolver.dart';

/// Company-scoped accounting configuration mapping core system roles to CoA accounts.
@immutable
class CompanyAccountingConfig {
  const CompanyAccountingConfig({
    required this.companyId,
    required this.accountMappings,
    this.updatedAt,
  });

  final String companyId;

  /// Role -> Account Code or UUID mapping (e.g. AccountRole.inventory -> '1230').
  final Map<AccountRole, String> accountMappings;
  final DateTime? updatedAt;

  /// Core required roles for inventory-accounting integration.
  static const requiredRoles = <AccountRole>[
    AccountRole.inventory,
    AccountRole.cogs,
    AccountRole.revenue,
    AccountRole.receivable,
    AccountRole.payable,
    AccountRole.cash,
    AccountRole.adjustment,
    AccountRole.fxGainLoss,
  ];

  /// Returns true if all required account roles are assigned non-empty targets.
  bool get isComplete {
    for (final role in requiredRoles) {
      final value = accountMappings[role]?.trim();
      if (value == null || value.isEmpty) {
        return false;
      }
    }
    return true;
  }

  CompanyAccountingConfig copyWith({
    String? companyId,
    Map<AccountRole, String>? accountMappings,
    DateTime? updatedAt,
  }) {
    return CompanyAccountingConfig(
      companyId: companyId ?? this.companyId,
      accountMappings: accountMappings ?? this.accountMappings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'accountMappings': {
      for (final entry in accountMappings.entries) entry.key.name: entry.value,
    },
    'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
  };

  factory CompanyAccountingConfig.fromJson(Map<dynamic, dynamic> json) {
    final rawUpdated = json['updatedAt'];
    final rawMappings = json['accountMappings'];
    final mappings = <AccountRole, String>{};

    if (rawMappings is Map) {
      rawMappings.forEach((key, value) {
        if (key is String && value is String) {
          for (final role in AccountRole.values) {
            if (role.name == key) {
              mappings[role] = value.trim();
              break;
            }
          }
        }
      });
    }

    return CompanyAccountingConfig(
      companyId: (json['companyId'] as String?)?.trim() ?? '',
      accountMappings: mappings,
      updatedAt: rawUpdated is int
          ? DateTime.fromMillisecondsSinceEpoch(rawUpdated, isUtc: true)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAccountingConfig &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          mapEquals(accountMappings, other.accountMappings) &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      companyId.hashCode ^ accountMappings.hashCode ^ updatedAt.hashCode;
}
