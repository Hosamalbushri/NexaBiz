import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';

/// Contract for constructing domain [JournalEntryDraft] objects from inventory business events.
///
/// Implementations resolve required chart accounts and exchange rates without performing database mutations.
abstract class JournalBuilderService {
  /// Builds a journal entry draft for a stock receipt (inbound inventory movement).
  Future<JournalEntryDraft> buildReceiptJournal({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  });

  /// Builds a journal entry draft for a stock issue or adjustment (outbound inventory movement).
  Future<JournalEntryDraft> buildIssueJournal({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  });

  /// Builds a journal entry draft for a value-neutral stock transfer between warehouses.
  Future<JournalEntryDraft> buildTransferJournal({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    bool isPosted = true,
  });

  /// Builds a journal entry draft to reverse an existing journal entry or inventory document.
  Future<JournalEntryDraft> buildReverseJournal({
    required InventoryDocumentRef document,
    JournalEntry? originalEntry,
  });
}
