/// How the platform relates to accounting data ownership.
///
/// The product always runs as [standalone] (local CoA + journals).
/// [integrated] remains only for legacy storage compatibility.
enum AccountingMode {
  standalone,
  integrated;

  String get storageValue => name;

  static AccountingMode fromStorage(String? value) {
    // Integrated mode is retired — always treat as standalone.
    return AccountingMode.standalone;
  }

  bool get isStandalone => true;

  bool get isIntegrated => false;
}
