import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';

import 'tables/categories_table.dart';
import 'tables/inventory_audit_trail_table.dart';
import 'tables/inventory_cost_consumptions_table.dart';
import 'tables/inventory_cost_layers_table.dart';
import 'tables/product_warehouse_stocks_table.dart';
import 'tables/products_table.dart';
import 'tables/stock_issues_table.dart';
import 'tables/stock_movement_lines_table.dart';
import 'tables/stock_receipts_table.dart';
import 'tables/stock_returns_table.dart';
import 'tables/stock_transfers_table.dart';
import 'tables/warehouses_table.dart';

part 'inventory_database.g.dart';

@DriftDatabase(tables: [
  Products,
  StockReceipts,
  StockIssues,
  StockMovementLines,
  InventoryCostLayers,
  InventoryCostConsumptions,
  StockReturns,
  Warehouses,
  ProductWarehouseStocks,
  StockTransfers,
  InventoryAuditTrail,
  Categories,
])
class InventoryDatabase extends _$InventoryDatabase {
  InventoryDatabase({String? name, QueryExecutor? executor})
    : super(executor ?? _openConnection(name ?? 'inventory_products'));

  /// In-memory database for tests.
  InventoryDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createSearchIndexes();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 12) {
        await customStatement(
          'ALTER TABLE stock_receipts ADD COLUMN account_id TEXT NULL',
        );
        await customStatement(
          'ALTER TABLE stock_receipts ADD COLUMN account_name TEXT NULL',
        );
      }
      if (from < 2) {
        await customStatement(
          "ALTER TABLE products ADD COLUMN uuid TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          "ALTER TABLE products ADD COLUMN sync_status TEXT NOT NULL "
          "DEFAULT 'synced'",
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN last_synced_at INTEGER NULL',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN deleted_at INTEGER NULL',
        );
        await customStatement(
          "UPDATE products SET uuid = printf("
          "'00000000-0000-4000-8000-%012d', id) "
          "WHERE uuid IS NULL OR uuid = ''",
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_products_uuid '
          'ON products (uuid)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_sync ON products (sync_status)',
        );
      }
      if (from < 3) {
        await _createSearchIndexes();
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE products ADD COLUMN on_hand_qty REAL NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN unit_cost REAL NOT NULL DEFAULT 0',
        );
      }
      if (from < 5) {
        await m.addColumn(products, products.companyId);
        await customStatement(
          "UPDATE products SET company_id = 'local-company' WHERE company_id IS NULL",
        );
      }
      if (from < 6) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS stock_receipts (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            receipt_number TEXT NOT NULL UNIQUE,
            supplier TEXT NULL,
            notes TEXT NULL,
            receipt_date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            last_synced_at INTEGER NULL,
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS stock_issues (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            issue_number TEXT NOT NULL UNIQUE,
            destination TEXT NULL,
            notes TEXT NULL,
            issue_date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            last_synced_at INTEGER NULL,
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS stock_movement_lines (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            movement_uuid TEXT NOT NULL,
            movement_type TEXT NOT NULL,
            item_code TEXT NOT NULL,
            item_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_cost REAL NOT NULL DEFAULT 0,
            total_cost REAL NOT NULL DEFAULT 0
          );
        ''');
      }
      if (from < 7) {
        await customStatement(
          'ALTER TABLE stock_issues ADD COLUMN account_id TEXT NULL',
        );
        await customStatement(
          'ALTER TABLE stock_issues ADD COLUMN account_name TEXT NULL',
        );
        await customStatement(
          "ALTER TABLE stock_issues ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'SAR'",
        );
        await customStatement(
          'ALTER TABLE stock_issues ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1',
        );
        await customStatement(
          'ALTER TABLE stock_issues ADD COLUMN voucher_book_id INTEGER NULL',
        );
        await customStatement(
          'ALTER TABLE stock_issues ADD COLUMN warehouse TEXT NULL',
        );
        await customStatement(
          'ALTER TABLE stock_movement_lines ADD COLUMN main_quantity REAL NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE stock_movement_lines ADD COLUMN sub_quantity REAL NOT NULL DEFAULT 0',
        );
      }
      if (from < 8) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS inventory_cost_layers (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            item_code TEXT NOT NULL,
            warehouse_id TEXT NULL,
            movement_uuid TEXT NOT NULL,
            movement_type TEXT NOT NULL,
            received_date INTEGER NOT NULL,
            received_qty REAL NOT NULL DEFAULT 0,
            remaining_qty REAL NOT NULL DEFAULT 0,
            unit_cost REAL NOT NULL DEFAULT 0,
            total_cost REAL NOT NULL DEFAULT 0,
            closed INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'synced',
            last_synced_at INTEGER NULL,
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS inventory_cost_consumptions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            layer_uuid TEXT NOT NULL,
            issue_line_uuid TEXT NOT NULL,
            movement_type TEXT NOT NULL,
            consumed_qty REAL NOT NULL DEFAULT 0,
            unit_cost REAL NOT NULL DEFAULT 0,
            total_cost REAL NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            company_id TEXT NULL
          );
        ''');
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cost_layers_item_date '
          'ON inventory_cost_layers (item_code, closed, received_date)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cost_consumptions_issue '
          'ON inventory_cost_consumptions (issue_line_uuid)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cost_consumptions_layer '
          'ON inventory_cost_consumptions (layer_uuid)',
        );
      }
      if (from < 9) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS stock_returns (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            return_number TEXT NOT NULL,
            return_type TEXT NOT NULL,
            original_movement_uuid TEXT NULL,
            party_name TEXT NULL,
            warehouse TEXT NULL,
            notes TEXT NULL,
            return_date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            last_synced_at INTEGER NULL,
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_stock_returns_type '
          'ON stock_returns (return_type, deleted_at)',
        );
      }
      if (from < 10) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS warehouses (
            uuid TEXT NOT NULL PRIMARY KEY,
            code TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            address TEXT NULL,
            phone TEXT NULL,
            manager_name TEXT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS product_warehouse_stocks (
            uuid TEXT NOT NULL PRIMARY KEY,
            item_code TEXT NOT NULL,
            warehouse_id TEXT NOT NULL,
            on_hand_qty REAL NOT NULL DEFAULT 0,
            min_reorder_level REAL NULL,
            bin_location TEXT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL,
            UNIQUE(item_code, warehouse_id)
          );
        ''');
        await customStatement('''
          CREATE TABLE IF NOT EXISTS stock_transfers (
            uuid TEXT NOT NULL PRIMARY KEY,
            transfer_number TEXT NOT NULL UNIQUE,
            from_warehouse_id TEXT NOT NULL,
            to_warehouse_id TEXT NOT NULL,
            transfer_date INTEGER NOT NULL,
            notes TEXT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL
          );
        ''');
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_product_wh_stocks '
          'ON product_warehouse_stocks (item_code, warehouse_id)',
        );
      }
      if (from < 11) {
        await customStatement(
          "ALTER TABLE stock_receipts ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'",
        );
        await customStatement(
          'ALTER TABLE stock_receipts ADD COLUMN posted_at INTEGER NULL',
        );
        await customStatement(
          "ALTER TABLE stock_issues ADD COLUMN status TEXT NOT NULL DEFAULT 'posted'",
        );
        await customStatement(
          'ALTER TABLE stock_issues ADD COLUMN posted_at INTEGER NULL',
        );
        await customStatement(
          "ALTER TABLE stock_returns ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'",
        );
        await customStatement(
          'ALTER TABLE stock_returns ADD COLUMN posted_at INTEGER NULL',
        );
        await customStatement(
          "ALTER TABLE stock_transfers ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'",
        );
        await customStatement(
          'ALTER TABLE stock_transfers ADD COLUMN posted_at INTEGER NULL',
        );
        await customStatement(
          'ALTER TABLE stock_movement_lines ADD COLUMN posted_cost REAL NULL',
        );
        await customStatement(
          'ALTER TABLE stock_movement_lines ADD COLUMN posted_at INTEGER NULL',
        );
        await customStatement('''
          CREATE TABLE IF NOT EXISTS inventory_audit_trail (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            document_id TEXT NOT NULL,
            document_type TEXT NOT NULL,
            event_type TEXT NOT NULL,
            user_id TEXT NULL,
            notes TEXT NULL,
            timestamp INTEGER NOT NULL,
            metadata TEXT NULL,
            company_id TEXT NULL
          );
        ''');
        // Backfill status = 'posted' for existing receipts & issues (since they were saved as posted)
        await customStatement(
          "UPDATE stock_receipts SET status = 'posted', posted_at = created_at WHERE status = 'draft'",
        );
        await customStatement(
          "UPDATE stock_issues SET status = 'posted', posted_at = created_at WHERE status IS NULL OR status = ''",
        );
      }
      if (from < 13) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS categories (
            uuid TEXT NOT NULL PRIMARY KEY,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            warehouse_id TEXT NOT NULL,
            parent_id TEXT NULL,
            cost_valuation_method TEXT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            version INTEGER NOT NULL DEFAULT 1,
            company_id TEXT NULL,
            deleted_at INTEGER NULL,
            UNIQUE(warehouse_id, code)
          );
        ''');
        await customStatement(
          'ALTER TABLE warehouses ADD COLUMN cost_valuation_method TEXT NULL',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN category_id TEXT NULL',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN cost_valuation_method TEXT NULL',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_categories_wh_parent '
          'ON categories (warehouse_id, parent_id)',
        );
      }
    },
  );

  Future<void> _createSearchIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_name ON products (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_sync ON products (sync_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_alive '
      'ON products (item_code) WHERE deleted_at IS NULL',
    );
  }

  static QueryExecutor _openConnection(String name) {
    // Avoid shareAcrossIsolates — it can leave the first watch hung before
    // any row (including an empty list) is emitted.
    return encryptedDriftDatabase(name: name);
  }
}
