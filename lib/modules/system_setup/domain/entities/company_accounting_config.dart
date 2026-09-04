import 'package:flutter/foundation.dart';
import '../../../../core/domain/entities/account_role.dart';
import '../../../../core/setup/domain/entities/account_binding_mode.dart';

/// Defines a targeted account binding rule for a system role.

@immutable
class AccountBindingTarget {
  const AccountBindingTarget({
    required this.mode,
    this.primaryUuid,
    this.parentUuid,
    this.setUuids = const [],
    this.isEnabled = true,
  });

  final AccountBindingMode mode;
  final String? primaryUuid;
  final String? parentUuid;
  final List<String> setUuids;
  final bool isEnabled;

  factory AccountBindingTarget.single(String uuid) => AccountBindingTarget(
        mode: AccountBindingMode.singleAccount,
        primaryUuid: uuid,
      );

  factory AccountBindingTarget.parentScope(String parentUuid) => AccountBindingTarget(
        mode: AccountBindingMode.parentAccountWithDescendants,
        parentUuid: parentUuid,
        primaryUuid: parentUuid,
      );

  factory AccountBindingTarget.set(List<String> setUuids) => AccountBindingTarget(
        mode: AccountBindingMode.accountSet,
        setUuids: setUuids,
      );

  String? get activeUuid {
    switch (mode) {
      case AccountBindingMode.singleAccount:
      case AccountBindingMode.exact:
        return primaryUuid;
      case AccountBindingMode.parentAccountWithDescendants:
      case AccountBindingMode.parent:
        return parentUuid ?? primaryUuid;
      case AccountBindingMode.accountSet:
        return setUuids.isNotEmpty ? setUuids.first : primaryUuid;
    }
  }


  Map<String, dynamic> toJson() => {
        'mode': mode.storageValue,
        'primaryUuid': primaryUuid,
        'parentUuid': parentUuid,
        'setUuids': setUuids,
        'isEnabled': isEnabled,
      };

  factory AccountBindingTarget.fromJson(dynamic json) {
    if (json is String) {
      return AccountBindingTarget.single(json.trim());
    }
    if (json is Map) {
      final modeStr = json['mode'] as String?;
      final mode = AccountBindingMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => AccountBindingMode.singleAccount,
      );
      final rawSet = json['setUuids'];
      final setList = rawSet is List ? rawSet.cast<String>() : <String>[];

      return AccountBindingTarget(
        mode: mode,
        primaryUuid: json['primaryUuid'] as String?,
        parentUuid: json['parentUuid'] as String?,
        setUuids: setList,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
    }
    return const AccountBindingTarget(mode: AccountBindingMode.singleAccount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountBindingTarget &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          primaryUuid == other.primaryUuid &&
          parentUuid == other.parentUuid &&
          listEquals(setUuids, other.setUuids) &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      mode.hashCode ^
      primaryUuid.hashCode ^
      parentUuid.hashCode ^
      setUuids.hashCode ^
      isEnabled.hashCode;
}

/// Company-scoped accounting configuration mapping core system roles to CoA accounts.
@immutable
class CompanyAccountingConfig {
  const CompanyAccountingConfig({
    required this.companyId,
    required this.accountMappings,
    Map<AccountRole, AccountBindingTarget>? bindingTargets,
    this.updatedAt,
  }) : bindingTargets = bindingTargets ?? const {};

  final String companyId;

  /// Legacy role -> Account Code or UUID mapping (e.g. AccountRole.inventory -> '1230').
  final Map<AccountRole, String> accountMappings;

  /// Structured role -> AccountBindingTarget rule mapping.
  final Map<AccountRole, AccountBindingTarget> bindingTargets;

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
      final target = bindingTargets[role];
      final value = target?.activeUuid ?? accountMappings[role]?.trim();
      if (value == null || value.isEmpty) {
        return false;
      }
    }
    return true;
  }

  CompanyAccountingConfig copyWith({
    String? companyId,
    Map<AccountRole, String>? accountMappings,
    Map<AccountRole, AccountBindingTarget>? bindingTargets,
    DateTime? updatedAt,
  }) {
    return CompanyAccountingConfig(
      companyId: companyId ?? this.companyId,
      accountMappings: accountMappings ?? this.accountMappings,
      bindingTargets: bindingTargets ?? this.bindingTargets,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'accountMappings': {
      for (final entry in accountMappings.entries) entry.key.name: entry.value,
    },
    'bindingTargets': {
      for (final entry in bindingTargets.entries) entry.key.name: entry.value.toJson(),
    },
    'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
  };

  factory CompanyAccountingConfig.fromJson(Map<dynamic, dynamic> json) {
    final rawUpdated = json['updatedAt'];
    final rawMappings = json['accountMappings'];
    final rawTargets = json['bindingTargets'];
    final mappings = <AccountRole, String>{};
    final targets = <AccountRole, AccountBindingTarget>{};

    if (rawMappings is Map) {
      rawMappings.forEach((key, value) {
        if (key is String && value is String) {
          for (final role in AccountRole.values) {
            if (role.name == key) {
              mappings[role] = value.trim();
              targets[role] = AccountBindingTarget.single(value.trim());
              break;
            }
          }
        }
      });
    }

    if (rawTargets is Map) {
      rawTargets.forEach((key, value) {
        if (key is String) {
          for (final role in AccountRole.values) {
            if (role.name == key) {
              targets[role] = AccountBindingTarget.fromJson(value);
              if (targets[role]?.activeUuid != null) {
                mappings[role] = targets[role]!.activeUuid!;
              }
              break;
            }
          }
        }
      });
    }

    return CompanyAccountingConfig(
      companyId: (json['companyId'] as String?)?.trim() ?? '',
      accountMappings: mappings,
      bindingTargets: targets,
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
          mapEquals(bindingTargets, other.bindingTargets) &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      companyId.hashCode ^
      accountMappings.hashCode ^
      bindingTargets.hashCode ^
      updatedAt.hashCode;
}

