/// Subject type classification (Customer, Supplier, etc.).
enum AccountingSubjectType {
  customer,
  supplier,
  other;

  static AccountingSubjectType fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'CUSTOMER':
        return AccountingSubjectType.customer;
      case 'SUPPLIER':
        return AccountingSubjectType.supplier;
      default:
        return AccountingSubjectType.other;
    }
  }

  String toDbValue() => name.toUpperCase();
}

/// Standalone Financial Accounting Subject entity model.
class AccountingSubject {
  final String id;
  final String companyId;
  final AccountingSubjectType subjectType;
  final String name;
  final String code;
  final String primaryAccountId;
  final bool isActive;

  const AccountingSubject({
    required this.id,
    required this.companyId,
    required this.subjectType,
    required this.name,
    required this.code,
    required this.primaryAccountId,
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AccountingSubject &&
            id == other.id &&
            companyId == other.companyId);
  }

  @override
  int get hashCode => Object.hash(id, companyId);

  @override
  String toString() => '[$subjectType] $code - $name';
}
