import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';

abstract class InventoryDependencyDetector {
  /// Finds all downstream posted documents that depend on the given [document].
  /// Returns the dependent documents ordered in reverse chronological order (newest first).
  /// If empty, no active downstream posted documents depend on this document, so it can be safely unposted.
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  });
}
