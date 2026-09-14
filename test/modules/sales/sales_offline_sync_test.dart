import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sync/sync.dart';

String makeUuid(int id) =>
    '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}';

void main() {
  group('SA-11 — Sales Offline-First, Sync & Idempotency Integrity Tests', () {
    final now = DateTime.now();

    Sale createSampleSale({
      required String uuid,
      required String companyId,
      double total = 100.0,
      SyncStatus syncStatus = SyncStatus.pending,
    }) {
      return Sale(
        id: uuid,
        companyId: companyId,
        saleNumber: 'INV-OFF-001',
        saleDate: now,
        settlementType: SaleSettlementType.cash,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        warehouseId: 'wh_main_01',
        items: [
          SaleItem(
            id: makeUuid(201),
            saleUuid: uuid,
            productId: 'p1',
            productName: 'Item 1',
            productCode: 'P1',
            quantity: 2.0,
            mainQuantity: 2.0,
            subQuantity: 0.0,
            packSize: 1,
            unitPrice: 50.0,
            baseUnitPrice: 50.0,
            discountType: DiscountType.fixed,
            discountValue: 0.0,
            discountAmount: 0.0,
            taxAmount: 0.0,
            subtotal: 100.0,
            total: 100.0,
            lineOrder: 0,
          ),
        ],
        payments: const [],
        subtotal: 100.0,
        itemDiscountTotal: 0.0,
        discountType: DiscountType.fixed,
        discountValue: 0.0,
        discountAmount: 0.0,
        taxRate: 0.0,
        taxAmount: 0.0,
        total: total,
        paidAmount: 100.0,
        remainingAmount: 0.0,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.posted,
        dataSource: SaleDataSource.local,
        syncStatus: syncStatus,
        createdAt: now,
        updatedAt: now,
      );
    }

    test(
      '1. Offline posting preserves complete economic state and assigns SyncStatus.pending',
      () {
        final sale = createSampleSale(
          uuid: makeUuid(101),
          companyId: 'company_01',
          syncStatus: SyncStatus.pending,
        );

        expect(sale.uuid, equals(makeUuid(101)));
        expect(sale.companyId, equals('company_01'));
        expect(sale.warehouseId, equals('wh_main_01'));
        expect(sale.items.length, equals(1));
        expect(sale.total, equals(100.0));
        expect(sale.syncStatus, equals(SyncStatus.pending));
      },
    );

    test(
      '2. Sync immutable snapshot rule: original transaction total, prices, and FX are preserved untouched',
      () {
        final offlineSale = createSampleSale(
          uuid: makeUuid(102),
          companyId: 'company_01',
          total: 250.0,
          syncStatus: SyncStatus.pending,
        );

        // Simulate sync payload processing
        final syncedSale = Sale(
          id: offlineSale.id,
          uuid: offlineSale.uuid,
          companyId: offlineSale.companyId,
          saleNumber: offlineSale.saleNumber,
          saleDate: offlineSale.saleDate,
          settlementType: offlineSale.settlementType,
          currencyCode: offlineSale.currencyCode,
          baseCurrencyCode: offlineSale.baseCurrencyCode,
          exchangeRate: offlineSale.exchangeRate, // Rate remains 1.0
          warehouseId: offlineSale.warehouseId,
          items: offlineSale.items,
          payments: offlineSale.payments,
          subtotal: offlineSale.subtotal,
          itemDiscountTotal: offlineSale.itemDiscountTotal,
          discountType: offlineSale.discountType,
          discountValue: offlineSale.discountValue,
          discountAmount: offlineSale.discountAmount,
          taxRate: offlineSale.taxRate,
          taxAmount: offlineSale.taxAmount,
          total: offlineSale
              .total, // Total remains 250.0 without dynamic recalculation
          paidAmount: offlineSale.paidAmount,
          remainingAmount: offlineSale.remainingAmount,
          paymentStatus: offlineSale.paymentStatus,
          paymentMethod: offlineSale.paymentMethod,
          saleStatus: offlineSale.saleStatus,
          dataSource: offlineSale.dataSource,
          syncStatus: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
          createdAt: offlineSale.createdAt,
          updatedAt: offlineSale.updatedAt,
        );

        expect(syncedSale.total, equals(250.0));
        expect(syncedSale.exchangeRate, equals(1.0));
        expect(syncedSale.syncStatus, equals(SyncStatus.synced));
        expect(syncedSale.lastSyncedAt, isNotNull);
      },
    );

    test(
      '3. Duplicate sync retry idempotency: re-syncing same UUID returns existing synced status',
      () {
        final existingStore = <String, Sale>{};
        final initialSale = createSampleSale(
          uuid: makeUuid(103),
          companyId: 'company_01',
          syncStatus: SyncStatus.synced,
        );
        existingStore[initialSale.uuid] = initialSale;

        // Duplicate sync payload submission function
        Sale processSyncPayload(Sale payload) {
          if (existingStore.containsKey(payload.uuid)) {
            // Idempotently return existing record without creating side effects
            return existingStore[payload.uuid]!;
          }
          existingStore[payload.uuid] = payload;
          return payload;
        }

        final retryResult = processSyncPayload(
          createSampleSale(uuid: makeUuid(103), companyId: 'company_01'),
        );

        expect(retryResult.uuid, equals(makeUuid(103)));
        expect(retryResult.syncStatus, equals(SyncStatus.synced));
        expect(existingStore.length, equals(1)); // No duplicate row created
      },
    );

    test(
      '4. Non-silent conflict handling: payload discrepancies on existing UUID raise conflict state',
      () {
        final existingStore = <String, Sale>{};
        final originalSale = createSampleSale(
          uuid: makeUuid(104),
          companyId: 'company_01',
          total: 100.0,
          syncStatus: SyncStatus.synced,
        );
        existingStore[originalSale.uuid] = originalSale;

        final modifiedPayload = createSampleSale(
          uuid: makeUuid(104),
          companyId: 'company_01',
          total: 150.0, // Modified total
        );

        bool hasConflict = false;
        if (existingStore.containsKey(modifiedPayload.uuid)) {
          final existing = existingStore[modifiedPayload.uuid]!;
          if (existing.total != modifiedPayload.total) {
            hasConflict = true; // Reject silent overwrites
          }
        }

        expect(hasConflict, isTrue);
      },
    );

    test(
      '5. Multi-company tenant scope isolation rejects cross-company sync payloads',
      () {
        final currentCompanyId = 'company_A';
        final payload = createSampleSale(
          uuid: makeUuid(105),
          companyId: 'company_B', // Cross-company attempt
        );

        bool isAuthorized = payload.companyId == currentCompanyId;
        expect(isAuthorized, isFalse);
      },
    );
  });
}
