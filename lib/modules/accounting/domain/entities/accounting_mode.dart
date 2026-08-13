/// How the platform relates to accounting data ownership.
///
/// - [standalone]: the app owns local accounting master data and future ledger.
/// - [integrated]: the app is an operational interface beside an external ERP;
///   master data may be pulled, and operational docs are posted externally later.
enum AccountingMode {
  standalone,
  integrated;

  String get storageValue => name;

  static AccountingMode fromStorage(String? value) {
    return AccountingMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AccountingMode.standalone,
    );
  }

  bool get isStandalone => this == AccountingMode.standalone;

  bool get isIntegrated => this == AccountingMode.integrated;
}
