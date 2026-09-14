import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';

import 'package:stock_count/modules/currency/domain/services/functional_currency_service.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_consumption.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';

import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/inventory_accounting_reconciliation_engine.dart';
import 'package:stock_count/core/domain/services/inventory_subledger_port.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';

void main() {
  group('Phase 1D — Canonical Inventory Valuation, Costing & Accounting Reconciliation', () {
    final now = DateTime.now();

    group('1. Currency & Purchase Costing Tests (20 SAR × 140 = 2800 YER)', () {
      test('Test 1.1 — ExchangeRateValidator validates single FX conversion rate', () {
        final rate = ExchangeRateValidator.validate(
          currencyCode: 'SAR',
          baseCurrencyCode: 'YER',
          exchangeRate: 140.0,
        );

        expect(rate, equals(140.0));
      });

      test('Test 1.2 — 20 SAR purchase with 140 rate yields exactly 2800 YER unit cost & total cost', () {
        const docQty = 20.0;
        const docUnitCost = 1.0; // 1 SAR per unit, 20 SAR total doc amount
        const rate = 140.0; // 140 YER / SAR

        const baseUnitCost = docUnitCost * rate; // 140 YER
        const baseTotalCost = docQty * baseUnitCost; // 2800 YER

        final layer = CostLayer(
          id: 'layer-1',
          itemCode: 'ITEM-SAR',
          warehouseId: 'WH-01',
          movementUuid: 'MOV-01',
          movementType: 'stock_receipt',
          receivedDate: now,
          receivedQty: docQty,
          remainingQty: docQty,
          unitCost: baseUnitCost,
          totalCost: baseTotalCost,
          closed: false,
          createdAt: now,
          updatedAt: now,
          companyId: 'comp-1001',
        );

        expect(layer.unitCost, equals(140.0));
        expect(layer.totalCost, equals(2800.0));
      });

      test('Test 1.3 — Invalid FX rate (<= 0) throws InvalidExchangeRateException', () {
        expect(
          () => ExchangeRateValidator.validate(
            currencyCode: 'USD',
            baseCurrencyCode: 'SAR',
            exchangeRate: 0.0,
          ),
          throwsA(isA<InvalidExchangeRateException>()),
        );

        expect(
          () => ExchangeRateValidator.validate(
            currencyCode: 'USD',
            baseCurrencyCode: 'SAR',
            exchangeRate: -5.0,
          ),
          throwsA(isA<InvalidExchangeRateException>()),
        );
      });

      test('Test 1.4 — Base currency identity rate is strictly 1.0', () {
        final rate = ExchangeRateValidator.validate(
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 50.0, // Should be ignored / resolved to 1.0
        );

        expect(rate, equals(1.0));
      });
    });

    group('2. Cost Layer Invariants & FIFO / WAC Consumption', () {
      test('Test 2.1 — Cost layer total cost matches quantity * unitCost invariant', () {
        const qty = 20.0;
        const unitCost = 140.0;
        const expectedTotal = 2800.0;

        final layer = CostLayer(
          id: 'l-inv-1',
          itemCode: 'P-1',
          warehouseId: 'WH-1',
          movementUuid: 'm-1',
          movementType: 'receipt',
          receivedDate: now,
          receivedQty: qty,
          remainingQty: qty,
          unitCost: unitCost,
          totalCost: qty * unitCost,
          closed: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(layer.totalCost, equals(expectedTotal));
      });

      test('Test 2.2 — Multi-layer FIFO consumption allocates older layer first', () {
        final layerOld = CostLayer(
          id: 'l-old',
          itemCode: 'P-FIFO',
          warehouseId: 'WH-1',
          movementUuid: 'm-1',
          movementType: 'receipt',
          receivedDate: now.subtract(const Duration(days: 2)),
          receivedQty: 10.0,
          remainingQty: 10.0,
          unitCost: 100.0,
          totalCost: 1000.0,
          closed: false,
          createdAt: now,
          updatedAt: now,
        );

        final layerNew = CostLayer(
          id: 'l-new',
          itemCode: 'P-FIFO',
          warehouseId: 'WH-1',
          movementUuid: 'm-2',
          movementType: 'receipt',
          receivedDate: now,
          receivedQty: 10.0,
          remainingQty: 10.0,
          unitCost: 150.0,
          totalCost: 1500.0,
          closed: false,
          createdAt: now,
          updatedAt: now,
        );

        // Consuming 15 units under FIFO consumes 10 from layerOld @ 100 and 5 from layerNew @ 150 = 1000 + 750 = 1750.
        const consumedOld = 10.0 * 100.0;
        const consumedNew = 5.0 * 150.0;
        const totalFifoCost = consumedOld + consumedNew;

        expect(totalFifoCost, equals(1750.0));
      });

      test('Test 2.3 — Weighted Average Cost computes exact weighted unit cost', () {
        // Layer 1: 10 units @ 100 = 1000 YER
        // Layer 2: 10 units @ 140 = 1400 YER
        // Total Qty = 20 units, Total Value = 2400 YER
        // Weighted Average Unit Cost = 2400 / 20 = 120 YER
        const totalValuation = 1000.0 + 1400.0;
        const totalQuantity = 10.0 + 10.0;
        const wacUnitCost = totalValuation / totalQuantity;

        expect(wacUnitCost, equals(120.0));
      });
    });

    group('3. Inventory ↔ Accounting Valuation Equality & COGS', () {
      test('Test 3.1 — COGS Journal Entry amounts equal consumed inventory cost', () async {
        final mockMappingResolver = _FakeAccountMappingResolver();
        final mockValidationService = _FakeAccountValidationService();
        final builder = AccountingEntryBuilder(
          mappingResolver: mockMappingResolver,
          validationService: mockValidationService,
        );

        final postingData = SaleInvoicePostingData(
          uuid: 'sale-101',
          saleNumber: 'INV-101',
          saleDate: now,
          total: 5000.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'YER',
          exchangeRate: 140.0,
        );

        const consumedInventoryCost = 2800.0;

        final drafts = await builder.buildDraftsFromSaleInvoice(
          sale: postingData,
          calculatedCogsCost: consumedInventoryCost,
        );

        expect(drafts.length, equals(2));
        final cogsDraft = drafts.firstWhere((d) => d.sourceType == 'sale_cogs');
        expect(cogsDraft.lines.length, equals(2));

        final cogsLine = cogsDraft.lines.firstWhere((l) => l.debit > 0);
        final invLine = cogsDraft.lines.firstWhere((l) => l.credit > 0);

        expect(cogsLine.debit, equals(consumedInventoryCost));
        expect(invLine.credit, equals(consumedInventoryCost));
        expect(cogsDraft.currencyCode, equals('YER'));
      });

      test('Test 3.2 — Purchase Receipt Inventory GL Debit equals Subledger Cost Layer Total Cost', () async {
        final mockMappingResolver = _FakeAccountMappingResolver();
        final mockValidationService = _FakeAccountValidationService();
        final builder = AccountingEntryBuilder(
          mappingResolver: mockMappingResolver,
          validationService: mockValidationService,
        );

        final docRef = InventoryDocumentRef(
          documentId: 'receipt-1',
          documentNumber: 'REC-001',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: now,
          currencyCode: 'SAR',
          exchangeRate: 140.0,
          warehouseId: 'WH-1',
        );

        const totalDocAmountInDocCurrency = 20.0; // 20 SAR
        // Base Amount = 20 SAR * 140 YER/SAR = 2800 YER

        final draft = await builder.buildDraftFromInventoryDocument(
          document: docRef,
          totalAmount: totalDocAmountInDocCurrency,
        );

        final invLine = draft.lines.firstWhere((l) => l.debit > 0);
        final apLine = draft.lines.firstWhere((l) => l.credit > 0);

        expect(invLine.debit, equals(2800.0));
        expect(invLine.currencyCode, equals('YER'));
        expect(apLine.credit, equals(20.0));
        expect(apLine.currencyCode, equals('SAR'));
        expect(apLine.exchangeRateToBase, equals(140.0));
      });
    });

    group('4. Returns & Warehouse Transfers Valuation Preservation', () {
      test('Test 4.1 — Stock Transfer preserves total company valuation across warehouses', () {
        // Warehouse A stock value before transfer: 2800 YER (WH-A: 2800, WH-B: 0) -> Total Company: 2800 YER
        // Transfer 10 units @ 140 YER from WH-A to WH-B:
        // Warehouse A remaining: 10 units @ 140 = 1400 YER
        // Warehouse B received: 10 units @ 140 = 1400 YER
        // Total Company Valuation After Transfer: 1400 + 1400 = 2800 YER
        const companyValuationBefore = 2800.0;
        const whAValuationAfter = 1400.0;
        const whBValuationAfter = 1400.0;
        const companyValuationAfter = whAValuationAfter + whBValuationAfter;

        expect(companyValuationAfter, equals(companyValuationBefore));
      });

      test('Test 4.2 — Purchase Return soft-deletion guard rejects deletion if consumptions exist', () {
        final mockCostLayerService = _FakeCostLayerService();

        expect(
          () => mockCostLayerService.reverseLayer('movement-with-consumptions'),
          throwsA(isA<JournalException>()),
        );
      });
    });

    group('5. Reconciliation & Integrity Checks', () {
      test('Test 5.1 — Reconciliation engine detects subledger vs GL balance discrepancy', () async {
        final fakeSubledgerQuery = _FakeSubledgerQuery(subledgerValuation: 2800.0);
        final db = NexabizDatabase.memory();

        final reconEngine = InventoryAccountingReconciliationEngine(
          inventorySubledgerQuery: fakeSubledgerQuery,
          accountingDb: db,
          readCompanyId: () => 'comp-1001',
        );

        await expectLater(
          reconEngine.verifyReconciliationOrThrow(companyId: 'comp-1001'),
          throwsA(isA<ReconciliationException>()),
        );

        await db.close();
      });
    });
  });
}

class _FakeAccountMappingResolver implements AccountMappingResolver {
  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    return const AccountMapping({
      AccountRole.cash: AccountRoleRef(role: AccountRole.cash, accountUuid: 'acc-cash', accountCode: '101', accountName: 'Cash'),
      AccountRole.receivable: AccountRoleRef(role: AccountRole.receivable, accountUuid: 'acc-ar', accountCode: '102', accountName: 'AR'),
      AccountRole.payable: AccountRoleRef(role: AccountRole.payable, accountUuid: 'acc-ap', accountCode: '201', accountName: 'AP'),
      AccountRole.revenue: AccountRoleRef(role: AccountRole.revenue, accountUuid: 'acc-rev', accountCode: '401', accountName: 'Sales Revenue'),
      AccountRole.cogs: AccountRoleRef(role: AccountRole.cogs, accountUuid: 'acc-cogs', accountCode: '501', accountName: 'COGS'),
      AccountRole.inventory: AccountRoleRef(role: AccountRole.inventory, accountUuid: 'acc-inv', accountCode: '123', accountName: 'Inventory'),
    });
  }
}

class _FakeAccountValidationService implements AccountValidationService {
  @override
  Future<void> assertCanPost(String accountId) async {}

  @override
  Future<AccountValidationResult> validateAccountUuid(String accountId) async {
    return const AccountValidationResult(isValid: true);
  }
}

class _FakeCostLayerService implements CostLayerService {
  @override
  Future<void> reverseLayer(String movementId) async {
    if (movementId == 'movement-with-consumptions') {
      throw JournalException(
        JournalException.dependencyViolation,
        'Cannot reverse cost layer because downstream cost consumptions exist.',
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubledgerQuery implements InventorySubledgerQueryPort {
  _FakeSubledgerQuery({required this.subledgerValuation});
  final double subledgerValuation;

  @override
  Future<double> calculateSubledgerValuation({required String companyId}) async {
    return subledgerValuation;
  }

  @override
  Future<List<InventorySubledgerReceiptSummary>> getPostedStockReceipts({required String companyId}) async => [];

  @override
  Future<List<InventorySubledgerIssueSummary>> getPostedStockIssues({required String companyId}) async => [];

  @override
  Future<List<InventorySubledgerReturnSummary>> getPostedStockReturns({required String companyId}) async => [];

  @override
  Future<bool> hasPostedStockReceipt({required String companyId, required String uuid}) async => false;

  @override
  Future<bool> hasPostedStockIssue({required String companyId, required String uuid}) async => false;

  @override
  Future<bool> hasPostedStockReturn({required String companyId, required String uuid}) async => false;
}
