/// Lifecycle of an accounting period.
enum AccountingPeriodStatus {
  closed,
  open,
  closing,
  reopened;

  String get storageValue => name;

  static AccountingPeriodStatus fromStorage(String raw) {
    return AccountingPeriodStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AccountingPeriodStatus.closed,
    );
  }

  bool get allowsPosting =>
      this == AccountingPeriodStatus.open ||
      this == AccountingPeriodStatus.reopened;
}

/// Fiscal year lifecycle.
enum FiscalYearStatus {
  open,
  closed;

  String get storageValue => name;

  static FiscalYearStatus fromStorage(String raw) {
    return FiscalYearStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => FiscalYearStatus.open,
    );
  }
}

/// How periods are generated within a fiscal year.
enum PeriodFrequency {
  monthly;

  String get storageValue => name;

  static PeriodFrequency fromStorage(String raw) {
    return PeriodFrequency.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => PeriodFrequency.monthly,
    );
  }
}

/// Status of a period closing attempt.
enum PeriodClosingStatus {
  completed,
  failed;

  String get storageValue => name;

  static PeriodClosingStatus fromStorage(String raw) {
    return PeriodClosingStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => PeriodClosingStatus.failed,
    );
  }
}
