/// Offline synchronization handler for Purchases module.
class PurchasesSyncHandler {
  final String module = 'purchases';

  Future<void> pushOutboxChanges(String companyId) async {
    // Process local outbox mutations for suppliers and purchase invoices
  }

  Future<void> pullIncrementalSync(String companyId) async {
    // Process remote server delta sync for suppliers and purchase invoices
  }
}
