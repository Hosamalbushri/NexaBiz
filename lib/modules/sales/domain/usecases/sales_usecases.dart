import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/entities/document_status.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';

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

  PostSaleInvoiceUseCase({
    required SaleRepository saleRepository,
    required PostingCoordinatorPort postingCoordinator,
    required JournalPostingService journalPostingService,
    required AccountingEntryBuilder entryBuilder,
    required CanonicalTransactionOrchestrator orchestrator,
  })  : _saleRepository = saleRepository,
        _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _orchestrator = orchestrator;

  Future<SaleOrchestrationResult> execute({
    required String saleUuid,
    required String companyId,
    String? userId,
  }) async {
    try {
      final sale = await _saleRepository.getByUuid(saleUuid);
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
            documentId: sale.uuid,
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
            uuid: sale.uuid,
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
            sourceId: sale.uuid,
          );
          await _journalPostingService.voidBySource(
            sourceType: 'sale_cogs',
            sourceId: sale.uuid,
          );

          String? primaryJournalUuid;
          for (final draft in drafts) {
            final entry = await _journalPostingService.post(draft);
            primaryJournalUuid ??= entry.uuid;
          }

          return SaleOrchestrationSuccess(
            saleUuid: sale.uuid,
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

  UnpostSaleInvoiceUseCase({
    required SaleRepository saleRepository,
    required PostingCoordinatorPort postingCoordinator,
    required JournalPostingService journalPostingService,
    required CanonicalTransactionOrchestrator orchestrator,
  })  : _saleRepository = saleRepository,
        _postingCoordinator = postingCoordinator,
        _journalPostingService = journalPostingService,
        _orchestrator = orchestrator;

  Future<SaleOrchestrationResult> execute({
    required String saleUuid,
    required String companyId,
    String? userId,
  }) async {
    try {
      final sale = await _saleRepository.getByUuid(saleUuid);
      if (sale == null) {
        return SaleOrchestrationFailure(
          saleUuid: saleUuid,
          reason: 'المبيعات غير موجودة',
        );
      }

      return await _orchestrator.runInTransaction(
        (context) async {
          final docRef = DocumentRef(
            documentId: sale.uuid,
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
            sourceId: sale.uuid,
          );
          await _journalPostingService.voidBySource(
            sourceType: 'sale_cogs',
            sourceId: sale.uuid,
          );

          return SaleOrchestrationSuccess(
            saleUuid: sale.uuid,
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
