import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_builder_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';

/// Adapter bridging Inventory module accounting requests to Accounting domain services.
class InventoryAccountingPosterAdapter implements InventoryAccountingPoster {
  InventoryAccountingPosterAdapter({
    required JournalPostingService journalPostingService,
    required JournalBuilderService journalBuilder,
    AccountingIntegrationPort? integrationService,
    InitializationGuard? initializationGuard,
  })  : _journalPostingService = journalPostingService,
        _journalBuilder = journalBuilder,
        _integrationService = integrationService,
        _initializationGuard = initializationGuard;

  final JournalPostingService _journalPostingService;
  final JournalBuilderService _journalBuilder;
  final AccountingIntegrationPort? _integrationService;
  final InitializationGuard? _initializationGuard;

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {
    await _initializationGuard?.assertInitialized();
    if (totalAmount <= 0) return;
    if (!isPosted) {
      await reverseAccountingEntry(document: document);
      return;
    }

    // Skip invoices handled by Sales module
    if (document.documentType == InventoryDocumentType.salesInvoice) {
      return;
    }

    if (_integrationService != null) {
      final txnType = switch (document.documentType) {
        InventoryDocumentType.stockReceipt => AccountingTransactionType.stockReceipt,
        InventoryDocumentType.stockTransfer => AccountingTransactionType.stockTransfer,
        _ => AccountingTransactionType.stockIssue,
      };

      final result = await _integrationService!.processOperationalTransaction(
        OperationalAccountingRequest(
          companyId: 'default',
          sourceType: document.documentType.storageValue,
          sourceId: document.documentId,
          transactionType: txnType,
          transactionDate: document.documentDate ?? DateTime.now().toUtc(),
          amount: totalAmount,
          currencyCode: 'YER',
          baseCurrencyCode: 'YER',
          description: 'مستند مخزني ${document.documentId}',
        ),
      );


      if (!result.isSuccess) {
        throw Exception(
          result.failureReason ?? 'فشل الترحيل المحاسبي للمستند المخزني',
        );
      }
      return;
    }

    final JournalEntryDraft draft;
    if (document.documentType == InventoryDocumentType.stockTransfer) {
      draft = await _journalBuilder.buildTransferJournal(
        document: document,
        totalAmount: totalAmount,
        valuationAmount: valuationAmount,
        isPosted: isPosted,
      );
    } else if (document.documentType == InventoryDocumentType.stockReceipt) {
      draft = await _journalBuilder.buildReceiptJournal(
        document: document,
        totalAmount: totalAmount,
        valuationAmount: valuationAmount,
        accountId: accountId,
        isPosted: isPosted,
        useBaseCurrencyForPosting: useBaseCurrencyForPosting,
      );
    } else {
      draft = await _journalBuilder.buildIssueJournal(
        document: document,
        totalAmount: totalAmount,
        valuationAmount: valuationAmount,
        accountId: accountId,
        isPosted: isPosted,
        useBaseCurrencyForPosting: useBaseCurrencyForPosting,
      );
    }

    await _journalPostingService.post(draft);
  }

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;
    final existing = await _journalPostingService.findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );

    if (existing != null && existing.isPosted && !isPosted) {
      throw const JournalException(JournalException.postedImmutable);
    }
  }

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {
    await _initializationGuard?.assertInitialized();
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;

    final existing = await _journalPostingService.findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );

    if (existing != null && existing.isPosted) {
      final reverseDraft = await _journalBuilder.buildReverseJournal(
        document: document,
        originalEntry: existing,
      );
      await _journalPostingService.post(reverseDraft);
      return;
    }

    await _journalPostingService.voidBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }
}

