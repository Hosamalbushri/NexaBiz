import 'package:flutter/foundation.dart';
import '../../../domain/entities/account_role.dart';
import '../../../domain/ports/setup_account_lookup_port.dart';
import 'account_binding_mode.dart';

/// Declarative requirement issued by a business package requesting an account binding.
///
/// A package declares a requirement for a semantic role (e.g. `AccountRole.inventory`),
/// never a hardcoded account number or code.
@immutable
class AccountRequirement {
  const AccountRequirement({
    required this.packageId,
    required this.requirementKey,
    required this.role,
    required this.labelAr,
    required this.labelEn,
    this.descriptionAr,
    this.descriptionEn,
    this.isRequired = true,
    this.bindingMode = AccountBindingMode.exact,
    this.expectedAccountType,
    this.boundAccountUuid,
  });

  final String packageId;
  final String requirementKey;
  final AccountRole role;
  final String labelAr;
  final String labelEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final bool isRequired;
  final AccountBindingMode bindingMode;
  final SetupAccountType? expectedAccountType;
  final String? boundAccountUuid;

  /// Returns a copy of this requirement with an updated bound account UUID.
  AccountRequirement withBoundAccountUuid(String? accountUuid) {
    return AccountRequirement(
      packageId: packageId,
      requirementKey: requirementKey,
      role: role,
      labelAr: labelAr,
      labelEn: labelEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      isRequired: isRequired,
      bindingMode: bindingMode,
      expectedAccountType: expectedAccountType,
      boundAccountUuid: accountUuid,
    );
  }

  String label(String languageCode) {
    if (languageCode == 'ar') {
      return labelAr;
    }
    return labelEn;
  }

  String? description(String languageCode) {
    if (languageCode == 'ar') {
      return descriptionAr;
    }
    return descriptionEn;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountRequirement &&
          runtimeType == other.runtimeType &&
          packageId == other.packageId &&
          requirementKey == other.requirementKey &&
          role == other.role &&
          labelAr == other.labelAr &&
          labelEn == other.labelEn &&
          descriptionAr == other.descriptionAr &&
          descriptionEn == other.descriptionEn &&
          isRequired == other.isRequired &&
          bindingMode == other.bindingMode &&
          expectedAccountType == other.expectedAccountType &&
          boundAccountUuid == other.boundAccountUuid;

  @override
  int get hashCode =>
      packageId.hashCode ^
      requirementKey.hashCode ^
      role.hashCode ^
      labelAr.hashCode ^
      labelEn.hashCode ^
      descriptionAr.hashCode ^
      descriptionEn.hashCode ^
      isRequired.hashCode ^
      bindingMode.hashCode ^
      expectedAccountType.hashCode ^
      boundAccountUuid.hashCode;
}

