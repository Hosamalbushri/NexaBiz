import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/purchases/data/repositories/purchase_repository_impl.dart';

void main() {
  group('Canonical Architecture & Negative Legacy-Write Invariants', () {
    late NexabizDatabase db;

    setUp(() {
      db = NexabizDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('SaleRepositoryImpl fails fast when active company context is missing', () {
      final repo = SaleRepositoryImpl(db, readCompanyId: () => '');
      expect(
        () => repo.getById(1),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Active company scope context is required'),
        )),
      );
    });

    test('FinancialTransactionRepositoryImpl fails fast when active company context is missing', () {
      final repo = FinancialTransactionRepositoryImpl(db, readCompanyId: () => '');
      expect(
        () => repo.getById(1),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Active company scope context is required'),
        )),
      );
    });

    test('PurchaseRepositoryImpl fails fast when active company context is missing', () {
      final repo = PurchaseRepositoryImpl(db, readCompanyId: () => '');
      expect(
        () => repo.getPurchaseInvoiceById('inv-1'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Active company scope context is required'),
        )),
      );
    });

    test('NexabizDatabase initializes canonical schema version 12 without legacy multi-db tables', () async {
      expect(db.schemaVersion, equals(12));
      final result = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table'").get();
      final tableNames = result.map((r) => r.read<String>('name')).toList();
      
      // Mandatory canonical tables must exist
      expect(tableNames, containsAll([
        'sales',
        'sale_items',
        'purchases',
        'purchase_items',
        'financial_transactions',
        'stock_movement_ledgers',
        'journal_entries',
        'accounts',
        'products',
        'customers',
        'suppliers',
      ]));

      // Verify legacy isolated database tables do NOT exist in nexabiz.sqlite
      expect(tableNames, isNot(contains('legacy_sales_db')));
      expect(tableNames, isNot(contains('legacy_inventory_db')));
    });
  });
}
