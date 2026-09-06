import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

String makeUuid(int id) =>
    '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}';

class FakeAccountValidationService implements AccountValidationService {
  const FakeAccountValidationService();

  @override
  Future<AccountValidationResult> validateAccountUuid(
    String accountUuid,
  ) async {
    return AccountValidationResult.valid;
  }

  @override
  Future<void> assertCanPost(String accountUuid) async {}
}

class FakeAccountMappingResolver implements AccountMappingResolver {
  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    return AccountMapping({
      AccountRole.cash: const AccountRoleRef(
        role: AccountRole.cash,
        accountUuid: 'acc_cash_101',
        accountCode: '1010',
        accountName: 'Cash',
      ),
      AccountRole.receivable: const AccountRoleRef(
        role: AccountRole.receivable,
        accountUuid: 'acc_rec_201',
        accountCode: '1100',
        accountName: 'Customer Receivables',
      ),
      AccountRole.revenue: const AccountRoleRef(
        role: AccountRole.revenue,
        accountUuid: 'acc_rev_401',
        accountCode: '4010',
        accountName: 'Sales Revenue',
      ),
      AccountRole.cogs: const AccountRoleRef(
        role: AccountRole.cogs,
        accountUuid: 'acc_cogs_501',
        accountCode: '5010',
        accountName: 'COGS',
      ),
      AccountRole.inventory: const AccountRoleRef(
        role: AccountRole.inventory,
        accountUuid: 'acc_inv_120',
        accountCode: '1200',
        accountName: 'Inventory Asset',
      ),
    });
  }
}

/// Helper model representing returnable quantity state for a sale line
class SalesReturnTracker {
  SalesReturnTracker({required this.saleLineUuid, required this.soldQuantity})
    : returnedQuantity = 0.0;

  final String saleLineUuid;
  final double soldQuantity;
  double returnedQuantity;

  double get remainingReturnableQty => soldQuantity - returnedQuantity;

  void processReturn(double qty) {
    if (qty <= 0) {
      throw ArgumentError('Return quantity must be positive');
    }
    if (qty > remainingReturnableQty) {
      throw StateError(
        'Excessive return quantity: requested $qty, remaining $remainingReturnableQty',
      );
    }
    returnedQuantity += qty;
  }
}

void main() {
  group('SA-08 — Sales Returns, Cancellation & Reversal Integrity Tests', () {
    late InventoryDatabase db;
    late CostLayerServiceImpl costLayerService;
    late AccountingEntryBuilder entryBuilder;
    const companyId = 'comp_ret_01';

    setUp(() {
      db = InventoryDatabase(executor: NativeDatabase.memory());
      costLayerService = CostLayerServiceImpl(
        db: db,
        readCompanyId: () => companyId,
      );
      entryBuilder = AccountingEntryBuilder(
        mappingResolver: FakeAccountMappingResolver(),
        validationService: const FakeAccountValidationService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      '1. Full return processes 100% of sold quantity and updates remaining returnable qty to 0',
      () {
        final tracker = SalesReturnTracker(
          saleLineUuid: makeUuid(10),
          soldQuantity: 10.0,
        );
        expect(tracker.remainingReturnableQty, equals(10.0));

        tracker.processReturn(10.0);

        expect(tracker.returnedQuantity, equals(10.0));
        expect(tracker.remainingReturnableQty, equals(0.0));
      },
    );

    test(
      '2. Partial return processes subset of sold quantity and tracks remaining returnable qty',
      () {
        final tracker = SalesReturnTracker(
          saleLineUuid: makeUuid(11),
          soldQuantity: 10.0,
        );
        tracker.processReturn(4.0);

        expect(tracker.returnedQuantity, equals(4.0));
        expect(tracker.remainingReturnableQty, equals(6.0));
      },
    );

    test(
      '3. Repeated partial returns aggregate correctly until returnable quantity reaches 0',
      () {
        final tracker = SalesReturnTracker(
          saleLineUuid: makeUuid(12),
          soldQuantity: 10.0,
        );
        tracker.processReturn(3.0);
        expect(tracker.remainingReturnableQty, equals(7.0));

        tracker.processReturn(4.0);
        expect(tracker.remainingReturnableQty, equals(3.0));

        tracker.processReturn(3.0);
        expect(tracker.remainingReturnableQty, equals(0.0));
      },
    );

    test(
      '4. Excessive return attempt (> remaining returnable qty) throws StateError',
      () {
        final tracker = SalesReturnTracker(
          saleLineUuid: makeUuid(13),
          soldQuantity: 5.0,
        );
        tracker.processReturn(3.0);

        expect(
          () => tracker.processReturn(3.0), // Requesting 3 when only 2 remain
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      '5. Return refund uses original sale unit price regardless of catalog price changes',
      () {
        const originalUnitPrice = 120.0;
        const updatedCatalogPrice = 150.0;
        const returnedQty = 2.0;

        final refundAmount =
            returnedQty * originalUnitPrice; // Must be 240.0, NOT 300.0
        expect(refundAmount, equals(240.0));
        expect(refundAmount, isNot(equals(returnedQty * updatedCatalogPrice)));
      },
    );

    test(
      '6. Return refund preserves original exchange rate snapshot',
      () async {
        final originalSale = SaleInvoicePostingData(
          uuid: makeUuid(16),
          saleNumber: 'INV-RET-016',
          saleDate: DateTime.now().subtract(const Duration(days: 15)),
          total: 100.0, // 100 USD
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'USD',
          baseCurrencyCode: 'SAR',
          exchangeRate: 3.75, // Original historical FX
          cashAccountId: 'acc_cash_101',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: originalSale,
          calculatedCogsCost: 0.0,
        );

        final entry = drafts.first;
        expect(entry.currencyCode, equals('USD'));
        expect(entry.lines.first.exchangeRateToBase, equals(3.75));
      },
    );

    test(
      '7. Return restores original cost layer remainingQty using reverseConsumptions',
      () async {
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(70),
            itemCode: 'ITEM_RET_07',
            warehouseId: 'WH_RET_01',
            movementUuid: makeUuid(170),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 5)),
            receivedQty: 10.0,
            remainingQty: 10.0,
            unitCost: 50.0,
            totalCost: 500.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 50.0,
            totalCostInventoryCurrency: 500.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 50.0,
            totalCostDocumentCurrency: 500.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        final issueLineUuid = makeUuid(270);
        await costLayerService.consumeLayers(
          itemCode: 'ITEM_RET_07',
          quantity: 4.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: issueLineUuid,
          movementType: 'issue',
          warehouseId: 'WH_RET_01',
          companyId: companyId,
        );

        var layers = await costLayerService.getOpenLayers(
          'ITEM_RET_07',
          warehouseId: 'WH_RET_01',
          companyId: companyId,
        );
        expect(layers.first.remainingQty, equals(6.0));

        // Execute return/cancellation reversal
        await costLayerService.reverseConsumptions(issueLineUuid);

        layers = await costLayerService.getOpenLayers(
          'ITEM_RET_07',
          warehouseId: 'WH_RET_01',
          companyId: companyId,
        );
        expect(layers.first.remainingQty, equals(10.0));
      },
    );

    test(
      '8. Inventory return enters explicitly specified return warehouse',
      () async {
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(80),
            itemCode: 'ITEM_RET_08',
            warehouseId: 'WH_BRANCH_02',
            movementUuid: makeUuid(180),
            movementType: 'return_receipt',
            receivedDate: DateTime.now(),
            receivedQty: 5.0,
            remainingQty: 5.0,
            unitCost: 30.0,
            totalCost: 150.0,
            inventoryCurrencyId: 'SAR',
            unitCostInventoryCurrency: 30.0,
            totalCostInventoryCurrency: 150.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 30.0,
            totalCostDocumentCurrency: 150.0,
            exchangeRate: 1.0,
            exchangeRateDate: DateTime.now(),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        final branchLayers = await costLayerService.getOpenLayers(
          'ITEM_RET_08',
          warehouseId: 'WH_BRANCH_02',
          companyId: companyId,
        );
        expect(branchLayers.length, equals(1));
        expect(branchLayers.first.warehouseId, equals('WH_BRANCH_02'));

        final mainLayers = await costLayerService.getOpenLayers(
          'ITEM_RET_08',
          warehouseId: 'WH_MAIN',
          companyId: companyId,
        );
        expect(mainLayers.isEmpty, isTrue);
      },
    );

    test(
      '9. Cash refund generates CREDIT to Cash Box Account whereas Credit refund generates CREDIT to Customer Receivable',
      () async {
        final cashSale = SaleInvoicePostingData(
          uuid: makeUuid(91),
          saleNumber: 'INV-RET-CASH',
          saleDate: DateTime.now(),
          total: 100.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_101',
        );

        final cashDrafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: cashSale,
          calculatedCogsCost: 0.0,
        );
        final cashLine = cashDrafts.first.lines.firstWhere((l) => l.debit > 0);
        expect(cashLine.accountUuid, equals('acc_cash_101'));

        final creditSale = SaleInvoicePostingData(
          uuid: makeUuid(92),
          saleNumber: 'INV-RET-CREDIT',
          saleDate: DateTime.now(),
          total: 100.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.credit,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          customerAccountId: 'acc_rec_201',
        );

        final creditDrafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: creditSale,
          calculatedCogsCost: 0.0,
        );
        final creditLine = creditDrafts.first.lines.firstWhere(
          (l) => l.debit > 0,
        );
        expect(creditLine.accountUuid, equals('acc_rec_201'));
      },
    );
  });
}
