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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      companyId: companyId ?? this.companyId,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
