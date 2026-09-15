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

// Standalone Financial Package Tables (Phase 2A)
import 'package:stock_count/packages/financial/database/tables/financial_currencies_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_exchange_rates_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_accounts_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_subjects_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_subject_account_buckets_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_account_balances_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_journal_entries_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_journal_lines_table.dart';
// GATE-08 V4 Financial Package Tables
import 'package:stock_count/packages/financial/database/tables/financial_fiscal_years_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_fiscal_periods_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_period_closing_operations_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_period_closing_records_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_period_closing_attempts_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_period_closing_rates_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_fiscal_year_closing_records_table.dart';
import 'package:stock_count/packages/financial/database/tables/financial_fiscal_year_opening_boundaries_table.dart';

import 'package:drift/native.dart';

part 'nexabiz_database.g.dart';

/// Single canonical database authority for `nexabiz.sqlite`.
@DriftDatabase(
  tables: [
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
    // Phase 2A Financial Package Tables:
    FinancialCurrencies,
    FinancialExchangeRates,
    FinancialAccounts,
    FinancialSubjects,
    FinancialSubjectAccountBuckets,
    FinancialAccountBalances,
    FinancialJournalEntries,
    FinancialJournalLines,
    // GATE-08 V4 Tables:
    FinancialFiscalYears,
    FinancialFiscalPeriods,
    FinancialPeriodClosingOperations,
    FinancialPeriodClosingRecords,
    FinancialPeriodClosingAttempts,
    FinancialPeriodClosingRates,
    FinancialFiscalYearClosingRecords,
    FinancialFiscalYearOpeningBoundaries,
  ],
)
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
  int get schemaVersion => 15;

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
        await _safeCreateTable(m, users);
        await _safeCreateTable(m, companies);
        await _safeCreateTable(m, companyMemberships);
      }
      if (from < 3) {
        await _safeCreateTable(m, currencies);
        await _safeCreateTable(m, productCategories);
        await _safeCreateTable(m, warehouses);
        await _safeCreateTable(m, accounts);
        await _safeCreateTable(m, products);
        await _safeCreateTable(m, customers);
        await _safeCreateTable(m, cashRegisters);
        await _safeCreateTable(m, voucherBooks);
      }
      if (from < 4) {
        await _safeCreateTable(m, stockMovementLedgers);
        await _safeCreateTable(m, stockMovementLines);
        await _safeCreateTable(m, inventoryCostLayers);
        await _safeCreateTable(m, inventoryCostConsumptions);
        await _safeCreateTable(m, productWarehouseStocks);
        await _safeCreateTable(m, stockReceipts);
        await _safeCreateTable(m, stockIssues);
        await _safeCreateTable(m, stockReturns);
        await _safeCreateTable(m, stockTransfers);
        await _safeCreateTable(m, inventoryAuditTrail);
      }
      if (from < 5) {
        await _safeCreateTable(m, sales);
        await _safeCreateTable(m, saleItems);
        await _safeCreateTable(m, salePayments);
      }
      if (from < 6) {
        await _safeCreateTable(m, financialTransactions);
      }
      if (from < 7) {
        await _safeCreateTable(m, journalEntries);
        await _safeCreateTable(m, journalLines);
        await _safeCreateTable(m, fiscalYears);
        await _safeCreateTable(m, accountingPeriods);
      }
      if (from < 8) {
        await _safeCreateTable(m, suppliers);
        await _safeCreateTable(m, purchases);
        await _safeCreateTable(m, purchaseItems);
        await _safeCreateTable(m, purchasePayments);
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
      if (from < 14) {
        await _safeCreateTable(m, financialCurrencies);
        await _safeCreateTable(m, financialExchangeRates);
        await _safeCreateTable(m, financialAccounts);
        await _safeCreateTable(m, financialSubjects);
        await _safeCreateTable(m, financialSubjectAccountBuckets);
        await _safeCreateTable(m, financialAccountBalances);
        await _safeCreateTable(m, financialJournalEntries);
        await _safeCreateTable(m, financialJournalLines);
      }
      if (from < 15) {
        await _safeCreateTable(m, financialFiscalYears);
        await _safeCreateTable(m, financialFiscalPeriods);
        await _safeCreateTable(m, financialPeriodClosingOperations);
        await _safeCreateTable(m, financialPeriodClosingRecords);
        await _safeCreateTable(m, financialPeriodClosingAttempts);
        await _safeCreateTable(m, financialPeriodClosingRates);
        await _safeCreateTable(m, financialFiscalYearClosingRecords);
        await _safeCreateTable(m, financialFiscalYearOpeningBoundaries);
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
      await _safeCreateTable(m, financialCurrencies);
      await _safeCreateTable(m, financialExchangeRates);
      await _safeCreateTable(m, financialAccounts);
      await _safeCreateTable(m, financialSubjects);
      await _safeCreateTable(m, financialSubjectAccountBuckets);
      await _safeCreateTable(m, financialAccountBalances);
      await _safeCreateTable(m, financialJournalEntries);
      await _safeCreateTable(m, financialJournalLines);
      await _safeCreateTable(m, financialFiscalYears);
      await _safeCreateTable(m, financialFiscalPeriods);
      await _safeCreateTable(m, financialPeriodClosingOperations);
      await _safeCreateTable(m, financialPeriodClosingRecords);
      await _safeCreateTable(m, financialPeriodClosingAttempts);
      await _safeCreateTable(m, financialPeriodClosingRates);
      await _safeCreateTable(m, financialFiscalYearClosingRecords);
      await _safeCreateTable(m, financialFiscalYearOpeningBoundaries);
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
