import 'package:equatable/equatable.dart';

/// Represents the hierarchical specificity of a determination rule match.
///
/// Order of evaluation (from most specific entity match to company default):
/// 1. Specific Product ID
/// 2. Specific Customer / Supplier ID
/// 3. Product Category ID
/// 4. Customer / Supplier Group ID
/// 5. Warehouse ID
/// 6. Branch ID
/// 7. Company ID (Base default)
class SpecificityVector extends Equatable implements Comparable<SpecificityVector> {
  const SpecificityVector({
    this.hasProduct = false,
    this.hasParty = false,
    this.hasProductCategory = false,
    this.hasPartyGroup = false,
    this.hasWarehouse = false,
    this.hasBranch = false,
    this.hasCompany = false,
  });

  final bool hasProduct;
  final bool hasParty;
  final bool hasProductCategory;
  final bool hasPartyGroup;
  final bool hasWarehouse;
  final bool hasBranch;
  final bool hasCompany;

  int get matchedDimensionsCount =>
      (hasProduct ? 1 : 0) +
      (hasParty ? 1 : 0) +
      (hasProductCategory ? 1 : 0) +
      (hasPartyGroup ? 1 : 0) +
      (hasWarehouse ? 1 : 0) +
      (hasBranch ? 1 : 0) +
      (hasCompany ? 1 : 0);

  @override
  int compareTo(SpecificityVector other) {
    if (hasProduct != other.hasProduct) {
      return hasProduct ? 1 : -1;
    }
    if (hasParty != other.hasParty) {
      return hasParty ? 1 : -1;
    }
    if (hasProductCategory != other.hasProductCategory) {
      return hasProductCategory ? 1 : -1;
    }
    if (hasPartyGroup != other.hasPartyGroup) {
      return hasPartyGroup ? 1 : -1;
    }
    if (hasWarehouse != other.hasWarehouse) {
      return hasWarehouse ? 1 : -1;
    }
    if (hasBranch != other.hasBranch) {
      return hasBranch ? 1 : -1;
    }
    if (hasCompany != other.hasCompany) {
      return hasCompany ? 1 : -1;
    }
    return 0;
  }

  @override
  List<Object?> get props => [
        hasProduct,
        hasParty,
        hasProductCategory,
        hasPartyGroup,
        hasWarehouse,
        hasBranch,
        hasCompany,
      ];
}
