import 'package:equatable/equatable.dart';

/// Structured context dimensions for dynamic accounting determination.
class DeterminationContext extends Equatable {
  const DeterminationContext({
    required this.companyId,
    required this.transactionDate,
    this.branchId,
    this.warehouseId,
    this.customerId,
    this.customerGroupId,
    this.supplierId,
    this.supplierGroupId,
    this.productId,
    this.productCategoryId,
  });

  final String companyId;
  final DateTime transactionDate;
  final String? branchId;
  final String? warehouseId;
  final String? customerId;
  final String? customerGroupId;
  final String? supplierId;
  final String? supplierGroupId;
  final String? productId;
  final String? productCategoryId;

  String? get partyId => customerId ?? supplierId;
  String? get partyGroupId => customerGroupId ?? supplierGroupId;

  @override
  List<Object?> get props => [
        companyId,
        transactionDate,
        branchId,
        warehouseId,
        customerId,
        customerGroupId,
        supplierId,
        supplierGroupId,
        productId,
        productCategoryId,
      ];
}
