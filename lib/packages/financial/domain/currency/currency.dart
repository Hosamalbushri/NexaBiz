/// Standalone Currency entity model in Financial Package.
class Currency {
  final String id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String symbol;
  final int decimalPlaces;
  final bool isActive;
  final bool isBaseCurrency;
  final String? companyId;

  const Currency({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbol,
    this.decimalPlaces = 2,
    this.isActive = true,
    this.isBaseCurrency = false,
    this.companyId,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Currency &&
            id == other.id &&
            code.toUpperCase() == other.code.toUpperCase() &&
            companyId == other.companyId);
  }

  @override
  int get hashCode => Object.hash(id, code.toUpperCase(), companyId);

  @override
  String toString() => '$code ($symbol)';
}
