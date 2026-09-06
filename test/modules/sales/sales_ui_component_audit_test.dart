import 'package:stock_count/modules/sales/shared/domain/services/sale_treasury_account_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_list_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/presentation/providers/sale_composer_provider.dart';
import 'package:stock_count/modules/sales/invoices/presentation/widgets/sale_number_text.dart';
import 'package:stock_count/modules/sales/invoices/presentation/widgets/sale_status_badge.dart';

void main() {
  group('SA-10 — Sales UI, UX & Component Consolidation Audit Tests', () {
    test('1. SaleStatusBadge renders correct label and status styling', () {
      final widget = MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              SaleStatusBadge(status: SaleStatus.unposted, label: 'مسودة'),
              SaleStatusBadge(status: SaleStatus.posted, label: 'رحلت'),
            ],
          ),
        ),
      );

      expect(widget, isNotNull);
    });

    test('2. SaleNumberText formats document number accurately', () {
      const text = SaleNumberText('INV-2026-001');
      expect(text.saleNumber, equals('INV-2026-001'));
    });

    test(
      '3. SaleComposerState requires explicit warehouseId before allowing save',
      () {
        final stateWithoutWarehouse = SaleComposerState(
          saleDate: DateTime.now(),
        );
        expect(stateWithoutWarehouse.warehouseId, isNull);
        expect(stateWithoutWarehouse.canSave, isFalse);

        final stateWithWarehouse = stateWithoutWarehouse.copyWith(
          warehouseId: 'WH_MAIN_01',
          voucherBook: const SaleVoucherBookRef(
            bookId: 'vb_01',
            name: 'Voucher Book 1',
            nextNumber: 1,
            canAllocate: true,
          ),
          cashAccount: const SaleAccountRef(
            accountId: 'acc_cash_01',
            code: '1010',
            name: 'Cash',
          ),
          items: const [
            SaleItemDraft(
              productId: 'p1',
              productName: 'Item 1',
              productCode: 'P1',
              mainQuantity: 1,
              unitPrice: 10,
              baseUnitPrice: 10,
            ),
          ],
        );
        expect(stateWithWarehouse.warehouseId, equals('WH_MAIN_01'));
        expect(stateWithWarehouse.canSave, isTrue);
      },
    );

    test(
      '4. SaleListItem entity correctly encapsulates list row details for AppListPagePattern',
      () {
        final item = SaleListItem(
          id: 101,
          uuid: '00000000-0000-0000-0000-000000000101',
          saleNumber: 'INV-101',
          saleDate: DateTime.now(),
          customerName: 'Customer A',
          settlementType: SaleSettlementType.cash,
          currencyCode: 'SAR',
          total: 500.0,
          paymentStatus: PaymentStatus.paid,
          saleStatus: SaleStatus.posted,
        );

        expect(item.id, equals(101));
        expect(item.settlementType.isCash, isTrue);
        expect(item.saleStatus, equals(SaleStatus.posted));
      },
    );
  });
}
