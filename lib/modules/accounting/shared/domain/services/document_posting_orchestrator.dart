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
  const OrchestrationFailure({required this.documentId, required this.reason});

  final String documentId;
  final String reason;
}

class DocumentPostingOrchestrator {
  DocumentPostingOrchestrator({
    required this._postingCoordinator,
    required this._journalPostingService,
    required this._entryBuilder,
    this._lockChecker = const DocumentLockChecker(),
  });

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

      final docRef = data.toDocumentRef();
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

      return OrchestrationSuccess(
        documentId: data.id,
        message: 'تم ترحيل أمر التوريد والقيود المحاسبية بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: data.id,
        reason: e.toString().replaceAll('Exception: ', ''),
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

      return OrchestrationSuccess(
        documentId: data.id,
        message: 'تم ترحيل أمر الصرف والقيود المحاسبية بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: data.id,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<OrchestrationResult> unpostStockDocumentRef({
    required DocumentRef docRef,
  }) async {
    try {
      final inventoryResult = await _postingCoordinator.unpost(
        document: docRef,
      );

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

      return OrchestrationSuccess(
        documentId: docRef.documentId,
        message: 'تم إلغاء ترحيل المستند وعكس القيد المحاسبي بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: docRef.documentId,
        reason: e.toString().replaceAll('Exception: ', ''),
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
        message:
            'تم ترحيل فاتورة المبيعات وحركات المخزون والقيود المحاسبية بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(
        documentId: sale.uuid,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<OrchestrationResult> unpostSaleInvoice({
    required SaleInvoicePostingData sale,
    required DocumentRef docRef,
  }) async {
    try {
      final inventoryResult = await _postingCoordinator.unpost(
        document: docRef,
      );

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

      await _journalPostingService.voidBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      await _journalPostingService.voidBySource(
        sourceType: 'sale_cogs',
        sourceId: sale.uuid,
      );

      return OrchestrationSuccess(
        documentId: sale.uuid,
        message:
            'تم إلغاء ترحيل فاتورة المبيعات وعكس حركات المخزون والقيود المحاسبية بنجاح',
      );
    } catch (e) {
      return OrchestrationFailure(documentId: sale.uuid, reason: e.toString());
    }
  }
}
