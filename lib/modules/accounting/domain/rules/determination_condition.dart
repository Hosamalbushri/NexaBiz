import 'package:equatable/equatable.dart';
import 'determination_context.dart';
import 'specificity_vector.dart';

enum ConditionMatchStatus {
  match,
  noMatch,
  invalidContext,
}

class DeterminationCondition extends Equatable {
  const DeterminationCondition({
    this.companyId,
    this.branchId,
    this.warehouseId,
    this.customerId,
    this.customerGroupId,
    this.supplierId,
    this.supplierGroupId,
    this.productId,
    this.productCategoryId,
  });

  final String? companyId;
  final String? branchId;
  final String? warehouseId;
  final String? customerId;
  final String? customerGroupId;
  final String? supplierId;
  final String? supplierGroupId;
  final String? productId;
  final String? productCategoryId;

  /// Evaluates whether this condition matches the given [context].
  ConditionMatchStatus evaluate(DeterminationContext context) {
    if (companyId != null && companyId != context.companyId) {
      return ConditionMatchStatus.noMatch;
    }
    if (branchId != null && branchId != context.branchId) {
      return ConditionMatchStatus.noMatch;
    }
    if (warehouseId != null && warehouseId != context.warehouseId) {
      return ConditionMatchStatus.noMatch;
    }
    if (customerId != null && customerId != context.customerId) {
      return ConditionMatchStatus.noMatch;
    }
    if (customerGroupId != null && customerGroupId != context.customerGroupId) {
      return ConditionMatchStatus.noMatch;
    }
    if (supplierId != null && supplierId != context.supplierId) {
      return ConditionMatchStatus.noMatch;
    }
    if (supplierGroupId != null && supplierGroupId != context.supplierGroupId) {
      return ConditionMatchStatus.noMatch;
    }
    if (productId != null && productId != context.productId) {
      return ConditionMatchStatus.noMatch;
    }
    if (productCategoryId != null && productCategoryId != context.productCategoryId) {
      return ConditionMatchStatus.noMatch;
    }
    return ConditionMatchStatus.match;
  }

  /// Calculates the [SpecificityVector] of this matched condition.
  SpecificityVector computeSpecificity() {
    return SpecificityVector(
      hasProduct: productId != null && productId!.isNotEmpty,
      hasParty: (customerId != null && customerId!.isNotEmpty) ||
          (supplierId != null && supplierId!.isNotEmpty),
      hasProductCategory:
          productCategoryId != null && productCategoryId!.isNotEmpty,
      hasPartyGroup: (customerGroupId != null && customerGroupId!.isNotEmpty) ||
          (supplierGroupId != null && supplierGroupId!.isNotEmpty),
      hasWarehouse: warehouseId != null && warehouseId!.isNotEmpty,
      hasBranch: branchId != null && branchId!.isNotEmpty,
      hasCompany: companyId != null && companyId!.isNotEmpty,
    );
  }

  @override
  List<Object?> get props => [
        companyId,
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
