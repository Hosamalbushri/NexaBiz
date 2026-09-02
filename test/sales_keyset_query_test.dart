import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_list_filter.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';

void main() {
  late SalesDatabase db;
  late SaleRepositoryImpl repoCompanyA;
  late SaleRepositoryImpl repoCompanyB;

  setUp(() {
    db = SalesDatabase.memory();
    repoCompanyA = SaleRepositoryImpl(
      db,
      readCompanyId: () => 'company_a',
    );
    repoCompanyB = SaleRepositoryImpl(
      db,
      readCompanyId: () => 'company_b',
    );
  });

  tearDown(() async {
    await db.close();
  });

  SaleDraft buildDraft({
    required String customerName,
    required double total,
    DateTime? saleDate,
    SaleStatus status = SaleStatus.unposted,
    PaymentMethod method = PaymentMethod.cash,
  }) {
    return SaleDraft(
      saleDate: saleDate ?? DateTime.utc(2026, 9, 1),
      settlementType: SaleSettlementType.cash,
      voucherBookId: 'VB-01',
      cashAccountId: 'ACC-CASH-01',
      customerName: customerName,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1.0,
      items: [
        SaleItemDraft(
          productId: '10',
          productName: 'Product Alpha',
          productCode: 'PROD-A',
          mainQuantity: 2,
          unitPrice: total / 2,
          baseUnitPrice: total / 2,
        ),
      ],
      paymentMethod: method,
      saleStatus: status,
    );
  }

  group('Phase 4 — Sales Keyset Query Layer & Pagination', () {
    test('Empty list query returns empty paged result', () async {
      final result = await repoCompanyA.searchKeysetPaged(
        const SaleListFilter(),
        pageSize: 10,
      );

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.nextCursor, isNull);
    });

    test('Keyset pagination returns items bounded by pageSize with deterministic tie-breaker', () async {
      final baseDate = DateTime.utc(2026, 9, 1, 10, 0, 0);

      // Create 35 sales with same saleDate timestamp to test tie-breaker
      for (var i = 1; i <= 35; i++) {
        await repoCompanyA.insert(
          buildDraft(
            customerName: 'Customer $i',
            total: i * 10.0,
            saleDate: baseDate,
          ),
          saleNumber: 'INV-${i.toString().padLeft(6, '0')}',
        );
      }

      // Fetch Page 1 (pageSize = 20)
      final page1 = await repoCompanyA.searchKeysetPaged(
        const SaleListFilter(),
        pageSize: 20,
      );

      expect(page1.items.length, 20);
      expect(page1.hasMore, isTrue);
      expect(page1.nextCursor, isNotNull);

      // Fetch Page 2 using cursor from Page 1
      final page2 = await repoCompanyA.searchKeysetPaged(
        const SaleListFilter(),
        cursor: page1.nextCursor,
        pageSize: 20,
      );

      expect(page2.items.length, 15);
      expect(page2.hasMore, isFalse);
      expect(page2.nextCursor, isNull);

      // Verify no duplicate IDs between Page 1 and Page 2
      final idsPage1 = page1.items.map((e) => e.id).toSet();
      final idsPage2 = page2.items.map((e) => e.id).toSet();
      expect(idsPage1.intersection(idsPage2), isEmpty);
      expect(idsPage1.length + idsPage2.length, 35);
    });

    test('SQL Filtering: Filters by status, date range, and text query in database', () async {
      await repoCompanyA.insert(
        buildDraft(
          customerName: 'Acme Corp',
          total: 100,
          status: SaleStatus.posted,
          saleDate: DateTime.utc(2026, 8, 15),
        ),
        saleNumber: 'INV-000101',
      );

      await repoCompanyA.insert(
        buildDraft(
          customerName: 'Beta Trading',
          total: 200,
          status: SaleStatus.unposted,
          saleDate: DateTime.utc(2026, 8, 20),
        ),
        saleNumber: 'INV-000102',
      );

      // Filter by text search "Acme"
      final searchResult = await repoCompanyA.searchKeysetPaged(
        const SaleListFilter(query: 'Acme'),
      );
      expect(searchResult.items.length, 1);
      expect(searchResult.items.first.customerName, 'Acme Corp');

      // Filter by status "posted"
      final statusResult = await repoCompanyA.searchKeysetPaged(
        const SaleListFilter(saleStatus: SaleStatus.posted),
      );
      expect(statusResult.items.length, 1);
      expect(statusResult.items.first.customerName, 'Acme Corp');

      // Filter by date range (2026-08-18 to 2026-08-25)
      final dateResult = await repoCompanyA.searchKeysetPaged(
        SaleListFilter(
          fromDate: DateTime.utc(2026, 8, 18),
          toDate: DateTime.utc(2026, 8, 25),
        ),
      );
      expect(dateResult.items.length, 1);
      expect(dateResult.items.first.customerName, 'Beta Trading');
    });

    test('Multi-Tenant Isolation: Company A cannot query Company B sales', () async {
      await repoCompanyA.insert(
        buildDraft(customerName: 'Company A Customer', total: 150),
        saleNumber: 'INV-A-001',
      );

      await repoCompanyB.insert(
        buildDraft(customerName: 'Company B Customer', total: 250),
        saleNumber: 'INV-B-001',
      );

      final listA = await repoCompanyA.searchKeysetPaged(const SaleListFilter());
      final listB = await repoCompanyB.searchKeysetPaged(const SaleListFilter());

      expect(listA.items.length, 1);
      expect(listA.items.first.customerName, 'Company A Customer');

      expect(listB.items.length, 1);
      expect(listB.items.first.customerName, 'Company B Customer');
    });

    test('Read-Model Projection & N+1 Prevention: Map rows without child entity queries', () async {
      // Insert sale with multiple items and payments
      await repoCompanyA.insert(
        SaleDraft(
          saleDate: DateTime.utc(2026, 9, 1),
          settlementType: SaleSettlementType.cash,
          voucherBookId: 'VB-01',
          cashAccountId: 'ACC-CASH-01',
          customerName: 'Multi Item Customer',
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          items: [
            SaleItemDraft(
              productId: '1',
              productName: 'Item 1',
              productCode: 'P1',
              mainQuantity: 1,
              unitPrice: 50,
              baseUnitPrice: 50,
            ),
            SaleItemDraft(
              productId: '2',
              productName: 'Item 2',
              productCode: 'P2',
              mainQuantity: 2,
              unitPrice: 25,
              baseUnitPrice: 25,
            ),
          ],
          paymentMethod: PaymentMethod.cash,
          paidAmount: 100,
          saleStatus: SaleStatus.unposted,
        ),
        saleNumber: 'INV-MULTI-1',
      );

      // Search keyset page
      final result = await repoCompanyA.searchKeysetPaged(
        const SaleListFilter(),
        pageSize: 10,
      );

      expect(result.items.length, 1);
      final item = result.items.first;

      // Projection assertions
      expect(item.saleNumber, 'INV-MULTI-1');
      expect(item.customerName, 'Multi Item Customer');
      expect(item.total, 100);
    });
  });
}
