import 'package:flutter/foundation.dart';

/// Authoritative initialization state for a company.
@immutable
class CompanyInitializationState {
  const CompanyInitializationState({
    required this.companyId,
    this.companyCreated = false,
    this.inventoryCurrencyConfigured = false,
    this.accountingConfigured = false,
    this.warehouseConfigured = false,
    this.inventorySettingsConfigured = false,
    this.initializationCompleted = false,
    this.updatedAt,
  });

  final String companyId;
  final bool companyCreated;
  final bool inventoryCurrencyConfigured;
  final bool accountingConfigured;
  final bool warehouseConfigured;
  final bool inventorySettingsConfigured;
  final bool initializationCompleted;
  final DateTime? updatedAt;

  /// Returns true only if all required sub-configurations are complete.
  bool get isFullyConfigured =>
      companyCreated &&
      inventoryCurrencyConfigured &&
      accountingConfigured &&
      warehouseConfigured &&
      inventorySettingsConfigured &&
      initializationCompleted;

  CompanyInitializationState copyWith({
    String? companyId,
    bool? companyCreated,
    bool? inventoryCurrencyConfigured,
    bool? accountingConfigured,
    bool? warehouseConfigured,
    bool? inventorySettingsConfigured,
    bool? initializationCompleted,
    DateTime? updatedAt,
  }) {
    return CompanyInitializationState(
      companyId: companyId ?? this.companyId,
      companyCreated: companyCreated ?? this.companyCreated,
      inventoryCurrencyConfigured:
          inventoryCurrencyConfigured ?? this.inventoryCurrencyConfigured,
      accountingConfigured: accountingConfigured ?? this.accountingConfigured,
      warehouseConfigured: warehouseConfigured ?? this.warehouseConfigured,
      inventorySettingsConfigured:
          inventorySettingsConfigured ?? this.inventorySettingsConfigured,
      initializationCompleted:
          initializationCompleted ?? this.initializationCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'companyCreated': companyCreated,
        'inventoryCurrencyConfigured': inventoryCurrencyConfigured,
        'accountingConfigured': accountingConfigured,
        'warehouseConfigured': warehouseConfigured,
        'inventorySettingsConfigured': inventorySettingsConfigured,
        'initializationCompleted': initializationCompleted,
        'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
      };

  factory CompanyInitializationState.fromJson(Map<dynamic, dynamic> json) {
    final rawUpdated = json['updatedAt'];
    return CompanyInitializationState(
      companyId: (json['companyId'] as String?)?.trim() ?? '',
      companyCreated: json['companyCreated'] == true,
      inventoryCurrencyConfigured: json['inventoryCurrencyConfigured'] == true,
      accountingConfigured: json['accountingConfigured'] == true,
      warehouseConfigured: json['warehouseConfigured'] == true,
      inventorySettingsConfigured: json['inventorySettingsConfigured'] == true,
      initializationCompleted: json['initializationCompleted'] == true,
      updatedAt: rawUpdated is int
          ? DateTime.fromMillisecondsSinceEpoch(rawUpdated, isUtc: true)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyInitializationState &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          companyCreated == other.companyCreated &&
          inventoryCurrencyConfigured == other.inventoryCurrencyConfigured &&
          accountingConfigured == other.accountingConfigured &&
          warehouseConfigured == other.warehouseConfigured &&
          inventorySettingsConfigured == other.inventorySettingsConfigured &&
          initializationCompleted == other.initializationCompleted &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      companyId.hashCode ^
      companyCreated.hashCode ^
      inventoryCurrencyConfigured.hashCode ^
      accountingConfigured.hashCode ^
      warehouseConfigured.hashCode ^
      inventorySettingsConfigured.hashCode ^
      initializationCompleted.hashCode ^
      updatedAt.hashCode;
}
