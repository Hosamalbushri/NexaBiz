import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/sales/perpetual_sale_inventory_effect_adapter.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/entities/document_status.dart';
import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/repositories/stock_movements_repository.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';

class _FakePostingCoordinator implements PostingCoordinatorPort {
  bool shouldFail = false;
  String failReason = 'Inventory Error';

  @override
  Future<PostResult> post({required DocumentRef document, String? userId}) async {
    if (shouldFail) {
      return PostStockShortage(shortages: const []);
    }
    return PostSuccess(document: document, postedValue: 50.0);
  }

  @override
  Future<UnpostResult> unpost({
    required DocumentRef document,
    String? requestedBy,
    String? reason,
  }) async {
    return const UnpostSuccess();
  }
}

class _FakeJournalPostingService implements JournalPostingService {
  bool shouldFail = false;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async {
    if (shouldFail) {
      throw Exception('Accounting Posting Error');
    }
    final now = DateTime.now();
    return JournalEntry(
      id: 'je-1',
      entryDate: draft.entryDate,
      voucherNumber: draft.voucherNumber,
      voucherType: draft.voucherType,
      currencyCode: draft.currencyCode,
      isPosted: true,
      lines: const [],
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<JournalEntry> reverse({
    required String journalEntryUuid,
    required String reason,
    required String reversedBy,
    DateTime? reversalDate,
  }) async {
    final now = DateTime.now();
    return JournalEntry(
      id: 'je-reversal-1',
      entryDate: reversalDate ?? now,
      voucherNumber: 'REV-001',
      voucherType: 'JV',
      currencyCode: 'SAR',
      isPosted: true,
      lines: const [],
      sourceType: 'reversal',
      sourceId: journalEntryUuid,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountingEntryBuilder extends Fake implements AccountingEntryBuilder {
  @override
  Future<List<JournalEntryDraft>> buildDraftsFromSaleInvoice({
    required SaleInvoicePostingData sale,
    required double calculatedCogsCost,
    bool isPosted = true,
  }) async {
    return [];
  }
}

class _FakeStockMovementsRepository extends Fake implements StockMovementsRepository {}

class _ClosedPeriodValidator implements PeriodValidatorPort {
  @override
  Future<void> assertEntryAllowed(DateTime entryDate) async {
    throw const JournalException(
      JournalException.periodClosed,
      'Period is closed',
    );
  }

  @override
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  }) async {
    throw const JournalException(
      JournalException.periodClosed,
      'Period is closed',
    );
  }
}

void main() {
  group('Phase 1C — Canonical Document Lifecycle & Transaction State Enforcement', () {
    const companyId = 'comp-1001';
    final now = DateTime.now();

    test('Test 1 — DocumentStatus transition guards disallow unpost & forbid cancelling posted', () {
      expect(DocumentStatus.draft.canEdit, isTrue);
      expect(DocumentStatus.draft.canPost, isTrue);
      expect(DocumentStatus.draft.canDelete, isTrue);
      expect(DocumentStatus.draft.canUnpost, isFalse);

      expect(DocumentStatus.posted.canEdit, isFalse);
      expect(DocumentStatus.posted.canPost, isFalse);
      expect(DocumentStatus.posted.canUnpost, isFalse);
    });

    test('Test 2 — SaleStatus transition guards forbid cancelling posted sales', () {
      expect(SaleStatus.unposted.canPost, isTrue);
      expect(SaleStatus.unposted.canCancel, isTrue);

      expect(SaleStatus.posted.canPost, isFalse);
      expect(SaleStatus.posted.canCancel, isFalse);
    });

    test('Test 3 — TransactionStatus transition guards forbid unposting & cancelling posted', () {
      expect(TransactionStatus.unposted.canPost, isTrue);
      expect(TransactionStatus.unposted.canCancel, isTrue);
      expect(TransactionStatus.unposted.canUnpost, isFalse);

      expect(TransactionStatus.posted.canPost, isFalse);
      expect(TransactionStatus.posted.canCancel, isFalse);
      expect(TransactionStatus.posted.canUnpost, isFalse);
    });

    test('Test 4 — PerpetualSaleInventoryEffectAdapter rejects unposting posted sale', () async {
      final fakePostingCoord = _FakePostingCoordinator();
      final fakeJournalService = _FakeJournalPostingService();
      final orchestrator = DocumentPostingOrchestrator(
        postingCoordinator: fakePostingCoord,
        journalPostingService: fakeJournalService,
        entryBuilder: _FakeAccountingEntryBuilder(),
      );

      final adapter = PerpetualSaleInventoryEffectAdapter(
        orchestrator: orchestrator,
        stockMovementsRepository: _FakeStockMovementsRepository(),
      );

      final postedSale = Sale(
        id: 'sale-1',
        companyId: companyId,
        saleNumber: 'INV-001',
        saleDate: now,
        settlementType: SaleSettlementType.cash,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        items: const [],
        payments: const [],
        subtotal: 100.0,
        itemDiscountTotal: 0.0,
        discountType: DiscountType.fixed,
        discountValue: 0.0,
        discountAmount: 0.0,
        taxRate: 0.0,
        taxAmount: 0.0,
        total: 100.0,
        paidAmount: 100.0,
        remainingAmount: 0.0,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.posted,
        dataSource: SaleDataSource.local,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () => adapter.onCancelled(postedSale),
        throwsA(isA<SaleException>()),
      );
    });

    test('Test 5 — DocumentPostingOrchestrator rejects unpostSaleInvoice in favor of Reversal', () async {
      final fakePostingCoord = _FakePostingCoordinator();
      final fakeJournalService = _FakeJournalPostingService();
      final orchestrator = DocumentPostingOrchestrator(
        postingCoordinator: fakePostingCoord,
        journalPostingService: fakeJournalService,
        entryBuilder: _FakeAccountingEntryBuilder(),
      );

      final docRef = DocumentRef(
        documentId: 'sale-1',
        documentNumber: 'INV-001',
        documentType: DocumentType.salesInvoice,
        documentDate: now,
        status: DocumentStatus.posted,
      );

      final postingData = SaleInvoicePostingData(
        uuid: 'sale-1',
        saleNumber: 'INV-001',
        saleDate: now,
        total: 100.0,
        itemDiscountTotal: 0.0,
        discountAmount: 0.0,
        settlementType: PostingSettlementType.cash,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
      );

      final result = await orchestrator.unpostSaleInvoice(
        sale: postingData,
        docRef: docRef,
      );

      expect(result, isA<OrchestrationFailure>());
      expect((result as OrchestrationFailure).reason, contains('لا يمكن إلغاء ترحيل'));
    });

    test('Test 6 — Inventory failure rolls back posting transaction', () async {
      final fakePostingCoord = _FakePostingCoordinator()..shouldFail = true;
      final fakeJournalService = _FakeJournalPostingService();
      final orchestrator = DocumentPostingOrchestrator(
        postingCoordinator: fakePostingCoord,
        journalPostingService: fakeJournalService,
        entryBuilder: _FakeAccountingEntryBuilder(),
      );

      final docRef = DocumentRef(
        documentId: 'sale-1',
        documentNumber: 'INV-001',
        documentType: DocumentType.salesInvoice,
        documentDate: now,
        status: DocumentStatus.draft,
      );

      final postingData = SaleInvoicePostingData(
        uuid: 'sale-1',
        saleNumber: 'INV-001',
        saleDate: now,
        total: 100.0,
        itemDiscountTotal: 0.0,
        discountAmount: 0.0,
        settlementType: PostingSettlementType.cash,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
      );

      final result = await orchestrator.postSaleInvoice(
        sale: postingData,
        docRef: docRef,
      );

      expect(result, isA<OrchestrationFailure>());
    });

    test('Test 7 — PeriodValidator rejects posting in closed period', () async {
      final validator = _ClosedPeriodValidator();

      expect(
        () => validator.assertEntryAllowed(DateTime(2026, 1, 15)),
        throwsA(isA<JournalException>()),
      );
    });

    test('Test 8 — Reversal preserves original document and creates reversing journal', () async {
      final fakeJournalService = _FakeJournalPostingService();

      final reversalEntry = await fakeJournalService.reverse(
        journalEntryUuid: 'je-1',
        reason: 'Correction',
        reversedBy: 'user-1',
      );

      expect(reversalEntry.isPosted, isTrue);
      expect(reversalEntry.sourceType, equals('reversal'));
      expect(reversalEntry.sourceId, equals('je-1'));
    });
  });
}
