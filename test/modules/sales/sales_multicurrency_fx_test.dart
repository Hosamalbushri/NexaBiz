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
        accountUuid: 'acc_cash_01',
        accountCode: '1010',
        accountName: 'Cash',
      ),
      AccountRole.receivable: const AccountRoleRef(
        role: AccountRole.receivable,
        accountUuid: 'acc_rec_01',
        accountCode: '1100',
        accountName: 'Receivable',
      ),
      AccountRole.revenue: const AccountRoleRef(
        role: AccountRole.revenue,
        accountUuid: 'acc_rev_01',
        accountCode: '4010',
        accountName: 'Revenue',
      ),
      AccountRole.cogs: const AccountRoleRef(
        role: AccountRole.cogs,
        accountUuid: 'acc_cogs_01',
        accountCode: '5010',
        accountName: 'COGS',
      ),
      AccountRole.inventory: const AccountRoleRef(
        role: AccountRole.inventory,
        accountUuid: 'acc_inv_01',
        accountCode: '1200',
        accountName: 'Inventory',
      ),
    });
  }
}

void main() {
  group('SA-06 — Sales Multi-Currency & FX Integrity Tests', () {
    late InventoryDatabase db;
    late CostLayerServiceImpl costLayerService;
    late AccountingEntryBuilder entryBuilder;
    const companyId = 'comp_fx_01';

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
      '1. Multi-currency distinction between Document Currency (SAR) and Inventory Valuation Currency (YER)',
      () async {
        // Create receipt cost layer in YER: 1 unit @ 1,400 YER (original receipt 10 SAR with FX=140)
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(1),
            itemCode: 'ITEM_FX_01',
            warehouseId: 'WH_MAIN',
            movementUuid: makeUuid(101),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 10)),
            receivedQty: 1.0,
            remainingQty: 1.0,
            unitCost: 1400.0,
            totalCost: 1400.0,
            inventoryCurrencyId: 'YER',
            unitCostInventoryCurrency: 1400.0,
            totalCostInventoryCurrency: 1400.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 10.0,
            exchangeRate: 140.0,
            exchangeRateDate: DateTime.now().subtract(const Duration(days: 10)),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Consume cost layer for a Sale of 10 SAR
        final consumptionResult = await costLayerService.consumeLayers(
          itemCode: 'ITEM_FX_01',
          quantity: 1.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: makeUuid(201),
          movementType: 'issue',
          warehouseId: 'WH_MAIN',
          companyId: companyId,
        );

        // Inventory COGS cost layer is authoritative in YER: 1,400 YER
        expect(consumptionResult.totalCost, equals(1400.0));
        expect(consumptionResult.effectiveUnitCost, equals(1400.0));

        // Generate Accounting Entry Drafts: Sale total = 10 SAR (Document Currency)
        final sale = SaleInvoicePostingData(
          uuid: makeUuid(301),
          saleNumber: 'INV-FX-100',
          saleDate: DateTime.now(),
          total: 10.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_01',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: consumptionResult.totalCost,
        );

        final revenueEntry = drafts.firstWhere((d) => d.sourceType == 'sale');
        expect(revenueEntry.currencyCode, equals('SAR'));
        expect(
          revenueEntry.lines.firstWhere((l) => l.debit > 0).debit,
          equals(10.0),
        );

        final cogsEntry = drafts.firstWhere((d) => d.sourceType == 'sale_cogs');
        expect(
          cogsEntry.lines.firstWhere((l) => l.debit > 0).debit,
          equals(1400.0),
        );
      },
    );

    test(
      '2. Historical COGS is preserved when market FX rate changes from 140 to 150 later',
      () async {
        // Historical layer created when FX = 140 -> 1,400 YER
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(2),
            itemCode: 'ITEM_FX_02',
            warehouseId: 'WH_MAIN',
            movementUuid: makeUuid(102),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 30)),
            receivedQty: 1.0,
            remainingQty: 1.0,
            unitCost: 1400.0,
            totalCost: 1400.0,
            inventoryCurrencyId: 'YER',
            unitCostInventoryCurrency: 1400.0,
            totalCostInventoryCurrency: 1400.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 10.0,
            exchangeRate: 140.0, // Historical rate at receipt
            exchangeRateDate: DateTime.now().subtract(const Duration(days: 30)),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        // Now at sale time, market FX rate is 150 (10 SAR * 150 = 1500 YER)
        // BUT inventory cost layer consumption MUST preserve historical valuation (1,400 YER) and NOT transform to 1,500 YER
        final consumptionResult = await costLayerService.consumeLayers(
          itemCode: 'ITEM_FX_02',
          quantity: 1.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: makeUuid(202),
          movementType: 'issue',
          warehouseId: 'WH_MAIN',
          companyId: companyId,
        );

        expect(consumptionResult.totalCost, equals(1400.0));
        expect(consumptionResult.totalCost, isNot(equals(1500.0)));
      },
    );

    test('3. Sales FX rate persistence in journal entry line drafts', () async {
      final sale = SaleInvoicePostingData(
        uuid: makeUuid(303),
        saleNumber: 'INV-FX-103',
        saleDate: DateTime.now(),
        total: 100.0, // 100 USD
        itemDiscountTotal: 0.0,
        discountAmount: 0.0,
        taxAmount: 0.0,
        settlementType: PostingSettlementType.cash,
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: 3.75, // Persisted rate: 1 USD = 3.75 SAR
        cashAccountId: 'acc_cash_01',
      );

      final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
        sale: sale,
        calculatedCogsCost: 0.0,
      );

      final entry = drafts.first;
      expect(entry.currencyCode, equals('USD'));
      expect(entry.lines.every((l) => l.exchangeRateToBase == 3.75), isTrue);
    });

    test(
      '4. Return & reversal restores layer with original historical cost layer valuation',
      () async {
        await costLayerService.createLayer(
          CostLayer(
            id: makeUuid(4),
            itemCode: 'ITEM_FX_04',
            warehouseId: 'WH_MAIN',
            movementUuid: makeUuid(104),
            movementType: 'receipt',
            receivedDate: DateTime.now().subtract(const Duration(days: 5)),
            receivedQty: 5.0,
            remainingQty: 5.0,
            unitCost: 1400.0,
            totalCost: 7000.0,
            inventoryCurrencyId: 'YER',
            unitCostInventoryCurrency: 1400.0,
            totalCostInventoryCurrency: 7000.0,
            documentCurrencyId: 'SAR',
            unitCostDocumentCurrency: 10.0,
            totalCostDocumentCurrency: 50.0,
            exchangeRate: 140.0,
            exchangeRateDate: DateTime.now().subtract(const Duration(days: 5)),
            closed: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            companyId: companyId,
          ),
        );

        final issueUuid = makeUuid(204);
        await costLayerService.consumeLayers(
          itemCode: 'ITEM_FX_04',
          quantity: 2.0,
          method: CostValuationMethod.fifo,
          issueLineUuid: issueUuid,
          movementType: 'issue',
          warehouseId: 'WH_MAIN',
          companyId: companyId,
        );

        // Remaining layer quantity is 3.0
        var openLayers = await costLayerService.getOpenLayers(
          'ITEM_FX_04',
          warehouseId: 'WH_MAIN',
          companyId: companyId,
        );
        expect(openLayers.first.remainingQty, equals(3.0));

        // Reversing consumption restores original 5.0 remaining quantity at 1,400 YER unit cost
        await costLayerService.reverseConsumptions(issueUuid);

        openLayers = await costLayerService.getOpenLayers(
          'ITEM_FX_04',
          warehouseId: 'WH_MAIN',
          companyId: companyId,
        );
        expect(openLayers.first.remainingQty, equals(5.0));
        expect(openLayers.first.unitCostInventoryCurrency, equals(1400.0));
      },
    );
  });
}
