import 'package:flutter/foundation.dart';
import 'account_binding_mode.dart';
import 'account_binding_status.dart';

/// Represents a persistent binding between a package requirement and an account UUID.
///
/// Bindings are strictly scoped to a single company context ([companyId]).
/// Permanent references MUST use stable account UUIDs ([accountUuid]), never display names or codes.
@immutable
class AccountBinding {
  const AccountBinding({
    required this.companyId,
    required this.packageId,
    required this.requirementKey,
    required this.accountUuid,
    required this.status,
    this.bindingMode = AccountBindingMode.exact,
    this.boundAt,
  });

  final String companyId;
  final String packageId;
  final String requirementKey;
  final String accountUuid;
  final AccountBindingStatus status;
  final AccountBindingMode bindingMode;
  final DateTime? boundAt;

  AccountBinding copyWith({
    String? companyId,
    String? packageId,
    String? requirementKey,
    String? accountUuid,
    AccountBindingStatus? status,
    AccountBindingMode? bindingMode,
    DateTime? boundAt,
  }) {
    return AccountBinding(
      companyId: companyId ?? this.companyId,
      packageId: packageId ?? this.packageId,
      requirementKey: requirementKey ?? this.requirementKey,
      accountUuid: accountUuid ?? this.accountUuid,
      status: status ?? this.status,
      bindingMode: bindingMode ?? this.bindingMode,
      boundAt: boundAt ?? this.boundAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'packageId': packageId,
        'requirementKey': requirementKey,
        'accountUuid': accountUuid,
        'status': status.name,
        'bindingMode': bindingMode.name,
        'boundAt': boundAt?.toUtc().millisecondsSinceEpoch,
      };

  factory AccountBinding.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String?;
    final status = AccountBindingStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => AccountBindingStatus.unbound,
    );
    final rawBindingMode = json['bindingMode'] as String?;
    final bindingMode = AccountBindingMode.values.firstWhere(
      (b) => b.name == rawBindingMode,
      orElse: () => AccountBindingMode.exact,
    );
    final rawBoundAt = json['boundAt'];
    return AccountBinding(
      companyId: (json['companyId'] as String?)?.trim() ?? '',
      packageId: (json['packageId'] as String?)?.trim() ?? '',
      requirementKey: (json['requirementKey'] as String?)?.trim() ?? '',
      accountUuid: (json['accountUuid'] as String?)?.trim() ?? '',
      status: status,
      bindingMode: bindingMode,
      boundAt: rawBoundAt is int
          ? DateTime.fromMillisecondsSinceEpoch(rawBoundAt, isUtc: true)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountBinding &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          packageId == other.packageId &&
          requirementKey == other.requirementKey &&
          accountUuid == other.accountUuid &&
          status == other.status &&
          bindingMode == other.bindingMode &&
          boundAt == other.boundAt;

  @override
  int get hashCode =>
      companyId.hashCode ^
      packageId.hashCode ^
      requirementKey.hashCode ^
      accountUuid.hashCode ^
      status.hashCode ^
      bindingMode.hashCode ^
      boundAt.hashCode;
}

