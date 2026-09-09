import 'package:equatable/equatable.dart';

/// Item line entry within a Purchase Order or Purchase Invoice.
class PurchaseItem extends Equatable {
  final String id;
  final String productId;
  final String productNameAr;
  final String productNameEn;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double taxAmount;
  final double totalPrice;
  final String? unitOfMeasure;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.productNameAr,
    required this.productNameEn,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.totalPrice,
    this.unitOfMeasure,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    productNameAr,
    productNameEn,
    quantity,
    unitPrice,
    discountAmount,
    taxAmount,
    totalPrice,
    unitOfMeasure,
  ];
}
