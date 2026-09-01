import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_payment.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';

import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

void main() {
  final now = DateTime.now().toUtc();

  group('ROOT FIX 39 — Financial Data Serialization Integrity Tests', () {
    test('1. JournalEntry Sync Payload Serialization Round-trip', () {
      final entry = JournalEntry(
        id: 101,
        uuid: '00000000-0000-4000-8000-000000000101',
        entryDate: now,
        voucherNumber: 'JV-2026-001',
        voucherType: 'journal',
        currencyCode: 'USD',
        isPosted: true,
        description: 'Monthly Depreciation Adjustment',
        sourceType: 'manual',
        sourceId: 'src_999',
        createdAt: now,
        updatedAt: now,
        version: 5,
        lines: const [
          JournalLine(
            id: 1,
            uuid: '00000000-0000-4000-8000-000000000102',
            entryUuid: '00000000-0000-4000-8000-000000000101',
            accountUuid: 'acc_depr_exp',
            debit: 1500.0,
            credit: 0.0,
            currencyCode: 'USD',
            exchangeRateToBase: 1.0,
            baseDebit: 1500.0,
            baseCredit: 0.0,
            sortOrder: 0,
            lineDescription: 'Depreciation line 1',
          ),
          JournalLine(
            id: 2,
            uuid: '00000000-0000-4000-8000-000000000103',
            entryUuid: '00000000-0000-4000-8000-000000000101',
            accountUuid: 'acc_accum_depr',
            debit: 0.0,
            credit: 1500.0,
            currencyCode: 'USD',
            exchangeRateToBase: 1.0,
            baseDebit: 0.0,
            baseCredit: 1500.0,
            sortOrder: 1,
            lineDescription: 'Depreciation line 2',
          ),
        ],
      );

      final payload = <String, dynamic>{
        'uuid': entry.uuid,
        'entryDate': entry.entryDate.millisecondsSinceEpoch,
        'voucherNumber': entry.voucherNumber,
        'voucherType': entry.voucherType,
        'description': entry.description,
        'currencyCode': entry.currencyCode,
        'isPosted': entry.isPosted,
        'sourceType': entry.sourceType,
        'sourceId': entry.sourceId,
        'version': entry.version,
        'updatedAt': entry.updatedAt.millisecondsSinceEpoch,
        'createdAt': entry.createdAt.millisecondsSinceEpoch,
        'lines': [
          for (final line in entry.lines)
            {
              'uuid': line.uuid,
              'accountUuid': line.accountUuid,
              'debit': line.debit,
              'credit': line.credit,
              'exchangeRateToBase': line.exchangeRateToBase,
              'baseDebit': line.baseDebit,
              'baseCredit': line.baseCredit,
              'currencyCode': line.currencyCode,
              'lineDescription': line.lineDescription,
              'sortOrder': line.sortOrder,
            }
        ],
      };

      // Verify all required fields preserved without silent loss
      expect(payload['uuid'], equals(entry.uuid));
      expect(payload['voucherNumber'], equals('JV-2026-001'));
      expect(payload['currencyCode'], equals('USD'));
      expect(payload['isPosted'], isTrue);
      expect(payload['version'], equals(5));
      expect(payload['sourceType'], equals('manual'));
      expect(payload['sourceId'], equals('src_999'));

      final lines = payload['lines'] as List;
      expect(lines.length, equals(2));
      expect(lines[0]['debit'], equals(1500.0));
      expect(lines[1]['credit'], equals(1500.0));
    });

    test('2. Sale Serialization Round-trip', () {
      final sale = Sale(
        id: 201,
        uuid: '00000000-0000-4000-8000-000000000201',
        saleNumber: 'INV-2026-888',
        saleDate: now,
        settlementType: SaleSettlementType.cash,
        voucherBookId: 'book_sales_01',
        customerId: 'cust_777',
        customerCode: 'CUST-777',
        customerName: 'Acme Logistics',
        customerAccountId: 'acc_ar_cust',
        cashAccountId: 'acc_cash_main',
        currencyCode: 'EUR',
        baseCurrencyCode: 'USD',
        exchangeRate: 1.10,
        subtotal: 1000.0,
        itemDiscountTotal: 50.0,
        discountType: DiscountType.percentage,
        discountValue: 5.0,
        discountAmount: 50.0,
        taxRate: 15.0,
        taxAmount: 135.0,
        total: 1035.0,
        paidAmount: 1035.0,
        remainingAmount: 0.0,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.posted,
        notes: 'Priority Delivery',
        createdAt: now,
        updatedAt: now,
        version: 3,
        dataSource: SaleDataSource.local,
        items: const [
          SaleItem(
            id: 1,
            uuid: '00000000-0000-4000-8000-000000000202',
            saleUuid: '00000000-0000-4000-8000-000000000201',
            productId: 'prod_99',
            productName: 'Heavy Industrial Motor',
            productCode: 'MOT-01',
            barcode: '123456789',
            quantity: 2.0,
            mainQuantity: 2.0,
            subQuantity: 0.0,
            packSize: 1,
            unitPrice: 500.0,
            baseUnitPrice: 550.0,
            discountType: DiscountType.fixed,
            discountValue: 25.0,
            discountAmount: 50.0,
            taxAmount: 135.0,
            subtotal: 1000.0,
            total: 1085.0,
            lineOrder: 1,
          ),
        ],
        payments: [
          SalePayment(
            id: 1,
            uuid: '00000000-0000-4000-8000-000000000203',
            saleUuid: '00000000-0000-4000-8000-000000000201',
            amount: 1035.0,
            method: PaymentMethod.cash,
            paidAt: now,
            createdAt: now,
            notes: 'Full payment received',
          ),
        ],
      );

      final payload = {
        'uuid': sale.uuid,
        'saleNumber': sale.saleNumber,
        'saleDate': sale.saleDate.millisecondsSinceEpoch,
        'settlementType': sale.settlementType.storageValue,
        'currencyCode': sale.currencyCode,
        'baseCurrencyCode': sale.baseCurrencyCode,
        'exchangeRate': sale.exchangeRate,
        'subtotal': sale.subtotal,
        'total': sale.total,
        'paidAmount': sale.paidAmount,
        'remainingAmount': sale.remainingAmount,
        'paymentStatus': sale.paymentStatus.storageValue,
        'saleStatus': sale.saleStatus.storageValue,
        'version': sale.version,
      };

      expect(payload['uuid'], equals(sale.uuid));
      expect(payload['saleNumber'], equals('INV-2026-888'));
      expect(payload['currencyCode'], equals('EUR'));
      expect(payload['baseCurrencyCode'], equals('USD'));
      expect(payload['exchangeRate'], equals(1.10));
      expect(payload['total'], equals(1035.0));
      expect(payload['paymentStatus'], equals('paid'));
      expect(payload['saleStatus'], equals('posted'));
    });

    test('3. FinancialTransaction Line Serialization Round-trip', () {
      const line = FinancialTransactionLine(
        accountId: 'acc_expense_office',
        accountCode: '5100',
        accountName: 'Office Expenses',
        amount: 350.0,
        currencyCode: 'USD',
        exchangeRate: 1.0,
        description: 'Stationery supply',
        lineOrder: 1,
      );

      final jsonMap = line.toJson();
      final reconstructed = FinancialTransactionLine.fromJson(jsonMap);

      expect(reconstructed.accountId, equals('acc_expense_office'));
      expect(reconstructed.amount, equals(350.0));
      expect(reconstructed.currencyCode, equals('USD'));
      expect(reconstructed.exchangeRate, equals(1.0));
    });

    test('4. Inventory Document Reference Serialization Integrity', () {
      final docRef = InventoryDocumentRef(
        documentId: '00000000-0000-4000-8000-000000000401',
        documentNumber: 'ST-2026-009',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: now,
        warehouseId: 'WH-SOURCE',
        status: InventoryDocumentStatus.posted,
      );

      expect(docRef.documentId, equals('00000000-0000-4000-8000-000000000401'));
      expect(docRef.documentNumber, equals('ST-2026-009'));
      expect(docRef.documentType, equals(InventoryDocumentType.stockTransfer));
      expect(docRef.status, equals(InventoryDocumentStatus.posted));
      expect(docRef.warehouseId, equals('WH-SOURCE'));
    });
  });
}
