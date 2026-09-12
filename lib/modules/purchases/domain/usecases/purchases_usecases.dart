import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/entities/document_status.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_invoice.dart';
import 'package:stock_count/modules/purchases/domain/entities/supplier.dart';
import 'package:stock_count/modules/purchases/domain/repositories/purchase_repository.dart';

sealed class PurchaseOrchestrationResult {
  const PurchaseOrchestrationResult();
}

class PurchaseOrchestrationSuccess extends PurchaseOrchestrationResult {
  final String invoiceId;
  final String message;
  final String? journalEntryUuid;

  const PurchaseOrchestrationSuccess({
    required this.invoiceId,
    required this.message,
    this.journalEntryUuid,
  });
}

class PurchaseOrchestrationFailure extends PurchaseOrchestrationResult {
  final String invoiceId;
  final String reason;

  const PurchaseOrchestrationFailure({
    required this.invoiceId,
    required this.reason,
  });
}

/// Canonical UseCase for orchestrating Purchase Invoice posting across Purchases, Inventory, Costing, Accounting, Audit, and Sync.
class PostPurchaseInvoiceUseCase {
  final PurchaseRepository _purchaseRepository;
  final PostingCoordinatorPort _postingCoordinator;
  final JournalPostingService _journalPostingService;
  final AccountingEntryBuilder _entryBuilder;
  final CanonicalTransactionOrchestrator _orchestrator;

  PostPurchaseInvoiceUseCase({
    required PurchaseRepository purchaseRepository,
    required PostingCoordinatorPort postingCoordinator,
    required JournalPostingService journalPostingService,
    required AccountingEntryBuilder entryBuilder,
    required CanonicalTransactionOrchestrator orchestrator,
  })  : _purchaseRepository = purchaseRepository,
        _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _orchestrator = orchestrator;

  Future<PurchaseOrchestrationResult> execute({
    required String invoiceId,
    required String companyId,
    String? userId,
  }) async {
    try {
      final invoice = await _purchaseRepository.getPurchaseInvoiceById(invoiceId);
      if (invoice == null) {
        return PurchaseOrchestrationFailure(
          invoiceId: invoiceId,
          reason: 'فاتورة الشراء غير موجودة',
        );
      }

      if (invoice.status == PurchaseInvoiceStatus.posted) {
        return PurchaseOrchestrationSuccess(
          invoiceId: invoiceId,
          message: 'فاتورة الشراء مرحلة بالفعل',
        );
      }

      return await _orchestrator.runInTransaction(
        (context) async {
          final docRef = DocumentRef(
            documentId: invoice.id,
            documentNumber: invoice.invoiceNumber,
            documentType: DocumentType.stockReceipt,
            documentDate: invoice.invoiceDate,
            warehouseId: invoice.warehouseId,
            status: DocumentStatus.draft,
          );

          // 1. Post Inbound Stock Receipt & create inventory cost layer
          final inventoryResult = await _postingCoordinator.post(
            document: docRef,
            userId: userId,
          );

          if (inventoryResult is PostInvalidStatus) {
            throw Exception(inventoryResult.reason);
          }

          // 2. Mark Purchase Invoice as posted in DB
          await _purchaseRepository.postPurchaseInvoice(invoice.id);

          // 3. Post Accounting Entry
          final draft = await _entryBuilder.buildDraftFromInventoryDocument(
            document: docRef,
            totalAmount: invoice.grandTotal,
            isPosted: true,
          );

          await _journalPostingService.voidBySource(
            sourceType: 'purchase',
            sourceId: invoice.id,
          );

          final journalEntry = await _journalPostingService.post(draft);

          return PurchaseOrchestrationSuccess(
            invoiceId: invoice.id,
            journalEntryUuid: journalEntry.uuid,
            message: 'تم ترحيل فاتورة الشراء وتوريد المخزون والقيود المحاسبية بنجاح',
          );
        },
        companyId: companyId,
        userId: userId,
      );
    } catch (e) {
      return PurchaseOrchestrationFailure(
        invoiceId: invoiceId,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

/// Canonical Purchase Usecases bundle interface.
class PurchaseUsecases {
  final PurchaseRepository _repository;
  final PostPurchaseInvoiceUseCase? _postUseCase;

  PurchaseUsecases(this._repository, [this._postUseCase]);

  Future<List<Supplier>> getSuppliers(String companyId) {
    return _repository.getSuppliers(companyId);
  }

  Future<Supplier> createSupplier(Supplier supplier) {
    return _repository.createSupplier(supplier);
  }

  Future<List<PurchaseInvoice>> getPurchaseInvoices(String companyId) {
    return _repository.getPurchaseInvoices(companyId);
  }

  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) {
    return _repository.createPurchaseInvoice(invoice);
  }

  Future<void> postPurchaseInvoice(String invoiceId) async {
    if (_postUseCase != null) {
      final invoice = await _repository.getPurchaseInvoiceById(invoiceId);
      final res = await _postUseCase.execute(
        invoiceId: invoiceId,
        companyId: invoice?.companyId ?? '',
      );
      if (res is PurchaseOrchestrationFailure) {
        throw Exception(res.reason);
      }
    } else {
      await _repository.postPurchaseInvoice(invoiceId);
    }
  }
}
