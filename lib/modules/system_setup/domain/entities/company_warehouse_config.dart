import 'package:flutter/foundation.dart';

/// Company-scoped warehouse configuration.
@immutable
class CompanyWarehouseConfig {
  const CompanyWarehouseConfig({
    required this.companyId,
    required this.defaultWarehouseId,
    this.updatedAt,
  });

  final String companyId;

  /// Default warehouse UUID or code assigned for primary stock movements.
  final String defaultWarehouseId;
  final DateTime? updatedAt;

  bool get isValid => defaultWarehouseId.trim().isNotEmpty;

  CompanyWarehouseConfig copyWith({
    String? companyId,
    String? defaultWarehouseId,
    DateTime? updatedAt,
  }) {
    return CompanyWarehouseConfig(
      companyId: companyId ?? this.companyId,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'defaultWarehouseId': defaultWarehouseId,
        'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
      };

  factory CompanyWarehouseConfig.fromJson(Map<dynamic, dynamic> json) {
    final rawUpdated = json['updatedAt'];
    return CompanyWarehouseConfig(
      companyId: (json['companyId'] as String?)?.trim() ?? '',
      defaultWarehouseId: (json['defaultWarehouseId'] as String?)?.trim() ?? '',
      updatedAt: rawUpdated is int
          ? DateTime.fromMillisecondsSinceEpoch(rawUpdated, isUtc: true)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyWarehouseConfig &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          defaultWarehouseId == other.defaultWarehouseId &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      companyId.hashCode ^ defaultWarehouseId.hashCode ^ updatedAt.hashCode;
}
