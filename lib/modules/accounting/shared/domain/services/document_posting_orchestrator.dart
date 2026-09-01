import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
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
    required PostingCoordinatorPort postingCoordinator,
    required JournalPostingService journalPostingService,
    required AccountingEntryBuilder entryBuilder,
    DocumentLockChecker lockChecker = const DocumentLockChecker(),
  })  : _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _lockChecker = lockChecker;

  final PostingCoordinatorPort _postingCoordinator;
  final JournalPostingService _journalPostingService;
  final AccountingEntryBuilder _entryBuilder;
  final DocumentLockChecker _lockChecker;

  Future<OrchestrationResult> postStockReceiptData({
    required StockDocumentPostingData data,
  }) async {
    try {
      _lockChecker.assertCanEdit(
        documentNumber: data.documentNumber,
        status: data.status,
      );

      final totalAmount = data.totalAmount;
      final docRef = data.toDocumentRef();

      // 1. Post Inventory movements & cost layers first
      final inventoryResult = await _postingCoordinator.post(document: docRef);

      if (inventoryResult is PostStockShortage) {
        return OrchestrationFailure(
          documentId: data.id,
          reason: 'نقص في المخزون للمواد المطلوب توريدها',
        );
      } else if (inventoryResult is PostInvalidStatus) {
        return OrchestrationFailure(
          documentId: data.id,
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
            documentId: data.id,
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
          offsetAccountId: data.offsetAccountId,
          isPosted: true,
        );
        final entry = await _journalPostingService.post(draft);
        return OrchestrationSuccess(
          documentId: data.id,
          journalEntryUuid: entry.uuid,
          message: 'تم ترحيل أمر التوريد والقيود المحاسبية بنجاح',
        );
      }

      return OrchestrationSuccess(
        documentId: data.id,
        message: 'تم ترحيل أمر التوريد بنجاح',
      );
    } catch (e) {
      final docRef = data.toDocumentRef();
      String compErrorMsg = '';
      try {
        await _postingCoordinator.unpost(document: docRef);
      } catch (compErr) {
        compErrorMsg = ' (فشل إلغاء ترحيل المخزون أثناء التعويض: $compErr)';
      }
      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );
      return OrchestrationFailure(
        documentId: data.id,
        reason: '${e.toString()}$compErrorMsg',
      );
    }
  }

  Future<OrchestrationResult> postStockIssueData({
    required StockDocumentPostingData data,
  }) async {
    try {
      _lockChecker.assertCanEdit(
        documentNumber: data.documentNumber,
        status: data.status,
      );

      final docRef = data.toDocumentRef();

      // 1. Post Inventory movements & consume cost layers FIRST
      final inventoryResult = await _postingCoordinator.post(document: docRef);

      if (inventoryResult is PostStockShortage) {
        return OrchestrationFailure(
          documentId: data.id,
          reason: 'نقص في الكميات المتاحة بالمخزن',
        );
      } else if (inventoryResult is PostInvalidStatus) {
        return OrchestrationFailure(
          documentId: data.id,
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
            documentId: data.id,
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
          offsetAccountId: data.offsetAccountId,
          isPosted: true,
          useBaseCurrencyForCogs: true,
        );
        final entry = await _journalPostingService.post(draft);
        return OrchestrationSuccess(
          documentId: data.id,
          journalEntryUuid: entry.uuid,
          message: 'تم ترحيل أمر الصرف والقيود المحاسبية بنجاح',
        );
      }

      return OrchestrationSuccess(
        documentId: data.id,
        message: 'تم ترحيل أمر الصرف بنجاح',
      );
    } catch (e) {
      final docRef = data.toDocumentRef();
      String compErrorMsg = '';
      try {
        await _postingCoordinator.unpost(document: docRef);
      } catch (compErr) {
        compErrorMsg = ' (فشل إلغاء ترحيل المخزون أثناء التعويض: $compErr)';
      }
      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );
      return OrchestrationFailure(
        documentId: data.id,
        reason: '${e.toString()}$compErrorMsg',
      );
    }
  }

  Future<OrchestrationResult> unpostStockDocumentRef({
    required DocumentRef docRef,
  }) async {
    try {
      // 1. Check inventory downstream dependencies first
      final inventoryResult = await _postingCoordinator.unpost(document: docRef);

      if (inventoryResult is UnpostBlockedByDependencies) {
        return OrchestrationFailure(
          documentId: docRef.documentId,
          reason: inventoryResult.message,
        );
      } else if (inventoryResult is UnpostInvalidStatus) {
        return OrchestrationFailure(
          documentId: docRef.documentId,
          reason: inventoryResult.reason,
        );
      }

      // 2. Void / reverse the accounting journal entry
      await _journalPostingService.voidBySource(
        sourceType: docRef.documentType.storageValue,
        sourceId: docRef.documentId,
      );

      return OrchestrationSuccess(
        documentId: docRef.documentId,
        message: 'تم إلغاء ترحيل المستند وعكس القيد المحاسبي بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: docRef.documentId,
        reason: e.toString(),
      );
    }
  }

  Future<OrchestrationResult> postSaleInvoice({
    required SaleInvoicePostingData sale,
    required DocumentRef docRef,
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
      String compErrorMsg = '';
      try {
        await _postingCoordinator.unpost(document: docRef);
      } catch (compErr) {
        compErrorMsg = ' (فشل إلغاء ترحيل المخزون أثناء التعويض: $compErr)';
      }
      await _journalPostingService.voidBySource(sourceType: 'sale', sourceId: sale.uuid);
      await _journalPostingService.voidBySource(sourceType: 'sale_cogs', sourceId: sale.uuid);

      return OrchestrationFailure(
        documentId: sale.uuid,
        reason: '${e.toString()}$compErrorMsg',
      );
    }
  }

  Future<OrchestrationResult> unpostSaleInvoice({
    required SaleInvoicePostingData sale,
    required DocumentRef docRef,
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
