import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';

import 'tables/sale_items_table.dart';
import 'tables/sale_payments_table.dart';
import 'tables/sales_table.dart';

part 'sales_database.g.dart';

@DriftDatabase(tables: [Sales, SaleItems, SalePayments])
class SalesDatabase extends _$SalesDatabase {
  SalesDatabase({String? name, QueryExecutor? executor})
    : super(executor ?? _openConnection(name ?? 'sales_master'));

  /// In-memory database for tests.
  SalesDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(sales, sales.saleDate);
        await m.addColumn(sales, sales.settlementType);
        await m.addColumn(sales, sales.voucherBookId);
        await m.addColumn(sales, sales.customerAccountId);
        await m.addColumn(sales, sales.cashAccountId);
        await m.addColumn(sales, sales.currencyCode);
        await m.addColumn(sales, sales.baseCurrencyCode);
        await m.addColumn(sales, sales.exchangeRate);
        await m.addColumn(saleItems, saleItems.baseUnitPrice);
        await customStatement(
          'UPDATE sales SET sale_date = created_at '
          'WHERE sale_date IS NULL OR sale_date = 0',
        );
      }
      if (from < 3) {
        await m.addColumn(saleItems, saleItems.mainQuantity);
        await m.addColumn(saleItems, saleItems.subQuantity);
        await m.addColumn(saleItems, saleItems.packSize);
        await customStatement(
          'UPDATE sale_items SET main_quantity = quantity, '
          'sub_quantity = 0, pack_size = 1 '
          'WHERE main_quantity = 0 AND sub_quantity = 0',
        );
      }
      if (from < 4) {
        await _createIndexes();
      }
      if (from < 5) {
        await m.addColumn(sales, sales.companyId);
        await customStatement(
          "UPDATE sales SET company_id = 'local-company' WHERE company_id IS NULL",
        );
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_sales_number_active '
      'ON sales (sale_number) WHERE deleted_at IS NULL',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales (customer_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_status ON sales (sale_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_payment ON sales (payment_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_sync ON sales (sync_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_created ON sales (created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_date ON sales (sale_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_customer_name '
      'ON sales (customer_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items (sale_uuid)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_product '
      'ON sale_items (product_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_name ON sale_items (product_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sale_payments_sale '
      'ON sale_payments (sale_uuid)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sales_status_date '
      'ON sales (company_id, sale_status, sale_date) WHERE deleted_at IS NULL',
    );
  }

  static QueryExecutor _openConnection(String name) {
    return encryptedDriftDatabase(name: name);
  }
}
