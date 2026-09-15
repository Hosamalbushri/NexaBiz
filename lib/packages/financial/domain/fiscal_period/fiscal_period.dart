enum FiscalPeriodStatus {
  draft('draft'),
  open('open'),
  closing('closing'),
  closed('closed'),
  reopened('reopened'),
  locked('locked');

  final String value;
  const FiscalPeriodStatus(this.value);

  static FiscalPeriodStatus parse(String value) {
    return FiscalPeriodStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase().trim(),
      orElse: () => throw ArgumentError('Unknown FiscalPeriodStatus: $value'),
    );
  }
}

/// Standalone Financial Package Fiscal Period entity (GATE-08 V4).
class FinancialFiscalPeriod {
  final String id;
  final String companyId;
  final String fiscalYearId;
  final int periodNumber;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final FiscalPeriodStatus status;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final DateTime? reopenedAt;
  final String? reopenReason;

  const FinancialFiscalPeriod({
    required this.id,
    required this.companyId,
    required this.fiscalYearId,
    required this.periodNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.reopenedAt,
    this.reopenReason,
  });

  bool get isDraft => status == FiscalPeriodStatus.draft;
  bool get isOpen => status == FiscalPeriodStatus.open;
  bool get isClosing => status == FiscalPeriodStatus.closing;
  bool get isClosed => status == FiscalPeriodStatus.closed;
  bool get isReopened => status == FiscalPeriodStatus.reopened;
  bool get isLocked => status == FiscalPeriodStatus.locked;

  /// Returns true if period allows normal postings (OPEN or REOPENED).
  bool get isOperational => isOpen || isReopened;

  FinancialFiscalPeriod copyWith({
    String? id,
    String? companyId,
    String? fiscalYearId,
    int? periodNumber,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    FiscalPeriodStatus? status,
    DateTime? openedAt,
    DateTime? closedAt,
    DateTime? reopenedAt,
    String? reopenReason,
  }) {
    return FinancialFiscalPeriod(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      fiscalYearId: fiscalYearId ?? this.fiscalYearId,
      periodNumber: periodNumber ?? this.periodNumber,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      reopenedAt: reopenedAt ?? this.reopenedAt,
      reopenReason: reopenReason ?? this.reopenReason,
    );
  }
}
