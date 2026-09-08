/// Purchases adapter for shared SyncManager.
class PurchasesSyncHandlers {
  final String entityType = 'purchase_invoice';

  Future<void> evaluateConflict() async {}
  Future<void> upload() async {}
  Future<void> pull() async {}
  Future<void> applyRemoteChange() async {}
  Future<void> markLocalSynced() async {}
  Future<void> markLocalConflict() async {}
}
