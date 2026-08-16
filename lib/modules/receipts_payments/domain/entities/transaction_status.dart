/// Financial document lifecycle (separate from [SyncStatus]).
enum TransactionStatus {
  unposted,
  posted,
}

extension TransactionStatusX on TransactionStatus {
  String get storageValue => name;

  bool get isEditable => this == TransactionStatus.unposted;

  bool get canPost => this == TransactionStatus.unposted;

  bool get canCancel =>
      this == TransactionStatus.unposted || this == TransactionStatus.posted;

  bool get isPosted => this == TransactionStatus.posted;

  static TransactionStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return TransactionStatus.unposted;
    }
    switch (value) {
      case 'unposted':
      case 'draft':
      case 'pending':
      case 'cancelled':
        return TransactionStatus.unposted;
      case 'posted':
      case 'confirmed':
        return TransactionStatus.posted;
      default:
        return TransactionStatus.unposted;
    }
  }
}
