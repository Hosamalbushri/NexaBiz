import 'package:drift/drift.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';
import 'package:stock_count/core/utils/id_generator.dart';

import 'canonical_db_metadata_table.dart';
import 'tables/users_table.dart';
import 'tables/companies_table.dart';
import 'tables/company_memberships_table.dart';
import 'tables/currencies_table.dart';
import 'tables/product_categories_table.dart';
import 'tables/warehouses_table.dart';
import 'tables/accounts_table.dart';
import 'tables/products_table.dart';
import 'tables/customers_table.dart';
import 'tables/cash_registers_table.dart';
import 'tables/voucher_books_table.dart';

import 'package:stock_count/modules/inventory/shared/data/database/tables/stock_movement_ledgers_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/stock_movement_lines_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/inventory_cost_layers_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/inventory_cost_consumptions_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/product_warehouse_stocks_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/stock_receipts_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/stock_issues_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/stock_returns_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/stock_transfers_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/inventory_audit_trail_table.dart';
import 'package:stock_count/modules/inventory/shared/data/database/tables/warehouse_accounting_bindings_table.dart';

import 'package:stock_count/modules/sales/shared/data/database/tables/sales_table.dart';
import 'package:stock_count/modules/sales/shared/data/database/tables/sale_items_table.dart';
import 'package:stock_count/modules/sales/shared/data/database/tables/sale_payments_table.dart';

import 'package:stock_count/modules/receipts_payments/shared/data/database/tables/financial_transactions_table.dart';

import 'package:stock_count/modules/accounting/shared/data/database/tables/journal_entries_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/journal_lines_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/fiscal_years_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/accounting_periods_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/period_closing_records_table.dart';
import 'package:stock_count/core/database/tables/suppliers_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/currency_rates_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/currency_rate_history_table.dart';
import 'package:stock_count/modules/accounting/shared/data/database/tables/account_currency_balances_table.dart';
import 'package:stock_count/modules/purchases/shared/data/database/tables/purchases_table.dart';
import 'package:stock_count/modules/purchases/shared/data/database/tables/purchase_items_table.dart';
import 'package:stock_count/modules/purchases/shared/data/database/tables/purchase_payments_table.dart';
import 'package:stock_count/core/database/migration/legacy_database_migrator.dart';

import 'package:drift/native.dart';

part 'nexabiz_database.g.dart';

/// Single canonical database authority for `nexabiz.sqlite`.
@DriftDatabase(tables: [
  CanonicalDbMetadata,
  Users,
  Companies,
  CompanyMemberships,
  Currencies,
  ProductCategories,
  Warehouses,
  Accounts,
  Products,
  Customers,
  CashRegisters,
  VoucherBooks,
  Suppliers,
  // Phase 3D Inventory Tables:
  StockMovementLedgers,
  StockMovementLines,
  InventoryCostLayers,
  InventoryCostConsumptions,
  ProductWarehouseStocks,
  StockReceipts,
  StockIssues,
  StockReturns,
  StockTransfers,
  InventoryAuditTrail,
  WarehouseAccountingBindings,
  // Phase 3E Sales Tables:
  Sales,
  SaleItems,
  SalePayments,
  // Phase 3F Treasury Tables:
  FinancialTransactions,
  // Phase 3G Accounting Tables:
  JournalEntries,
  JournalLines,
  FiscalYears,
  AccountingPeriods,
  PeriodClosingRecords,
  CurrencyRates,
  CurrencyRateHistory,
  AccountCurrencyBalances,
  // Phase 3H Purchases Tables:
  Purchases,
  PurchaseItems,
  PurchasePayments,
])
class NexabizDatabase extends _$NexabizDatabase {
  /// Opens `$name.sqlite` (`nexabiz.sqlite` by default) with SQLCipher encryption.
  NexabizDatabase({String name = 'nexabiz'})
      : super(encryptedDriftDatabase(name: name));

  /// In-memory database for testing and isolated verification.
  factory NexabizDatabase.memory() {
    return NexabizDatabase.connect(NativeDatabase.memory());
  }

  /// Constructor allowing custom [QueryExecutor] injection (e.g. for testing/isolation).
  NexabizDatabase.connect(super.connection);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(canonicalDbMetadata).insert(
            CanonicalDbMetadataCompanion.insert(
              key: 'schema_initialized_at',
              value: Value(DateTime.now().toIso8601String()),
              updatedAt: Value(DateTime.now()),
            ),
          );
        },
        onUpgrade: (m, from, to) async {
          // Perform production-safe transformation for existing legacy databases
          final legacyMigrator = LegacyDatabaseMigrator(this);
          await legacyMigrator.migrateFromLegacy(
            migrator: m,
            fromVersion: from,
            toVersion: to,
          );

          if (from < 2) {
            await m.createTable(users);
            await m.createTable(companies);
            await m.createTable(companyMemberships);
          }
          if (from < 3) {
            await m.createTable(currencies);
            await m.createTable(productCategories);
            await m.createTable(warehouses);
            await m.createTable(accounts);
            await m.createTable(products);
            await m.createTable(customers);
            await m.createTable(cashRegisters);
            await m.createTable(voucherBooks);
          }
          if (from < 4) {
            await m.createTable(stockMovementLedgers);
            await m.createTable(stockMovementLines);
            await m.createTable(inventoryCostLayers);
            await m.createTable(inventoryCostConsumptions);
            await m.createTable(productWarehouseStocks);
            await m.createTable(stockReceipts);
            await m.createTable(stockIssues);
            await m.createTable(stockReturns);
            await m.createTable(stockTransfers);
            await m.createTable(inventoryAuditTrail);
          }
          if (from < 5) {
            await m.createTable(sales);
            await m.createTable(saleItems);
            await m.createTable(salePayments);
          }
          if (from < 6) {
            await m.createTable(financialTransactions);
          }
          if (from < 7) {
            await m.createTable(journalEntries);
            await m.createTable(journalLines);
            await m.createTable(fiscalYears);
            await m.createTable(accountingPeriods);
          }
          if (from < 8) {
            await m.createTable(suppliers);
            await m.createTable(purchases);
            await m.createTable(purchaseItems);
            await m.createTable(purchasePayments);
          }
          if (from < 9) {
            await _safeAddColumn(m, currencies, currencies.deletedAt);
          }
          if (from < 10) {
            await _safeAddColumn(m, currencies, currencies.isDefault);
          }
          if (from < 11) {
            await _safeAddColumn(m, currencies, currencies.code);
            await _safeAddColumn(m, currencies, currencies.currencyCode);
            await _safeAddColumn(m, currencies, currencies.nameAr);
            await _safeAddColumn(m, currencies, currencies.nameEn);
            await _safeAddColumn(m, currencies, currencies.decimalDigits);
          }
          if (from < 12) {
            await _safeCreateTable(m, warehouseAccountingBindings);
            await _safeCreateTable(m, periodClosingRecords);
            await _safeCreateTable(m, currencyRates);
            await _safeCreateTable(m, currencyRateHistory);
          }
          if (from < 13) {
            await _safeCreateTable(m, accountCurrencyBalances);
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON;');

          // Ensure all tables exist in SQLite database safely
          final m = Migrator(this);
          await _safeCreateTable(m, warehouseAccountingBindings);
          await _safeCreateTable(m, periodClosingRecords);
          await _safeCreateTable(m, currencyRates);
          await _safeCreateTable(m, currencyRateHistory);
          await _safeCreateTable(m, accountCurrencyBalances);
        },
      );

  Future<void> _safeCreateTable(Migrator m, TableInfo table) async {
    try {
      await m.createTable(table);
    } catch (e) {
      if (e.toString().contains('already exists')) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      await m.addColumn(table, column);
    } catch (e) {
      if (e.toString().contains('duplicate column name')) {
        return;
      }
      rethrow;
    }
  }
}



