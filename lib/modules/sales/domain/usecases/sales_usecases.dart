import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/entities/document_status.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';

sealed class SaleOrchestrationResult {
  const SaleOrchestrationResult();
}

class SaleOrchestrationSuccess extends SaleOrchestrationResult {
  final String saleUuid;
  final String message;
  final String? journalEntryUuid;

  const SaleOrchestrationSuccess({
    required this.saleUuid,
    required this.message,
    this.journalEntryUuid,
  });
}

class SaleOrchestrationFailure extends SaleOrchestrationResult {
  final String saleUuid;
  final String reason;

  const SaleOrchestrationFailure({
    required this.saleUuid,
    required this.reason,
  });
}

/// Use case for posting a Sale Invoice across Sales, Inventory, Costing, Accounting, Audit, and Sync domains
/// within a single atomic database transaction.
class PostSaleInvoiceUseCase {
  final SaleRepository _saleRepository;
  final PostingCoordinatorPort _postingCoordinator;
  final JournalPostingService _journalPostingService;
  final AccountingEntryBuilder _entryBuilder;
  final CanonicalTransactionOrchestrator _orchestrator;
  final AuditTrailService? _auditTrailService;
  final SyncQueue? _syncQueue;

  PostSaleInvoiceUseCase({
    required SaleRepository saleRepository,
    required PostingCoordinatorPort postingCoordinator,
    required JournalPostingService journalPostingService,
    required AccountingEntryBuilder entryBuilder,
    required CanonicalTransactionOrchestrator orchestrator,
    AuditTrailService? auditTrailService,
    SyncQueue? syncQueue,
  })  : _saleRepository = saleRepository,
        _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _orchestrator = orchestrator,
        _auditTrailService = auditTrailService,
        _syncQueue = syncQueue;

  Future<SaleOrchestrationResult> execute({
    required String saleUuid,
    required String companyId,
    String? userId,
  }) async {
    try {
      final sale = await _saleRepository.getById(saleUuid);
      if (sale == null) {
        return SaleOrchestrationFailure(
          saleUuid: saleUuid,
          reason: 'المبيعات غير موجودة',
        );
      }

      if (sale.saleStatus == SaleStatus.posted) {
        return SaleOrchestrationSuccess(
          saleUuid: saleUuid,
          message: 'فاتورة المبيعات مرحلة بالفعل',
        );
      }

      return await _orchestrator.runInTransaction(
        (context) async {
          final docRef = DocumentRef(
            documentId: sale.id,
            documentNumber: sale.saleNumber,
            documentType: DocumentType.salesInvoice,
            documentDate: sale.saleDate,
            warehouseId: sale.warehouseId,
            status: DocumentStatus.draft,
          );

          // 1. Post Inventory movements & consume cost layers FIRST
          final inventoryResult = await _postingCoordinator.post(
            document: docRef,
            userId: userId,
          );

          if (inventoryResult is PostStockShortage) {
            throw Exception('الكمية غير كافية في المخزون لترحيل فاتورة المبيعات');
          } else if (inventoryResult is PostInvalidStatus) {
            throw Exception(inventoryResult.reason);
          }

          final cogsCost = (inventoryResult as PostSuccess).postedValue;

          // 2. Build and post Journal Entries
          final postingData = SaleInvoicePostingData(
            uuid: sale.id,
            saleNumber: sale.saleNumber,
            saleDate: sale.saleDate,
            settlementType: sale.settlementType == SaleSettlementType.credit
                ? PostingSettlementType.credit
                : PostingSettlementType.cash,
            customerAccountId: sale.customerAccountId,
            cashAccountId: sale.cashAccountId,
            currencyCode: sale.currencyCode,
            baseCurrencyCode: sale.baseCurrencyCode,
            exchangeRate: sale.exchangeRate,
            discountAmount: sale.discountAmount,
            itemDiscountTotal: sale.itemDiscountTotal,
            taxAmount: sale.taxAmount,
            total: sale.total,
          );

          final drafts = await _entryBuilder.buildDraftsFromSaleInvoice(
            sale: postingData,
            calculatedCogsCost: cogsCost,
            isPosted: true,
          );

          await _journalPostingService.voidBySource(
            sourceType: 'sale',
            sourceId: sale.id,
          );
          await _journalPostingService.voidBySource(
            sourceType: 'sale_cogs',
            sourceId: sale.id,
          );

          String? primaryJournalUuid;
          for (final draft in drafts) {
            final entry = await _journalPostingService.post(draft);
            primaryJournalUuid ??= entry.id;
          }

          // 3. Record Audit Event inside transaction
          if (_auditTrailService != null) {
            await _auditTrailService!.recordEvent(
              documentId: sale.id,
              documentType: 'sales_invoice',
              eventType: 'posted',
              userId: userId ?? context.userId,
              companyId: companyId,
              notes: 'Sale Invoice ${sale.saleNumber} posted',
            );
          }

          // 4. Enqueue Sync Operation inside transaction
          if (_syncQueue != null) {
            await _syncQueue!.enqueue(
              SyncOperation.create(
                entityType: 'sales_invoice',
                entityId: sale.id,
                type: SyncOperationType.update,
                companyId: companyId,
                payload: {
                  'uuid': sale.id,
                  'saleNumber': sale.saleNumber,
                  'saleStatus': SaleStatus.posted.name,
                  'journalEntryUuid': primaryJournalUuid,
                  'companyId': companyId,
                },
              ),
            );
          }

          return SaleOrchestrationSuccess(
            saleUuid: sale.id,
            journalEntryUuid: primaryJournalUuid,
            message: 'تم ترحيل فاتورة المبيعات وحركات المخزون والقيود المحاسبية بنجاح',
          );
        },
        companyId: companyId,
        userId: userId,
      );
    } catch (e) {
      return SaleOrchestrationFailure(
        saleUuid: saleUuid,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

/// Use case for unposting a Sale Invoice across domains inside a single atomic database transaction.
class UnpostSaleInvoiceUseCase {
  final SaleRepository _saleRepository;
  final PostingCoordinatorPort _postingCoordinator;
  final JournalPostingService _journalPostingService;
  final CanonicalTransactionOrchestrator _orchestrator;
  final AuditTrailService? _auditTrailService;
  final SyncQueue? _syncQueue;

  UnpostSaleInvoiceUseCase({
    required SaleRepository saleRepository,
    required PostingCoordinatorPort postingCoordinator,
    required JournalPostingService journalPostingService,
    required CanonicalTransactionOrchestrator orchestrator,
    AuditTrailService? auditTrailService,
    SyncQueue? syncQueue,
  })  : _saleRepository = saleRepository,
        _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _orchestrator = orchestrator,
        _auditTrailService = auditTrailService,
        _syncQueue = syncQueue;

  Future<SaleOrchestrationResult> execute({
    required String saleUuid,
    required String companyId,
    String? userId,
  }) async {
    try {
      final sale = await _saleRepository.getById(saleUuid);
      if (sale == null) {
        return SaleOrchestrationFailure(
          saleUuid: saleUuid,
          reason: 'المبيعات غير موجودة',
        );
      }

      return await _orchestrator.runInTransaction(
        (context) async {
          final docRef = DocumentRef(
            documentId: sale.id,
            documentNumber: sale.saleNumber,
            documentType: DocumentType.salesInvoice,
            documentDate: sale.saleDate,
            warehouseId: sale.warehouseId,
            status: DocumentStatus.posted,
          );

          final inventoryResult = await _postingCoordinator.unpost(
            document: docRef,
            requestedBy: userId,
          );

          if (inventoryResult is UnpostBlockedByDependencies) {
            throw Exception(inventoryResult.message);
          } else if (inventoryResult is UnpostInvalidStatus) {
            throw Exception(inventoryResult.reason);
          }

          await _journalPostingService.voidBySource(
            sourceType: 'sale',
            sourceId: sale.id,
          );
          await _journalPostingService.voidBySource(
            sourceType: 'sale_cogs',
            sourceId: sale.id,
          );

          // Record Audit Event inside transaction
          if (_auditTrailService != null) {
            await _auditTrailService!.recordEvent(
              documentId: sale.id,
              documentType: 'sales_invoice',
              eventType: 'unposted',
              userId: userId ?? context.userId,
              companyId: companyId,
              notes: 'Sale Invoice ${sale.saleNumber} unposted',
            );
          }

          // Enqueue Sync Operation inside transaction
          if (_syncQueue != null) {
            await _syncQueue!.enqueue(
              SyncOperation.create(
                entityType: 'sales_invoice',
                entityId: sale.id,
                type: SyncOperationType.update,
                companyId: companyId,
                payload: {
                  'uuid': sale.id,
                  'saleNumber': sale.saleNumber,
                  'saleStatus': SaleStatus.unposted.name,
                  'companyId': companyId,
                },
              ),
            );
          }

          return SaleOrchestrationSuccess(
            saleUuid: sale.id,
            message: 'تم إلغاء ترحيل فاتورة المبيعات وعكس القيود بنجاح',
          );
        },
        companyId: companyId,
        userId: userId,
      );
    } catch (e) {
      return SaleOrchestrationFailure(
        saleUuid: saleUuid,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
