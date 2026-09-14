import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';
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
    this._integrationService,
    this._journalPostingService,
    this._entryBuilder,
    this._lockChecker = const DocumentLockChecker(),
    this._orchestrator,
  });

  final PostingCoordinatorPort _postingCoordinator;
  final AccountingIntegrationPort? _integrationService;
  final JournalPostingService? _journalPostingService;
  final AccountingEntryBuilder? _entryBuilder;
  final DocumentLockChecker _lockChecker;
  final CanonicalTransactionOrchestrator? _orchestrator;

  Future<OrchestrationResult> postStockReceiptData({
    required StockDocumentPostingData data,
    String? companyId,
    String? userId,
  }) async {
    Future<OrchestrationResult> body() async {
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
    }

    try {
      final orchestrator = _orchestrator;
      if (orchestrator != null && companyId != null) {
        return await orchestrator.runInTransaction(
          (_) async => await body(),
          companyId: companyId,
          userId: userId,
        );
      }
      return await body();
    } catch (e) {
      return OrchestrationFailure(
        documentId: data.id,
        reason: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<OrchestrationResult> postStockIssueData({
    required StockDocumentPostingData data,
    String? companyId,
    String? userId,
  }) async {
    Future<OrchestrationResult> body() async {
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
    }

    try {
      final orchestrator = _orchestrator;
      if (orchestrator != null && companyId != null) {
        return await orchestrator.runInTransaction(
          (_) async => await body(),
          companyId: companyId,
          userId: userId,
        );
      }
      return await body();
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
    final result = await _postingCoordinator.unpost(document: docRef);
    if (result is UnpostSuccess) {
      return OrchestrationSuccess(
        documentId: docRef.documentId,
        message: 'تم إلغاء ترحيل المستند بنجاح',
      );
    } else if (result is UnpostBlockedByDependencies) {
      return OrchestrationFailure(
        documentId: docRef.documentId,
        reason: result.message,
      );
    } else if (result is UnpostInvalidStatus) {
      return OrchestrationFailure(
        documentId: docRef.documentId,
        reason: result.reason,
      );
    }
    return OrchestrationFailure(
      documentId: docRef.documentId,
      reason: 'فشل إلغاء ترحيل المستند',
    );
  }

  Future<OrchestrationResult> postSaleInvoice({
    required SaleInvoicePostingData sale,
    required DocumentRef docRef,
    String? companyId,
    String? userId,
  }) async {
    Future<OrchestrationResult> body() async {
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
      final activeCompanyId = companyId ?? sale.baseCurrencyCode;

      final integrationService = _integrationService;
      final entryBuilder = _entryBuilder;
      final journalPostingService = _journalPostingService;

      if (integrationService != null) {
        final isCredit = sale.settlementType == PostingSettlementType.credit;
        final postingResult = await integrationService.processOperationalTransaction(
          OperationalAccountingRequest(
            companyId: activeCompanyId,
            sourceType: 'sale',
            sourceId: sale.uuid,
            transactionType: isCredit
                ? AccountingTransactionType.saleCredit
                : AccountingTransactionType.saleCash,
            transactionDate: sale.saleDate,
            amount: sale.total,
            currencyCode: sale.currencyCode,
            baseCurrencyCode: sale.baseCurrencyCode,
            exchangeRate: sale.exchangeRate,
            description: 'فاتورة مبيعات ${sale.saleNumber}',
          ),
        );


        if (!postingResult.isSuccess) {
          throw Exception(
            postingResult.failureReason ?? 'فشل الترحيل المحاسبي لفاتورة المبيعات',
          );
        }

        if (cogsCost > 0) {
          final cogsResult = await integrationService.processOperationalTransaction(
            OperationalAccountingRequest(
              companyId: activeCompanyId,
              sourceType: 'sale_cogs',
              sourceId: sale.uuid,
              transactionType: AccountingTransactionType.stockIssue,
              transactionDate: sale.saleDate,
              amount: cogsCost,
              currencyCode: sale.baseCurrencyCode,
              baseCurrencyCode: sale.baseCurrencyCode,
              exchangeRate: 1.0,
              description: 'تكلفة المبيعات لفاتورة ${sale.saleNumber}',
            ),
          );
          if (!cogsResult.isSuccess) {
            throw Exception(
              cogsResult.failureReason ?? 'فشل الترحيل المحاسبي لتكلفة المبيعات',
            );
          }
        }


        return OrchestrationSuccess(
          documentId: sale.uuid,
          journalEntryUuid: postingResult.journal?.uuid,
          message:
              'تم ترحيل فاتورة المبيعات وحركات المخزون والقيود المحاسبية بنجاح',
        );
      } else if (entryBuilder != null && journalPostingService != null) {
        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: cogsCost,
          isPosted: true,
        );

        await journalPostingService.voidBySource(
          sourceType: 'sale',
          sourceId: sale.uuid,
        );
        await journalPostingService.voidBySource(
          sourceType: 'sale_cogs',
          sourceId: sale.uuid,
        );

        String? primaryJournalUuid;
        for (final draft in drafts) {
          final entry = await journalPostingService.post(draft);
          primaryJournalUuid ??= entry.uuid;
        }

        return OrchestrationSuccess(
          documentId: sale.uuid,
          journalEntryUuid: primaryJournalUuid,
          message:
              'تم ترحيل فاتورة المبيعات وحركات المخزون والقيود المحاسبية بنجاح',
        );
      } else {
        return OrchestrationSuccess(
          documentId: sale.uuid,
          message: 'تم ترحيل حركات المخزون بنجاح (بدون ترحيل محاسبي)',
        );
      }
    }

    try {
      final orchestrator = _orchestrator;
      if (orchestrator != null && companyId != null) {
        return await orchestrator.runInTransaction(
          (_) async => await body(),
          companyId: companyId,
          userId: userId,
        );
      }
      return await body();
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
    return OrchestrationFailure(
      documentId: sale.uuid,
      reason: 'لا يمكن إلغاء ترحيل فاتورة مبيعات مرحّلة. يلزم التسوية عبر العكس.',
    );
  }
}


