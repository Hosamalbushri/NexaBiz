import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/entities/document_status.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_invoice.dart';
import 'package:stock_count/modules/purchases/domain/entities/supplier.dart';
import 'package:stock_count/modules/purchases/domain/repositories/purchase_repository.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

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
  final JournalPostingService? _journalPostingService;
  final AccountingEntryBuilder? _entryBuilder;
  final AccountingIntegrationPort? _accountingIntegrationService;
  final CanonicalTransactionOrchestrator _orchestrator;
  final AuditTrailService? _auditTrailService;
  final SyncQueue? _syncQueue;

  PostPurchaseInvoiceUseCase({
    required PurchaseRepository purchaseRepository,
    required PostingCoordinatorPort postingCoordinator,
    JournalPostingService? journalPostingService,
    AccountingEntryBuilder? entryBuilder,
    AccountingIntegrationPort? accountingIntegrationService,
    required CanonicalTransactionOrchestrator orchestrator,
    AuditTrailService? auditTrailService,
    SyncQueue? syncQueue,
  })  : _purchaseRepository = purchaseRepository,
        _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _accountingIntegrationService = accountingIntegrationService,
        _orchestrator = orchestrator,
        _auditTrailService = auditTrailService,
        _syncQueue = syncQueue;

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

          if (inventoryResult is PostStockShortage) {
            throw Exception('خطأ في المخزون أثناء ترحيل فاتورة الشراء');
          } else if (inventoryResult is PostInvalidStatus) {
            throw Exception(inventoryResult.reason);
          }

          // 2. Mark Purchase Invoice as posted in DB
          await _purchaseRepository.postPurchaseInvoice(invoice.id);

          // 3. Post Accounting Entry via AccountingIntegrationPort
          String? journalUuid;
          if (_accountingIntegrationService != null) {
            final postingResult = await _accountingIntegrationService!.processOperationalTransaction(
              OperationalAccountingRequest(
                companyId: companyId,
                sourceType: 'purchase',
                sourceId: invoice.id,
                transactionType: AccountingTransactionType.purchaseCredit,
                transactionDate: invoice.invoiceDate,
                amount: invoice.grandTotal,
                currencyCode: invoice.currencyCode,
                baseCurrencyCode: invoice.currencyCode,
                exchangeRate: 1.0,
                warehouseId: invoice.warehouseId,
                description: 'فاتورة شراء ${invoice.invoiceNumber}',
              ),
            );

            if (!postingResult.isSuccess) {
              throw Exception(
                postingResult.failureReason ?? 'فشل الترحيل المحاسبي لفاتورة الشراء',
              );
            }
            journalUuid = postingResult.journal?.uuid;
          } else if (_entryBuilder != null && _journalPostingService != null) {
            final draft = await _entryBuilder!.buildDraftFromInventoryDocument(
              document: docRef,
              totalAmount: invoice.grandTotal,
              isPosted: true,
            );

            await _journalPostingService!.voidBySource(
              sourceType: 'purchase',
              sourceId: invoice.id,
            );

            final journalEntry = await _journalPostingService!.post(draft);
            journalUuid = journalEntry.uuid;
          }

          // 4. Record Audit Event inside transaction
          if (_auditTrailService != null) {
            await _auditTrailService!.recordEvent(
              documentId: invoice.id,
              documentType: 'purchase_invoice',
              eventType: 'posted',
              userId: userId ?? context.userId,
              companyId: companyId,
              notes: 'Purchase Invoice ${invoice.invoiceNumber} posted',
            );
          }

          // 5. Enqueue Sync Operation inside transaction
          if (_syncQueue != null) {
            await _syncQueue!.enqueue(
              SyncOperation.create(
                entityType: 'purchase_invoice',
                entityId: invoice.id,
                type: SyncOperationType.update,
                companyId: companyId,
                payload: {
                  'id': invoice.id,
                  'invoiceNumber': invoice.invoiceNumber,
                  'status': PurchaseInvoiceStatus.posted.name,
                  'journalEntryUuid': journalUuid,
                  'companyId': companyId,
                },
              ),
            );
          }

          return PurchaseOrchestrationSuccess(
            invoiceId: invoice.id,
            journalEntryUuid: journalUuid,
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
