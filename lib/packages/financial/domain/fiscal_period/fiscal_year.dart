enum FiscalYearStatus {
  draft('draft'),
  open('open'),
  closed('closed'),
  locked('locked');

  final String value;
  const FiscalYearStatus(this.value);

  static FiscalYearStatus parse(String value) {
    return FiscalYearStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase().trim(),
      orElse: () => throw ArgumentError('Unknown FiscalYearStatus: $value'),
    );
  }
}

/// Standalone Financial Package Fiscal Year entity (GATE-08 V4).
class FinancialFiscalYear {
  final String id;
  final String companyId;
  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final FiscalYearStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final String? createdBy;
  final String? closedBy;

  const FinancialFiscalYear({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.createdBy,
    this.closedBy,
  });

  bool get isDraft => status == FiscalYearStatus.draft;
  bool get isOpen => status == FiscalYearStatus.open;
  bool get isClosed => status == FiscalYearStatus.closed;
  bool get isLocked => status == FiscalYearStatus.locked;

  FinancialFiscalYear copyWith({
    String? id,
    String? companyId,
    String? code,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    FiscalYearStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? createdBy,
    String? closedBy,
  }) {
    return FinancialFiscalYear(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      code: code ?? this.code,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      createdBy: createdBy ?? this.createdBy,
      closedBy: closedBy ?? this.closedBy,
    );
  }
}
