import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'accounting_entry_builder.dart';
import 'document_lock_checker.dart';

sealed class OrchestrationResult {
  const OrchestrationResult();
}

class OrchestrationSuccess extends OrchestrationResult {
  const OrchestrationSuccess({
    required this.documentId,
    required this.message,
    this.journalEntryUuid,
  });

  final String documentId;
  final String message;
  final String? journalEntryUuid;
}

class OrchestrationFailure extends OrchestrationResult {
  const OrchestrationFailure({
    required this.documentId,
    required this.reason,
  });

  final String documentId;
  final String reason;
}

class DocumentPostingOrchestrator {
  DocumentPostingOrchestrator({
    required PostingCoordinator postingCoordinator,
    required JournalPostingService journalPostingService,
    required AccountingEntryBuilder entryBuilder,
    DocumentLockChecker lockChecker = const DocumentLockChecker(),
  })  : _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _lockChecker = lockChecker;

  final PostingCoordinator _postingCoordinator;
  final JournalPostingService _journalPostingService;
  final AccountingEntryBuilder _entryBuilder;
  final DocumentLockChecker _lockChecker;

  Future<OrchestrationResult> postReceipt({
    required StockReceipt receipt,
  }) async {
    try {
      _lockChecker.assertCanEdit(
        documentNumber: receipt.receiptNumber,
        status: receipt.status,
      );

      final totalAmount = receipt.totalCost;
      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: receipt.status,
        currencyCode: receipt.currencyCode,
        exchangeRate: receipt.exchangeRate,
      );

      // 1. Post Inventory movements & cost layers first
      final inventoryResult = await _postingCoordinator.post(document: docRef);

      if (inventoryResult is PostStockShortage) {
        return OrchestrationFailure(
          documentId: receipt.id,
          reason: 'نقص في المخزون للمواد المطلوب توريدها',
        );
      } else if (inventoryResult is PostInvalidStatus) {
        return OrchestrationFailure(
          documentId: receipt.id,
          reason: inventoryResult.reason,
        );
      }

      // 2. Build and post Journal Entry after inventory layer creation succeeds
      if (totalAmount > 0) {
        final sourceType = docRef.documentType.storageValue;
        final sourceId = docRef.documentId;

        final existing = await _journalPostingService.findBySource(
          sourceType: sourceType,
          sourceId: sourceId,
        );

        if (existing != null && existing.isPosted) {
          return OrchestrationSuccess(
            documentId: receipt.id,
            journalEntryUuid: existing.uuid,
            message: 'تم ترحيل أمر التوريد والقيود المحاسبية بنجاح',
          );
        }

        await _journalPostingService.voidBySource(
          sourceType: sourceType,
          sourceId: sourceId,
        );

        final draft = await _entryBuilder.buildDraftFromInventoryDocument(
          document: docRef,
          totalAmount: totalAmount,
          offsetAccountId: receipt.accountId ?? receipt.supplier,
          isPosted: true,
        );
        final entry = await _journalPostingService.post(draft);
        return OrchestrationSuccess(
          documentId: receipt.id,
          journalEntryUuid: entry.uuid,
          message: 'تم ترحيل أمر التوريد والقيود المحاسبية بنجاح',
        );
      }

      return OrchestrationSuccess(
        documentId: receipt.id,
        message: 'تم ترحيل أمر التوريد بنجاح',
      );
    } catch (e) {
      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: receipt.status,
        currencyCode: receipt.currencyCode,
        exchangeRate: receipt.exchangeRate,
      );
      try {
        await _postingCoordinator.unpost(document: docRef);
      } catch (_) {
        // Force status compensation if unpost fails during failure recovery
      }
      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );
      return OrchestrationFailure(
        documentId: receipt.id,
        reason: e.toString(),
      );
    }
  }

  Future<OrchestrationResult> postIssue({
    required StockIssue issue,
  }) async {
    try {
      _lockChecker.assertCanEdit(
        documentNumber: issue.issueNumber,
        status: issue.status,
      );

      final docRef = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
        status: issue.status,
        currencyCode: issue.currencyCode,
        exchangeRate: issue.exchangeRate,
      );

      // 1. Post Inventory movements & consume cost layers FIRST
      final inventoryResult = await _postingCoordinator.post(document: docRef);

      if (inventoryResult is PostStockShortage) {
        return OrchestrationFailure(
          documentId: issue.id,
          reason: 'نقص في الكميات المتاحة بالمخزن',
        );
      } else if (inventoryResult is PostInvalidStatus) {
        return OrchestrationFailure(
          documentId: issue.id,
          reason: inventoryResult.reason,
        );
      }

      final calculatedCogsCost = (inventoryResult as PostSuccess).postedValue;

      // 2. Build and post Journal Entry using consumed layer cost in Base Currency
      if (calculatedCogsCost > 0) {
        final sourceType = docRef.documentType.storageValue;
        final sourceId = docRef.documentId;

        final existing = await _journalPostingService.findBySource(
          sourceType: sourceType,
          sourceId: sourceId,
        );

        if (existing != null && existing.isPosted) {
          return OrchestrationSuccess(
            documentId: issue.id,
            journalEntryUuid: existing.uuid,
            message: 'تم ترحيل أمر الصرف والقيود المحاسبية بنجاح',
          );
        }

        await _journalPostingService.voidBySource(
          sourceType: sourceType,
          sourceId: sourceId,
        );

        final draft = await _entryBuilder.buildDraftFromInventoryDocument(
          document: docRef,
          totalAmount: calculatedCogsCost,
          offsetAccountId: issue.accountId ?? issue.destination,
          isPosted: true,
          useBaseCurrencyForCogs: true,
        );
        final entry = await _journalPostingService.post(draft);
        return OrchestrationSuccess(
          documentId: issue.id,
          journalEntryUuid: entry.uuid,
          message: 'تم ترحيل أمر الصرف والقيود المحاسبية بنجاح',
        );
      }

      return OrchestrationSuccess(
        documentId: issue.id,
        message: 'تم ترحيل أمر الصرف بنجاح',
      );
    } catch (e) {
      final docRef = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
        status: issue.status,
        currencyCode: issue.currencyCode,
        exchangeRate: issue.exchangeRate,
      );
      try {
        await _postingCoordinator.unpost(document: docRef);
      } catch (_) {
        // Force status compensation if unpost fails during failure recovery
      }
      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );
      return OrchestrationFailure(
        documentId: issue.id,
        reason: e.toString(),
      );
    }
  }

  Future<OrchestrationResult> unpostReceipt({
    required StockReceipt receipt,
  }) async {
    try {
      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        warehouseId: receipt.warehouse,
        status: receipt.status,
        currencyCode: receipt.currencyCode,
        exchangeRate: receipt.exchangeRate,
      );

      // 1. Check inventory downstream dependencies first
      final inventoryResult = await _postingCoordinator.unpost(document: docRef);

      if (inventoryResult is UnpostBlockedByDependencies) {
        return OrchestrationFailure(
          documentId: receipt.id,
          reason: inventoryResult.message,
        );
      } else if (inventoryResult is UnpostInvalidStatus) {
        return OrchestrationFailure(
          documentId: receipt.id,
          reason: inventoryResult.reason,
        );
      }

      // 2. Void / reverse the accounting journal entry
      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );

      return OrchestrationSuccess(
        documentId: receipt.id,
        message: 'تم إلغاء ترحيل أمر التوريد وعكس القيد المحاسبي بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: receipt.id,
        reason: e.toString(),
      );
    }
  }

  Future<OrchestrationResult> unpostIssue({
    required StockIssue issue,
  }) async {
    try {
      final docRef = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: issue.warehouse,
        status: issue.status,
        currencyCode: issue.currencyCode,
        exchangeRate: issue.exchangeRate,
      );

      final inventoryResult = await _postingCoordinator.unpost(document: docRef);

      if (inventoryResult is UnpostBlockedByDependencies) {
        return OrchestrationFailure(
          documentId: issue.id,
          reason: inventoryResult.message,
        );
      } else if (inventoryResult is UnpostInvalidStatus) {
        return OrchestrationFailure(
          documentId: issue.id,
          reason: inventoryResult.reason,
        );
      }

      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );

      return OrchestrationSuccess(
        documentId: issue.id,
        message: 'تم إلغاء ترحيل أمر الصرف وعكس القيد المحاسبي بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: issue.id,
        reason: e.toString(),
      );
    }
  }

  Future<OrchestrationResult> postSaleInvoice({
    required Sale sale,
    required InventoryDocumentRef docRef,
  }) async {
    try {
      final inventoryResult = await _postingCoordinator.post(document: docRef);

      if (inventoryResult is PostStockShortage) {
        return OrchestrationFailure(
          documentId: sale.uuid,
          reason: 'الكمية غير كافية في المخزون لترحيل فاتورة المبيعات',
        );
      } else if (inventoryResult is PostInvalidStatus) {
        return OrchestrationFailure(
          documentId: sale.uuid,
          reason: inventoryResult.reason,
        );
      }

      final cogsCost = (inventoryResult as PostSuccess).postedValue;

      final drafts = await _entryBuilder.buildDraftsFromSaleInvoice(
        sale: sale,
        calculatedCogsCost: cogsCost,
        isPosted: true,
      );

      // Void any existing journal entries for this sale to avoid postedImmutable error on re-post
      await _journalPostingService.voidBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      await _journalPostingService.voidBySource(
        sourceType: 'sale_cogs',
        sourceId: sale.uuid,
      );

      for (final draft in drafts) {
        await _journalPostingService.post(draft);
      }

      return OrchestrationSuccess(
        documentId: sale.uuid,
        message: 'تم ترحيل فاتورة المبيعات وحركات المخزون والقيود المحاسبية بنجاح',
      );
    } catch (e) {
      try {
        await _postingCoordinator.unpost(document: docRef);
      } catch (_) {}
      await _journalPostingService.voidBySource(sourceType: 'sale', sourceId: sale.uuid);
      await _journalPostingService.voidBySource(sourceType: 'sale_cogs', sourceId: sale.uuid);

      return OrchestrationFailure(
        documentId: sale.uuid,
        reason: e.toString(),
      );
    }
  }

  Future<OrchestrationResult> unpostSaleInvoice({
    required Sale sale,
    required InventoryDocumentRef docRef,
  }) async {
    try {
      final inventoryResult = await _postingCoordinator.unpost(document: docRef);

      if (inventoryResult is UnpostBlockedByDependencies) {
        return OrchestrationFailure(
          documentId: sale.uuid,
          reason: inventoryResult.message,
        );
      } else if (inventoryResult is UnpostInvalidStatus) {
        return OrchestrationFailure(
          documentId: sale.uuid,
          reason: inventoryResult.reason,
        );
      }

      await _journalPostingService.voidBySource(sourceType: 'sale', sourceId: sale.uuid);
      await _journalPostingService.voidBySource(sourceType: 'sale_cogs', sourceId: sale.uuid);

      return OrchestrationSuccess(
        documentId: sale.uuid,
        message: 'تم إلغاء ترحيل فاتورة المبيعات وعكس حركات المخزون والقيود المحاسبية بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: sale.uuid,
        reason: e.toString(),
      );
    }
  }
}
