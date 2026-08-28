import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';

abstract class InventoryAccountingPoster {
  /// Posts or updates corresponding accounting journal entries when an inventory document is saved or posted.
  /// If [isPosted] is true, entry status is set to posted. If false, entry status is set to draft.
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  });

  /// Updates journal entry posting status when document status changes (e.g. unposting).
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  });

  /// Reverses/deletes corresponding accounting journal entries when an inventory document is unposted or deleted.
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  });
}
