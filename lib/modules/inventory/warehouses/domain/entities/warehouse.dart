import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

class Warehouse {
  Warehouse({
    required this.id,
    required this.code,
    required this.name,
    this.isDefault = false,
    this.isActive = true,
    this.address,
    this.phone,
    this.managerName,
    this.costValuationMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.version = 1,
    this.companyId,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String code;
  final String name;
  final bool isDefault;
  final bool isActive;
  final String? address;
  final String? phone;
  final String? managerName;

  /// Cost Valuation Method Override: Null = inherit from System Default.
  final CostValuationMethod? costValuationMethod;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? companyId;
  final DateTime? deletedAt;

  Warehouse copyWith({
    String? id,
    String? code,
    String? name,
    bool? isDefault,
    bool? isActive,
    String? address,
    String? phone,
    String? managerName,
    CostValuationMethod? costValuationMethod,
    bool clearCostValuationMethod = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? companyId,
    DateTime? deletedAt,
  }) {
    return Warehouse(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      managerName: managerName ?? this.managerName,
      costValuationMethod: clearCostValuationMethod
          ? null
          : (costValuationMethod ?? this.costValuationMethod),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
