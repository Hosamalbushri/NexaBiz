/// Master product in the inventory catalog (Drift-backed).
class Product {
  const Product({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.packSize,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
  });

  final int id;
  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    int? id,
    String? itemCode,
    String? name,
    String? barcode,
    bool clearBarcode = false,
    int? packSize,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      packSize: packSize ?? this.packSize,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Payload for create / update / upsert (no id / timestamps required).
class ProductDraft {
  const ProductDraft({
    required this.itemCode,
    required this.name,
    required this.packSize,
    required this.price,
    this.barcode,
  });

  final String itemCode;
  final String name;
  final String? barcode;
  final int packSize;
  final double price;
}
