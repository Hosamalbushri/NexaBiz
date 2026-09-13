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
    required PostingCoordinatorPort postingCoordinator,
    AccountingIntegrationPort? integrationService,
    JournalPostingService? journalPostingService,
    AccountingEntryBuilder? entryBuilder,
    DocumentLockChecker lockChecker = const DocumentLockChecker(),
    CanonicalTransactionOrchestrator? orchestrator,
  })  : _postingCoordinator = postingCoordinator,
        _integrationService = integrationService,
        _journalPostingService = journalPostingService,
        _entryBuilder = entryBuilder,
        _lockChecker = lockChecker,
        _orchestrator = orchestrator;

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
    final body = () async {
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
    };

    try {
      if (_orchestrator != null && companyId != null) {
        return await _orchestrator!.runInTransaction(
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
    final body = () async {
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
    };

    try {
      if (_orchestrator != null && companyId != null) {
        return await _orchestrator!.runInTransaction(
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
    return OrchestrationFailure(
      documentId: docRef.documentId,
      reason: 'لا يمكن إلغاء ترحيل مستند مرحّل. يلزم التسوية عبر العكس.',
    );
  }

  Future<OrchestrationResult> postSaleInvoice({
    required SaleInvoicePostingData sale,
    required DocumentRef docRef,
    String? companyId,
    String? userId,
  }) async {
    final body = () async {
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

      if (_integrationService != null) {
        final isCredit = sale.settlementType == PostingSettlementType.credit;
        final postingResult = await _integrationService!.processOperationalTransaction(
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
          final cogsResult = await _integrationService!.processOperationalTransaction(
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
      } else if (_entryBuilder != null && _journalPostingService != null) {
        final drafts = await _entryBuilder!.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: cogsCost,
          isPosted: true,
        );

        await _journalPostingService!.voidBySource(
          sourceType: 'sale',
          sourceId: sale.uuid,
        );
        await _journalPostingService!.voidBySource(
          sourceType: 'sale_cogs',
          sourceId: sale.uuid,
        );

        String? primaryJournalUuid;
        for (final draft in drafts) {
          final entry = await _journalPostingService!.post(draft);
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
    };

    try {
      if (_orchestrator != null && companyId != null) {
        return await _orchestrator!.runInTransaction(
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


