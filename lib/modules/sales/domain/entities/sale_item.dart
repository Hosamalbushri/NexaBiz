import 'discount_type.dart';
import '../services/sale_quantity_math.dart';

/// Line on a sale — references a product by uuid with snapshot fields.
class SaleItem {
  const SaleItem({
    required this.id,
    required this.uuid,
    required this.saleUuid,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.mainQuantity,
    required this.subQuantity,
    required this.packSize,
    required this.unitPrice,
    required this.baseUnitPrice,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxAmount,
    required this.subtotal,
    required this.total,
    required this.lineOrder,
    this.barcode,
  });

  final int id;
  final String uuid;
  final String saleUuid;

  /// Product.uuid (opaque FK — Sales does not import Inventory).
  final String productId;

  final String productName;
  final String productCode;
  final String? barcode;

  /// Effective billing quantity (`main + sub / packSize`).
  final double quantity;

  final double mainQuantity;
  final double subQuantity;

  /// Pieces per main unit (snapshot from catalog).
  final int packSize;

  /// Unit price in the sale currency.
  final double unitPrice;

  /// Catalog unit price in the company base currency.
  final double baseUnitPrice;
  final DiscountType discountType;

  /// Raw discount input (fixed amount or percentage, depending on [discountType]).
  final double discountValue;

  /// Resolved discount money amount applied to this line.
  final double discountAmount;
  final double taxAmount;

  /// qty × unitPrice before line discount.
  final double subtotal;

  /// Line total after line discount (before sale-level discount/tax share).
  final double total;
  final int lineOrder;

  SaleItem copyWith({
    int? id,
    String? uuid,
    String? saleUuid,
    String? productId,
    String? productName,
    String? productCode,
    String? barcode,
    bool clearBarcode = false,
    double? quantity,
    double? mainQuantity,
    double? subQuantity,
    int? packSize,
    double? unitPrice,
    double? baseUnitPrice,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxAmount,
    double? subtotal,
    double? total,
    int? lineOrder,
  }) {
    return SaleItem(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      saleUuid: saleUuid ?? this.saleUuid,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      quantity: quantity ?? this.quantity,
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      packSize: packSize ?? this.packSize,
      unitPrice: unitPrice ?? this.unitPrice,
      baseUnitPrice: baseUnitPrice ?? this.baseUnitPrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      lineOrder: lineOrder ?? this.lineOrder,
    );
  }
}

/// Mutable line draft used while composing a sale in the UI / use cases.
class SaleItemDraft {
  const SaleItemDraft({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitPrice,
    required this.baseUnitPrice,
    this.mainQuantity = 1,
    this.subQuantity = 0,
    this.packSize = 1,
    this.barcode,
    this.discountType = DiscountType.fixed,
    this.discountValue = 0,
    this.lineUuid,
  });

  final String? lineUuid;
  final String productId;
  final String productName;
  final String productCode;
  final String? barcode;
  final double mainQuantity;
  final double subQuantity;
  final int packSize;

  /// Unit price in the current sale currency.
  final double unitPrice;

  /// Catalog price in company base currency.
  final double baseUnitPrice;
  final DiscountType discountType;
  final double discountValue;

  /// Effective billing quantity in main-unit terms.
  double get quantity => SaleQuantityMath.effective(
    mainQuantity: mainQuantity,
    subQuantity: subQuantity,
    packSize: packSize,
  );

  /// Builds a draft with pack roll-up applied to main/sub (use on save).
  factory SaleItemDraft.normalized({
    required String productId,
    required String productName,
    required String productCode,
    required double unitPrice,
    required double baseUnitPrice,
    double mainQuantity = 1,
    double subQuantity = 0,
    int packSize = 1,
    String? barcode,
    DiscountType discountType = DiscountType.fixed,
    double discountValue = 0,
    String? lineUuid,
  }) {
    final normalized = SaleQuantityMath.normalize(
      mainQuantity: mainQuantity,
      subQuantity: subQuantity,
      packSize: packSize,
    );
    return SaleItemDraft(
      lineUuid: lineUuid,
      productId: productId,
      productName: productName,
      productCode: productCode,
      barcode: barcode,
      mainQuantity: normalized.mainQuantity,
      subQuantity: normalized.subQuantity,
      packSize: SaleQuantityMath.normalizePackSize(packSize),
      unitPrice: unitPrice,
      baseUnitPrice: baseUnitPrice,
      discountType: discountType,
      discountValue: discountValue,
    );
  }

  /// Rolls sub packs into main (call on persist, not while editing).
  SaleItemDraft withNormalizedQuantities() {
    final normalized = SaleQuantityMath.normalize(
      mainQuantity: mainQuantity,
      subQuantity: subQuantity,
      packSize: packSize,
    );
    return SaleItemDraft(
      lineUuid: lineUuid,
      productId: productId,
      productName: productName,
      productCode: productCode,
      barcode: barcode,
      mainQuantity: normalized.mainQuantity,
      subQuantity: normalized.subQuantity,
      packSize: SaleQuantityMath.normalizePackSize(packSize),
      unitPrice: unitPrice,
      baseUnitPrice: baseUnitPrice,
      discountType: discountType,
      discountValue: discountValue,
    );
  }

  /// UI edits — does not roll sub into main (that happens on save).
  SaleItemDraft copyWith({
    String? lineUuid,
    String? productId,
    String? productName,
    String? productCode,
    String? barcode,
    bool clearBarcode = false,
    double? mainQuantity,
    double? subQuantity,
    int? packSize,
    double? unitPrice,
    double? baseUnitPrice,
    DiscountType? discountType,
    double? discountValue,
  }) {
    return SaleItemDraft(
      lineUuid: lineUuid ?? this.lineUuid,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      packSize: SaleQuantityMath.normalizePackSize(packSize ?? this.packSize),
      unitPrice: unitPrice ?? this.unitPrice,
      baseUnitPrice: baseUnitPrice ?? this.baseUnitPrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}
