import 'dart:io';

import 'package:drift/drift.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Production-safe legacy database migrator for upgrading existing NexaBiz SQLite databases
/// from legacy integer-ID schemas to the canonical UUID v7 physical schema.
///
/// Features:
/// 1. Comprehensive coverage across all 39 physical SQLite tables.
/// 2. Multi-tenant collision safety: `_legacy_id_mappings` keyed by `(company_id, entity_type, legacy_id)`.
/// 3. Crash recovery & transactional state journal (`_migration_journal`).
/// 4. Pre-migration physical backup (`.pre_migration_v<version>.bak`).
/// 5. Post-migration row-count verification and fail-closed integrity checks.
class LegacyDatabaseMigrator {
  LegacyDatabaseMigrator(this.db);

  final NexabizDatabase db;

  /// Main entry point for executing schema and data upgrade from legacy schema version.
  Future<void> migrateFromLegacy({
    required Migrator migrator,
    required int fromVersion,
    required int toVersion,
  }) async {
    // 1. Pre-migration physical database backup (if file-based database)
    String? backupPath;
    try {
      final dbList = await db.customSelect('PRAGMA database_list;').get();
      final mainDb = dbList.firstWhere(
        (r) => r.read<String>('name') == 'main',
        orElse: () => dbList.first,
      );
      final dbFilePath = mainDb.read<String>('file');
      if (dbFilePath.isNotEmpty) {
        backupPath = '$dbFilePath.pre_migration_v$fromVersion.bak';
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        final escapedPath = backupPath.replaceAll("'", "''");
        await db.customStatement("VACUUM INTO '$escapedPath';");
        if (!await backupFile.exists() || await backupFile.length() == 0) {
          throw StateError(
            'Pre-migration backup verification failed: $backupPath is empty or missing!',
          );
        }
      }
    } catch (e) {
      if (backupPath != null) {
        throw StateError('Pre-migration physical database backup failed: $e');
      }
    }

    // 2. Disable foreign keys during DDL migration
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    try {
      // 3. Initialize / Upgrade migration mapping table with company_id composite key
      final mappingTableExists =
          (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name='_legacy_id_mappings'",
                  )
                  .get())
              .isNotEmpty;

      if (mappingTableExists) {
        final colInfo = await db
            .customSelect('PRAGMA table_info(_legacy_id_mappings);')
            .get();
        final hasCompanyId = colInfo.any(
          (c) => c.read<String>('name') == 'company_id',
        );
        if (!hasCompanyId) {
          await db.customStatement(
            'ALTER TABLE _legacy_id_mappings RENAME TO _legacy_id_mappings_old;',
          );
          await db.customStatement('''
            CREATE TABLE _legacy_id_mappings (
              company_id TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              legacy_id TEXT NOT NULL,
              new_uuid TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              PRIMARY KEY (company_id, entity_type, legacy_id),
              UNIQUE (company_id, entity_type, new_uuid)
            );
          ''');
          await db.customStatement('''
            INSERT OR IGNORE INTO _legacy_id_mappings (company_id, entity_type, legacy_id, new_uuid, created_at)
            SELECT '__SYSTEM__', entity_type, legacy_id, new_uuid, created_at FROM _legacy_id_mappings_old;
          ''');
          await db.customStatement('DROP TABLE _legacy_id_mappings_old;');
        }
      } else {
        await db.customStatement('''
          CREATE TABLE IF NOT EXISTS _legacy_id_mappings (
            company_id TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            legacy_id TEXT NOT NULL,
            new_uuid TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (company_id, entity_type, legacy_id),
            UNIQUE (company_id, entity_type, new_uuid)
          );
        ''');
      }

      // 4. Initialize migration crash journal
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS _migration_journal (
          table_name TEXT PRIMARY KEY,
          status TEXT NOT NULL,
          legacy_count INTEGER NOT NULL,
          migrated_count INTEGER NOT NULL,
          started_at INTEGER NOT NULL,
          completed_at INTEGER
        );
      ''');

      // 5. Migrate all 39 physical tables in strict dependency order

      // Group 1: Foundations (Companies, Users, CompanyMemberships, Currencies)
      await _migrateTableIfLegacy('companies', db.companies, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid(
          '__SYSTEM__',
          'companies',
          legacyId,
        );
        return CompaniesCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? 'COMP-$legacyId',
          name: row['name']?.toString() ?? 'Migrated Company $legacyId',
          baseCurrencyCode: Value(
            row['base_currency_code']?.toString() ?? 'YER',
          ),
          inventoryCurrencyCode: Value(
            row['inventory_currency_code']?.toString() ?? 'SAR',
          ),
          status: Value(row['status']?.toString() ?? 'active'),
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('users', db.users, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('__SYSTEM__', 'users', legacyId);
        return UsersCompanion.insert(
          id: Value(uuid),
          email: row['email']?.toString() ?? 'user-$legacyId@nexabiz.local',
          name: row['name']?.toString() ?? 'User $legacyId',
          passwordHash: Value(row['password_hash']?.toString() ?? ''),
          status: Value(row['status']?.toString() ?? 'active'),
          isSuperAdmin: Value(_asBool(row['is_super_admin']) ?? false),
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy(
        'company_memberships',
        db.companyMemberships,
        (row) async {
          final legacyId = row['id'].toString();
          final uuid = await _getOrCreateUuid(
            '__SYSTEM__',
            'company_memberships',
            legacyId,
          );
          final userId =
              await _lookupUuid('__SYSTEM__', 'users', row['user_id']) ?? uuid;
          final companyId =
              await _lookupUuid('__SYSTEM__', 'companies', row['company_id']) ??
              uuid;
          return CompanyMembershipsCompanion.insert(
            id: Value(uuid),
            userId: userId,
            companyId: companyId,
            role: Value(row['role']?.toString() ?? 'member'),
            status: Value(row['status']?.toString() ?? 'active'),
            createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
            updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
          );
        },
      );

      await _migrateTableIfLegacy('currencies', db.currencies, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'currencies',
          legacyId,
        );
        return CurrenciesCompanion.insert(
          id: Value(uuid),
          code:
              row['code']?.toString() ??
              row['currency_code']?.toString() ??
              'CUR-$legacyId',
          currencyCode: Value(
            row['currency_code']?.toString() ?? 'CUR-$legacyId',
          ),
          name: Value(row['name']?.toString()),
          nameAr: Value(row['name_ar']?.toString() ?? 'عملة $legacyId'),
          nameEn: Value(row['name_en']?.toString() ?? 'Currency $legacyId'),
          symbol: row['symbol']?.toString() ?? 'SAR',
          isBase: Value(
            _asBool(row['is_base_currency']) ??
                _asBool(row['is_base']) ??
                false,
          ),
          isDefault: Value(_asBool(row['is_default']) ?? false),
          decimalDigits: Value(_asInt(row['decimal_digits']) ?? 2),
          companyId: Value(companyUuid == '__SYSTEM__' ? null : companyUuid),
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
          deletedAt: Value(_asDateTime(row['deleted_at'])),
        );
      });

      // Group 2: Master Data
      await _migrateTableIfLegacy('product_categories', db.productCategories, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'product_categories',
          legacyId,
        );
        final parentId = await _lookupUuid(
          companyUuid,
          'product_categories',
          row['parent_id'],
        );
        return ProductCategoriesCompanion.insert(
          id: Value(uuid),
          code:
              row['code']?.toString() ??
              row['category_code']?.toString() ??
              'CAT-$legacyId',
          name: row['name']?.toString() ?? 'Category $legacyId',
          parentCategoryId: Value(parentId),
          isActive: Value(_asBool(row['is_active']) ?? true),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('warehouses', db.warehouses, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'warehouses',
          legacyId,
        );
        return WarehousesCompanion.insert(
          id: Value(uuid),
          code:
              row['code']?.toString() ??
              row['warehouse_code']?.toString() ??
              'WH-$legacyId',
          name: row['name']?.toString() ?? 'Warehouse $legacyId',
          address: Value(
            row['address']?.toString() ?? row['location']?.toString(),
          ),
          phone: Value(row['phone']?.toString()),
          isActive: Value(_asBool(row['is_active']) ?? true),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('accounts', db.accounts, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(companyUuid, 'accounts', legacyId);
        final parentId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['parent_id'],
        );
        return AccountsCompanion.insert(
          id: Value(uuid),
          accountCode: row['account_code']?.toString() ?? 'ACC-$legacyId',
          name: row['name']?.toString() ?? 'Account $legacyId',
          accountType: row['account_type']?.toString() ?? 'asset',
          normalBalance: row['normal_balance']?.toString() ?? 'debit',
          parentAccountId: Value(parentId),
          isActive: Value(_asBool(row['is_active']) ?? true),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('products', db.products, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(companyUuid, 'products', legacyId);
        final categoryId = await _lookupUuid(
          companyUuid,
          'product_categories',
          row['category_id'],
        );
        return ProductsCompanion.insert(
          id: Value(uuid),
          itemCode: row['item_code']?.toString() ?? 'PROD-$legacyId',
          name: row['name']?.toString() ?? 'Product $legacyId',
          barcode: Value(row['barcode']?.toString()),
          categoryId: Value(categoryId),
          packSize: Value(_asInt(row['pack_size']) ?? 1),
          price: Value(_asDouble(row['price']) ?? 0.0),
          unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('customers', db.customers, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(companyUuid, 'customers', legacyId);
        final accountId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['account_id'],
        );
        return CustomersCompanion.insert(
          id: Value(uuid),
          customerCode: row['customer_code']?.toString() ?? 'CUST-$legacyId',
          name: row['name']?.toString() ?? 'Customer $legacyId',
          phone: Value(row['phone']?.toString()),
          email: Value(row['email']?.toString()),
          address: Value(row['address']?.toString()),
          accountId: Value(accountId),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('suppliers', db.suppliers, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(companyUuid, 'suppliers', legacyId);
        final accountId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['account_id'],
        );
        return SuppliersCompanion.insert(
          id: Value(uuid),
          supplierCode: row['supplier_code']?.toString() ?? 'SUPP-$legacyId',
          name: row['name']?.toString() ?? 'Supplier $legacyId',
          phone: Value(row['phone']?.toString()),
          email: Value(row['email']?.toString()),
          address: Value(row['address']?.toString()),
          accountId: Value(accountId),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('cash_registers', db.cashRegisters, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'cash_registers',
          legacyId,
        );
        final accountId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['account_id'],
        );
        return CashRegistersCompanion.insert(
          id: Value(uuid),
          code:
              row['code']?.toString() ??
              row['register_code']?.toString() ??
              'REG-$legacyId',
          name: row['name']?.toString() ?? 'Cash Register $legacyId',
          accountId: Value(accountId),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('voucher_books', db.voucherBooks, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'voucher_books',
          legacyId,
        );
        return VoucherBooksCompanion.insert(
          id: Value(uuid),
          name: row['name']?.toString() ?? 'Voucher Book $legacyId',
          bookType:
              row['voucher_type']?.toString() ??
              row['book_type']?.toString() ??
              'receipt',
          nextNumber: Value(_asInt(row['next_number']) ?? 1),
          companyId: companyUuid,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy(
        'warehouse_accounting_bindings',
        db.warehouseAccountingBindings,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'warehouse_accounting_bindings',
            legacyId,
          );
          final whId =
              await _lookupUuid(
                companyUuid,
                'warehouses',
                row['warehouse_id'],
              ) ??
              (row['warehouse_id']?.toString() ?? uuid);
          final invAssetId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['inventory_asset_account_id'],
          );
          final cogsId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['cogs_account_id'],
          );
          final invAdjId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['inventory_adjustment_account_id'],
          );
          final stClearId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['stock_transfer_clearing_account_id'],
          );
          final salesRevId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['sales_revenue_account_id'],
          );
          final salesRetId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['sales_return_account_id'],
          );
          final salesDiscId = await _lookupUuid(
            companyUuid,
            'accounts',
            row['sales_discount_account_id'],
          );
          return WarehouseAccountingBindingsCompanion.insert(
            id: Value(uuid),
            warehouseId: whId,
            inventoryAssetAccountId: Value(invAssetId),
            cogsAccountId: Value(cogsId),
            inventoryAdjustmentAccountId: Value(invAdjId),
            stockTransferClearingAccountId: Value(stClearId),
            salesRevenueAccountId: Value(salesRevId),
            salesReturnAccountId: Value(salesRetId),
            salesDiscountAccountId: Value(salesDiscId),
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            updatedAt:
                _asInt(row['updated_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            companyId: companyUuid,
          );
        },
      );

      // Group 3: Accounting Foundation
      await _migrateTableIfLegacy('fiscal_years', db.fiscalYears, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'fiscal_years',
          legacyId,
        );
        return FiscalYearsCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? 'FY-$legacyId',
          name: row['name']?.toString() ?? 'Fiscal Year $legacyId',
          startDate: _asInt(row['start_date']) ?? 0,
          endDate: _asInt(row['end_date']) ?? 0,
          status: row['status']?.toString() ?? 'open',
          baseCurrencyCode: row['base_currency_code']?.toString() ?? 'YER',
          periodCount: _asInt(row['period_count']) ?? 12,
          periodFrequency: Value(
            row['period_frequency']?.toString() ?? 'monthly',
          ),
          fxRevaluationEnabled: Value(
            _asBool(row['fx_revaluation_enabled']) ?? false,
          ),
          fxGainAccountId: Value(
            await _lookupUuid(
              companyUuid,
              'accounts',
              row['fx_gain_account_id'],
            ),
          ),
          fxLossAccountId: Value(
            await _lookupUuid(
              companyUuid,
              'accounts',
              row['fx_loss_account_id'],
            ),
          ),
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('accounting_periods', db.accountingPeriods, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'accounting_periods',
          legacyId,
        );
        final fyId =
            await _lookupUuid(
              companyUuid,
              'fiscal_years',
              row['fiscal_year_id'],
            ) ??
            (row['fiscal_year_id']?.toString() ?? uuid);
        return AccountingPeriodsCompanion.insert(
          id: Value(uuid),
          fiscalYearId: fyId,
          periodNumber: _asInt(row['period_number']) ?? 1,
          name:
              row['name']?.toString() ??
              'Period ${_asInt(row['period_number']) ?? 1}',
          startDate: _asInt(row['start_date']) ?? 0,
          endDate: _asInt(row['end_date']) ?? 0,
          status: row['status']?.toString() ?? 'open',
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy(
        'period_closing_records',
        db.periodClosingRecords,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'period_closing_records',
            legacyId,
          );
          final fyId =
              await _lookupUuid(
                companyUuid,
                'fiscal_years',
                row['fiscal_year_id'],
              ) ??
              uuid;
          final pId =
              await _lookupUuid(
                companyUuid,
                'accounting_periods',
                row['period_id'],
              ) ??
              uuid;
          final jeId = await _lookupUuid(
            companyUuid,
            'journal_entries',
            row['journal_entry_id'],
          );
          return PeriodClosingRecordsCompanion.insert(
            id: Value(uuid),
            fiscalYearId: fyId,
            periodId: pId,
            closingDate:
                _asInt(row['closing_date']) ??
                DateTime.now().millisecondsSinceEpoch,
            status: row['status']?.toString() ?? 'completed',
            journalEntryId: Value(jeId),
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            companyId: Value(companyUuid),
          );
        },
      );

      await _migrateTableIfLegacy('currency_rates', db.currencyRates, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'currency_rates',
          legacyId,
        );
        return CurrencyRatesCompanion.insert(
          id: Value(uuid),
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          rateToBase: _asDouble(row['rate_to_base']) ?? 1.0,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          notes: Value(row['notes']?.toString()),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy(
        'currency_rate_history',
        db.currencyRateHistory,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'currency_rate_history',
            legacyId,
          );
          return CurrencyRateHistoryCompanion.insert(
            id: Value(uuid),
            currencyCode: row['currency_code']?.toString() ?? 'SAR',
            asOfDate:
                _asInt(row['as_of_date']) ??
                DateTime.now().millisecondsSinceEpoch,
            rateToBase: _asDouble(row['rate_to_base']) ?? 1.0,
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            notes: Value(row['notes']?.toString()),
            companyId: Value(companyUuid),
          );
        },
      );

      // Group 4: Operational Documents (Sales, Purchases, Receipts, Issues, Transfers, Returns)
      await _migrateTableIfLegacy('sales', db.sales, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(companyUuid, 'sales', legacyId);
        final voucherBookId = await _lookupUuid(
          companyUuid,
          'voucher_books',
          row['voucher_book_id'],
        );
        final warehouseId = await _lookupUuid(
          companyUuid,
          'warehouses',
          row['warehouse_id'],
        );
        final customerId = await _lookupUuid(
          companyUuid,
          'customers',
          row['customer_id'],
        );
        final custAccId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['customer_account_id'],
        );
        final cashAccId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['cash_account_id'],
        );
        return SalesCompanion.insert(
          id: Value(uuid),
          saleNumber:
              row['sale_number']?.toString() ??
              row['invoice_number']?.toString() ??
              'SALE-$legacyId',
          saleDate: Value(
            _asInt(row['sale_date']) ??
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
          ),
          settlementType: Value(row['settlement_type']?.toString() ?? 'cash'),
          voucherBookId: Value(voucherBookId),
          warehouseId: Value(warehouseId),
          customerId: Value(customerId),
          customerCode: Value(row['customer_code']?.toString()),
          customerName: Value(row['customer_name']?.toString()),
          customerAccountId: Value(custAccId),
          cashAccountId: Value(cashAccId),
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          baseCurrencyCode: row['base_currency_code']?.toString() ?? 'YER',
          exchangeRate: Value(_asDouble(row['exchange_rate']) ?? 1.0),
          subtotal:
              _asDouble(row['subtotal']) ??
              _asDouble(row['total_amount']) ??
              _asDouble(row['total']) ??
              0.0,
          itemDiscountTotal: _asDouble(row['item_discount_total']) ?? 0.0,
          discountType: Value(row['discount_type']?.toString() ?? 'fixed'),
          discountValue: Value(_asDouble(row['discount_value']) ?? 0.0),
          discountAmount: Value(_asDouble(row['discount_amount']) ?? 0.0),
          taxRate: Value(_asDouble(row['tax_rate']) ?? 0.0),
          taxAmount: Value(_asDouble(row['tax_amount']) ?? 0.0),
          total:
              _asDouble(row['total']) ?? _asDouble(row['total_amount']) ?? 0.0,
          paidAmount: Value(_asDouble(row['paid_amount']) ?? 0.0),
          remainingAmount: Value(_asDouble(row['remaining_amount']) ?? 0.0),
          paymentStatus: Value(row['payment_status']?.toString() ?? 'paid'),
          paymentMethod: Value(row['payment_method']?.toString() ?? 'cash'),
          saleStatus: Value(
            row['sale_status']?.toString() ??
                row['status']?.toString() ??
                'confirmed',
          ),
          notes: Value(row['notes']?.toString()),
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('sale_items', db.saleItems, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'sale_items',
          legacyId,
        );
        final saleId =
            await _lookupUuid(companyUuid, 'sales', row['sale_id']) ??
            (row['sale_id']?.toString() ?? uuid);
        final productId =
            await _lookupUuid(companyUuid, 'products', row['product_id']) ??
            (row['product_id']?.toString() ?? 'PROD-UNKNOWN');
        return SaleItemsCompanion.insert(
          id: Value(uuid),
          saleId: saleId,
          productId: productId,
          productName:
              row['product_name']?.toString() ??
              row['name']?.toString() ??
              'Product',
          productCode:
              row['product_code']?.toString() ??
              row['item_code']?.toString() ??
              'PROD',
          barcode: Value(row['barcode']?.toString()),
          quantity: _asDouble(row['quantity']) ?? _asDouble(row['qty']) ?? 1.0,
          mainQuantity: Value(
            _asDouble(row['main_quantity']) ??
                _asDouble(row['quantity']) ??
                1.0,
          ),
          subQuantity: Value(_asDouble(row['sub_quantity']) ?? 0.0),
          packSize: Value(_asInt(row['pack_size']) ?? 1),
          unitPrice:
              _asDouble(row['unit_price']) ?? _asDouble(row['price']) ?? 0.0,
          baseUnitPrice: Value(_asDouble(row['base_unit_price']) ?? 0.0),
          discountType: Value(row['discount_type']?.toString() ?? 'fixed'),
          discountValue: Value(_asDouble(row['discount_value']) ?? 0.0),
          discountAmount: Value(_asDouble(row['discount_amount']) ?? 0.0),
          taxAmount: Value(_asDouble(row['tax_amount']) ?? 0.0),
          subtotal:
              _asDouble(row['subtotal']) ??
              ((_asDouble(row['quantity']) ?? 1.0) *
                  (_asDouble(row['unit_price']) ?? 0.0)),
          total: _asDouble(row['total']) ?? _asDouble(row['subtotal']) ?? 0.0,
          lineOrder: Value(_asInt(row['line_order']) ?? 0),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('sale_payments', db.salePayments, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'sale_payments',
          legacyId,
        );
        final saleId =
            await _lookupUuid(companyUuid, 'sales', row['sale_id']) ??
            (row['sale_id']?.toString() ?? uuid);
        return SalePaymentsCompanion.insert(
          id: Value(uuid),
          saleId: saleId,
          amount: _asDouble(row['amount']) ?? 0.0,
          method: Value(row['method']?.toString() ?? 'cash'),
          paidAt:
              _asInt(row['paid_at']) ??
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          notes: Value(row['notes']?.toString()),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('purchases', db.purchases, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(companyUuid, 'purchases', legacyId);
        final voucherBookId = await _lookupUuid(
          companyUuid,
          'voucher_books',
          row['voucher_book_id'],
        );
        final warehouseId = await _lookupUuid(
          companyUuid,
          'warehouses',
          row['warehouse_id'],
        );
        final supplierId = await _lookupUuid(
          companyUuid,
          'suppliers',
          row['supplier_id'],
        );
        final suppAccId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['supplier_account_id'],
        );
        final cashAccId = await _lookupUuid(
          companyUuid,
          'accounts',
          row['cash_account_id'],
        );
        return PurchasesCompanion.insert(
          id: Value(uuid),
          purchaseNumber:
              row['purchase_number']?.toString() ??
              row['invoice_number']?.toString() ??
              'PUR-$legacyId',
          purchaseDate: Value(
            _asInt(row['purchase_date']) ??
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
          ),
          settlementType: Value(row['settlement_type']?.toString() ?? 'cash'),
          voucherBookId: Value(voucherBookId),
          warehouseId: Value(warehouseId),
          supplierId: Value(supplierId),
          supplierCode: Value(row['supplier_code']?.toString()),
          supplierName: Value(row['supplier_name']?.toString()),
          supplierAccountId: Value(suppAccId),
          cashAccountId: Value(cashAccId),
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          baseCurrencyCode: row['base_currency_code']?.toString() ?? 'YER',
          exchangeRate: Value(_asDouble(row['exchange_rate']) ?? 1.0),
          subtotal:
              _asDouble(row['subtotal']) ??
              _asDouble(row['total_amount']) ??
              _asDouble(row['total']) ??
              0.0,
          itemDiscountTotal: _asDouble(row['item_discount_total']) ?? 0.0,
          discountType: Value(row['discount_type']?.toString() ?? 'fixed'),
          discountValue: Value(_asDouble(row['discount_value']) ?? 0.0),
          discountAmount: Value(_asDouble(row['discount_amount']) ?? 0.0),
          taxRate: Value(_asDouble(row['tax_rate']) ?? 0.0),
          taxAmount: Value(_asDouble(row['tax_amount']) ?? 0.0),
          total:
              _asDouble(row['total']) ?? _asDouble(row['total_amount']) ?? 0.0,
          paidAmount: Value(_asDouble(row['paid_amount']) ?? 0.0),
          remainingAmount: Value(_asDouble(row['remaining_amount']) ?? 0.0),
          paymentStatus: Value(row['payment_status']?.toString() ?? 'paid'),
          paymentMethod: Value(row['payment_method']?.toString() ?? 'cash'),
          purchaseStatus: Value(
            row['purchase_status']?.toString() ??
                row['status']?.toString() ??
                'confirmed',
          ),
          notes: Value(row['notes']?.toString()),
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('purchase_items', db.purchaseItems, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'purchase_items',
          legacyId,
        );
        final purchaseId =
            await _lookupUuid(companyUuid, 'purchases', row['purchase_id']) ??
            (row['purchase_id']?.toString() ?? uuid);
        final productId =
            await _lookupUuid(companyUuid, 'products', row['product_id']) ??
            (row['product_id']?.toString() ?? 'PROD-UNKNOWN');
        return PurchaseItemsCompanion.insert(
          id: Value(uuid),
          purchaseId: purchaseId,
          productId: productId,
          productName:
              row['product_name']?.toString() ??
              row['name']?.toString() ??
              'Product',
          productCode:
              row['product_code']?.toString() ??
              row['item_code']?.toString() ??
              'PROD',
          barcode: Value(row['barcode']?.toString()),
          quantity: _asDouble(row['quantity']) ?? _asDouble(row['qty']) ?? 1.0,
          mainQuantity: Value(
            _asDouble(row['main_quantity']) ??
                _asDouble(row['quantity']) ??
                1.0,
          ),
          subQuantity: Value(_asDouble(row['sub_quantity']) ?? 0.0),
          packSize: Value(_asInt(row['pack_size']) ?? 1),
          unitPrice:
              _asDouble(row['unit_price']) ?? _asDouble(row['price']) ?? 0.0,
          baseUnitPrice: Value(_asDouble(row['base_unit_price']) ?? 0.0),
          discountType: Value(row['discount_type']?.toString() ?? 'fixed'),
          discountValue: Value(_asDouble(row['discount_value']) ?? 0.0),
          discountAmount: Value(_asDouble(row['discount_amount']) ?? 0.0),
          taxAmount: Value(_asDouble(row['tax_amount']) ?? 0.0),
          subtotal:
              _asDouble(row['subtotal']) ??
              ((_asDouble(row['quantity']) ?? 1.0) *
                  (_asDouble(row['unit_price']) ?? 0.0)),
          total: _asDouble(row['total']) ?? _asDouble(row['subtotal']) ?? 0.0,
          lineOrder: Value(_asInt(row['line_order']) ?? 0),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('purchase_payments', db.purchasePayments, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'purchase_payments',
          legacyId,
        );
        final purchaseId =
            await _lookupUuid(companyUuid, 'purchases', row['purchase_id']) ??
            (row['purchase_id']?.toString() ?? uuid);
        return PurchasePaymentsCompanion.insert(
          id: Value(uuid),
          purchaseId: purchaseId,
          paymentDate:
              _asInt(row['payment_date']) ??
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          amount: _asDouble(row['amount']) ?? 0.0,
          paymentMethod: row['payment_method']?.toString() ?? 'cash',
          treasuryTransactionId: Value(
            row['treasury_transaction_id']?.toString(),
          ),
          notes: Value(row['notes']?.toString()),
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy(
        'financial_transactions',
        db.financialTransactions,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'financial_transactions',
            legacyId,
          );
          final cashAccId =
              await _lookupUuid(
                companyUuid,
                'accounts',
                row['cash_account_id'],
              ) ??
              (row['cash_account_id']?.toString() ?? uuid);
          final counterAccId =
              await _lookupUuid(
                companyUuid,
                'accounts',
                row['counter_account_id'],
              ) ??
              (row['counter_account_id']?.toString() ?? uuid);
          final voucherBookId = await _lookupUuid(
            companyUuid,
            'voucher_books',
            row['voucher_book_id'],
          );
          final customerId = await _lookupUuid(
            companyUuid,
            'customers',
            row['customer_id'],
          );
          return FinancialTransactionsCompanion.insert(
            id: Value(uuid),
            transactionNumber:
                row['transaction_number']?.toString() ?? 'TX-$legacyId',
            transactionType: row['transaction_type']?.toString() ?? 'receipt',
            source: row['source']?.toString() ?? 'manual',
            transactionDate:
                _asInt(row['transaction_date']) ??
                DateTime.now().millisecondsSinceEpoch,
            amount: _asDouble(row['amount']) ?? 0.0,
            currencyCode: row['currency_code']?.toString() ?? 'SAR',
            baseCurrencyCode: row['base_currency_code']?.toString() ?? 'YER',
            exchangeRate: Value(_asDouble(row['exchange_rate']) ?? 1.0),
            counterAmount: Value(
              _asDouble(row['counter_amount']) ??
                  _asDouble(row['amount']) ??
                  0.0,
            ),
            counterCurrencyCode:
                row['counter_currency_code']?.toString() ??
                row['currency_code']?.toString() ??
                'SAR',
            counterExchangeRate: Value(
              _asDouble(row['counter_exchange_rate']) ?? 1.0,
            ),
            linesJson: Value(row['lines_json']?.toString()),
            voucherBookId: Value(voucherBookId),
            cashAccountId: cashAccId,
            counterAccountId: counterAccId,
            customerId: Value(customerId),
            customerCode: Value(row['customer_code']?.toString()),
            customerName: Value(row['customer_name']?.toString()),
            partyName: Value(row['party_name']?.toString()),
            reference: Value(row['reference']?.toString()),
            description: Value(row['description']?.toString()),
            paymentMethod: Value(row['payment_method']?.toString() ?? 'cash'),
            documentStatus: Value(
              row['document_status']?.toString() ?? 'posted',
            ),
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            updatedAt:
                _asInt(row['updated_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            companyId: Value(companyUuid),
          );
        },
      );

      await _migrateTableIfLegacy('stock_receipts', db.stockReceipts, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'stock_receipts',
          legacyId,
        );
        final warehouseId = await _lookupUuid(
          companyUuid,
          'warehouses',
          row['warehouse_id'],
        );
        final supplierId = await _lookupUuid(
          companyUuid,
          'suppliers',
          row['supplier_id'],
        );
        return StockReceiptsCompanion.insert(
          id: Value(uuid),
          receiptNumber: row['receipt_number']?.toString() ?? 'REC-$legacyId',
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          receiptDate:
              _asInt(row['receipt_date']) ??
              DateTime.now().millisecondsSinceEpoch,
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          status: Value(row['status']?.toString() ?? 'posted'),
          warehouseId: Value(warehouseId),
          supplierId: Value(supplierId),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('stock_issues', db.stockIssues, (row) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'stock_issues',
          legacyId,
        );
        final warehouseId = await _lookupUuid(
          companyUuid,
          'warehouses',
          row['warehouse_id'],
        );
        final customerId = await _lookupUuid(
          companyUuid,
          'customers',
          row['customer_id'],
        );
        return StockIssuesCompanion.insert(
          id: Value(uuid),
          issueNumber: row['issue_number']?.toString() ?? 'ISS-$legacyId',
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          issueDate:
              _asInt(row['issue_date']) ??
              DateTime.now().millisecondsSinceEpoch,
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          status: Value(row['status']?.toString() ?? 'posted'),
          warehouseId: Value(warehouseId),
          customerId: Value(customerId),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('stock_returns', db.stockReturns, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'stock_returns',
          legacyId,
        );
        final warehouseId = await _lookupUuid(
          companyUuid,
          'warehouses',
          row['warehouse_id'],
        );
        return StockReturnsCompanion.insert(
          id: Value(uuid),
          returnNumber: row['return_number']?.toString() ?? 'RET-$legacyId',
          returnType: row['return_type']?.toString() ?? 'sales_return',
          originalDocumentType: Value(
            row['original_document_type']?.toString(),
          ),
          originalDocumentId: Value(row['original_document_id']?.toString()),
          partyName: Value(row['party_name']?.toString()),
          warehouse: Value(row['warehouse']?.toString()),
          warehouseId: Value(warehouseId),
          notes: Value(row['notes']?.toString()),
          returnDate:
              _asInt(row['return_date']) ??
              DateTime.now().millisecondsSinceEpoch,
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          status: Value(row['status']?.toString() ?? 'posted'),
          postedAt: Value(_asInt(row['posted_at'])),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy('stock_transfers', db.stockTransfers, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'stock_transfers',
          legacyId,
        );
        final fromWh =
            await _lookupUuid(
              companyUuid,
              'warehouses',
              row['from_warehouse_id'],
            ) ??
            (row['from_warehouse_id']?.toString() ?? uuid);
        final toWh =
            await _lookupUuid(
              companyUuid,
              'warehouses',
              row['to_warehouse_id'],
            ) ??
            (row['to_warehouse_id']?.toString() ?? uuid);
        return StockTransfersCompanion.insert(
          id: Value(uuid),
          transferNumber: row['transfer_number']?.toString() ?? 'TR-$legacyId',
          fromWarehouseId: fromWh,
          toWarehouseId: toWh,
          transferDate:
              _asInt(row['transfer_date']) ??
              DateTime.now().millisecondsSinceEpoch,
          notes: Value(row['notes']?.toString()),
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          status: Value(row['status']?.toString() ?? 'posted'),
          postedAt: Value(_asInt(row['posted_at'])),
          companyId: Value(companyUuid),
        );
      });

      // Group 5: Ledgers, Cost Layers & Balances
      await _migrateTableIfLegacy(
        'stock_movement_ledgers',
        db.stockMovementLedgers,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'stock_movement_ledgers',
            legacyId,
          );
          final warehouseId =
              await _lookupUuid(
                companyUuid,
                'warehouses',
                row['warehouse_id'],
              ) ??
              (row['warehouse_id']?.toString() ?? 'WH-DEFAULT');
          final productId = await _lookupUuid(
            companyUuid,
            'products',
            row['product_id'],
          );
          final srcDocId =
              await _resolveDocumentUuid(
                companyUuid,
                row['source_document_type']?.toString(),
                row['source_document_id'],
              ) ??
              uuid;
          final rawSrcLine = row['source_line_uuid']?.toString();
          final srcLineId = (rawSrcLine != null && rawSrcLine.length == 36)
              ? rawSrcLine
              : (await _lookupUuid(
                      companyUuid,
                      'stock_movement_lines',
                      rawSrcLine,
                    ) ??
                    await _lookupUuid(companyUuid, 'sale_items', rawSrcLine) ??
                    await _lookupUuid(
                      companyUuid,
                      'purchase_items',
                      rawSrcLine,
                    ) ??
                    uuid);

          return StockMovementLedgersCompanion.insert(
            id: Value(uuid),
            companyId: companyUuid,
            warehouseId: warehouseId,
            productId: Value(productId),
            itemCode: row['item_code']?.toString() ?? 'ITEM-$legacyId',
            quantity: Value(_asDouble(row['quantity']) ?? 0.0),
            direction: row['direction']?.toString() ?? 'inbound',
            movementType: row['movement_type']?.toString() ?? 'receipt',
            postingDate:
                _asInt(row['posting_date']) ??
                DateTime.now().millisecondsSinceEpoch,
            sourceDocumentId: srcDocId,
            sourceDocumentType:
                row['source_document_type']?.toString() ?? 'stock_receipt',
            sourceLineUuid: srcLineId,
            unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
            totalCost: Value(_asDouble(row['total_cost']) ?? 0.0),
            baseTotalCost: Value(
              _asDouble(row['base_total_cost']) ??
                  _asDouble(row['total_cost']) ??
                  0.0,
            ),
            inventoryCurrencyId:
                row['inventory_currency_id']?.toString() ?? 'YER',
            documentCurrencyId:
                row['document_currency_id']?.toString() ?? 'SAR',
            unitCostDocumentCurrency: Value(
              _asDouble(row['unit_cost_document_currency']) ??
                  _asDouble(row['unit_cost']) ??
                  0.0,
            ),
            totalCostDocumentCurrency: Value(
              _asDouble(row['total_cost_document_currency']) ??
                  _asDouble(row['total_cost']) ??
                  0.0,
            ),
            exchangeRate: Value(_asDouble(row['exchange_rate']) ?? 1.0),
            costingMethodUsed: row['costing_method_used']?.toString() ?? 'fifo',
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
          );
        },
      );

      await _migrateTableIfLegacy(
        'stock_movement_lines',
        db.stockMovementLines,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'stock_movement_lines',
            legacyId,
          );
          final receiptId = await _lookupUuid(
            companyUuid,
            'stock_receipts',
            row['receipt_id'],
          );
          final issueId = await _lookupUuid(
            companyUuid,
            'stock_issues',
            row['issue_id'],
          );
          final returnId = await _lookupUuid(
            companyUuid,
            'stock_returns',
            row['return_id'],
          );
          final transferId = await _lookupUuid(
            companyUuid,
            'stock_transfers',
            row['transfer_id'],
          );
          final productId = await _lookupUuid(
            companyUuid,
            'products',
            row['product_id'],
          );

          return StockMovementLinesCompanion.insert(
            id: Value(uuid),
            receiptId: Value(receiptId),
            issueId: Value(issueId),
            returnId: Value(returnId),
            transferId: Value(transferId),
            movementType: row['movement_type']?.toString() ?? 'receipt',
            productId: Value(productId),
            itemCode: row['item_code']?.toString() ?? 'ITEM-$legacyId',
            itemName: row['item_name']?.toString() ?? 'Item $legacyId',
            mainQuantity: Value(
              _asDouble(row['main_quantity']) ??
                  _asDouble(row['quantity']) ??
                  0.0,
            ),
            subQuantity: Value(_asDouble(row['sub_quantity']) ?? 0.0),
            quantity: Value(_asDouble(row['quantity']) ?? 0.0),
            unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
            totalCost: Value(_asDouble(row['total_cost']) ?? 0.0),
            baseTotalCost: Value(
              _asDouble(row['base_total_cost']) ??
                  _asDouble(row['total_cost']) ??
                  0.0,
            ),
            postedCost: Value(_asDouble(row['posted_cost'])),
            postedAt: Value(_asInt(row['posted_at'])),
            companyId: companyUuid,
          );
        },
      );

      await _migrateTableIfLegacy(
        'inventory_cost_layers',
        db.inventoryCostLayers,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'inventory_cost_layers',
            legacyId,
          );
          final warehouseId = await _lookupUuid(
            companyUuid,
            'warehouses',
            row['warehouse_id'],
          );
          final receiptId = await _lookupUuid(
            companyUuid,
            'stock_receipts',
            row['receipt_id'],
          );
          final legacyMov = row['movement_uuid']?.toString();
          final movUuid = (legacyMov != null && legacyMov.length == 36)
              ? legacyMov
              : (await _lookupUuid(companyUuid, 'stock_receipts', legacyMov) ??
                    await _lookupUuid(companyUuid, 'stock_issues', legacyMov) ??
                    receiptId ??
                    uuid);

          return InventoryCostLayersCompanion.insert(
            id: Value(uuid),
            itemCode: row['item_code']?.toString() ?? 'ITEM-$legacyId',
            movementUuid: movUuid,
            movementType: row['movement_type']?.toString() ?? 'receipt',
            receivedDate:
                _asInt(row['received_date']) ??
                DateTime.now().millisecondsSinceEpoch,
            receivedQty: Value(_asDouble(row['received_qty']) ?? 0.0),
            remainingQty: Value(_asDouble(row['remaining_qty']) ?? 0.0),
            unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
            totalCost: Value(_asDouble(row['total_cost']) ?? 0.0),
            inventoryCurrencyId:
                row['inventory_currency_id']?.toString() ?? 'YER',
            documentCurrencyId:
                row['currency_code']?.toString() ??
                row['document_currency_id']?.toString() ??
                'SAR',
            exchangeRate: Value(_asDouble(row['exchange_rate']) ?? 1.0),
            unitCostInventoryCurrency: Value(
              _asDouble(row['unit_cost_inventory_currency']) ?? 0.0,
            ),
            totalCostInventoryCurrency: Value(
              _asDouble(row['total_cost_inventory_currency']) ?? 0.0,
            ),
            closed: Value(_asInt(row['closed']) ?? 0),
            warehouseId: Value(warehouseId),
            companyId: Value(companyUuid),
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            updatedAt:
                _asInt(row['updated_at']) ??
                DateTime.now().millisecondsSinceEpoch,
          );
        },
      );

      await _migrateTableIfLegacy(
        'inventory_cost_consumptions',
        db.inventoryCostConsumptions,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'inventory_cost_consumptions',
            legacyId,
          );
          final rawLayer = row['layer_uuid']?.toString();
          final layerUuid = (rawLayer != null && rawLayer.length == 36)
              ? rawLayer
              : (await _lookupUuid(
                      companyUuid,
                      'inventory_cost_layers',
                      rawLayer,
                    ) ??
                    uuid);
          final rawIssueLine = row['issue_line_uuid']?.toString();
          final issueLineUuid =
              (rawIssueLine != null && rawIssueLine.length == 36)
              ? rawIssueLine
              : (await _lookupUuid(
                      companyUuid,
                      'stock_movement_lines',
                      rawIssueLine,
                    ) ??
                    await _lookupUuid(
                      companyUuid,
                      'sale_items',
                      rawIssueLine,
                    ) ??
                    uuid);

          return InventoryCostConsumptionsCompanion.insert(
            id: Value(uuid),
            layerUuid: layerUuid,
            issueLineUuid: issueLineUuid,
            movementType: row['movement_type']?.toString() ?? 'issue',
            consumedQty: Value(_asDouble(row['consumed_qty']) ?? 0.0),
            unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
            totalCost: Value(_asDouble(row['total_cost']) ?? 0.0),
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            companyId: Value(companyUuid),
          );
        },
      );

      await _migrateTableIfLegacy(
        'product_warehouse_stocks',
        db.productWarehouseStocks,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'product_warehouse_stocks',
            legacyId,
          );
          final productId = await _lookupUuid(
            companyUuid,
            'products',
            row['product_id'],
          );
          final warehouseId =
              await _lookupUuid(
                companyUuid,
                'warehouses',
                row['warehouse_id'],
              ) ??
              (row['warehouse_id']?.toString() ?? 'WH-DEFAULT');

          return ProductWarehouseStocksCompanion.insert(
            id: Value(uuid),
            productId: Value(productId),
            itemCode: row['item_code']?.toString() ?? 'ITEM-$legacyId',
            warehouseId: warehouseId,
            onHandQty: Value(_asDouble(row['on_hand_qty']) ?? 0.0),
            minReorderLevel: Value(_asDouble(row['min_reorder_level'])),
            binLocation: Value(row['bin_location']?.toString()),
            createdAt:
                _asInt(row['created_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            updatedAt:
                _asInt(row['updated_at']) ??
                DateTime.now().millisecondsSinceEpoch,
            companyId: Value(companyUuid),
          );
        },
      );

      await _migrateTableIfLegacy(
        'inventory_audit_trail',
        db.inventoryAuditTrail,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'inventory_audit_trail',
            legacyId,
          );
          final rawDoc = row['document_id']?.toString();
          final docId = (rawDoc != null && rawDoc.length == 36)
              ? rawDoc
              : (await _resolveDocumentUuid(
                      companyUuid,
                      row['document_type']?.toString(),
                      rawDoc,
                    ) ??
                    uuid);
          final userId = await _lookupUuid(
            '__SYSTEM__',
            'users',
            row['user_id'],
          );

          return InventoryAuditTrailCompanion.insert(
            id: Value(uuid),
            documentId: docId,
            documentType: row['document_type']?.toString() ?? 'stock_receipt',
            eventType: row['event_type']?.toString() ?? 'post',
            userId: Value(userId),
            notes: Value(row['notes']?.toString()),
            timestamp:
                _asInt(row['timestamp']) ??
                DateTime.now().millisecondsSinceEpoch,
            metadata: Value(row['metadata']?.toString()),
            companyId: Value(companyUuid),
          );
        },
      );

      await _migrateTableIfLegacy('journal_entries', db.journalEntries, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'journal_entries',
          legacyId,
        );
        return JournalEntriesCompanion.insert(
          id: Value(uuid),
          voucherNumber: row['voucher_number']?.toString() ?? 'JE-$legacyId',
          voucherType: row['voucher_type']?.toString() ?? 'journal',
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          entryDate:
              _asInt(row['entry_date']) ??
              DateTime.now().millisecondsSinceEpoch,
          description: Value(row['description']?.toString()),
          companyId: Value(companyUuid),
          createdAt:
              _asInt(row['created_at']) ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt:
              _asInt(row['updated_at']) ??
              DateTime.now().millisecondsSinceEpoch,
        );
      });

      await _migrateTableIfLegacy('journal_lines', db.journalLines, (
        row,
      ) async {
        final legacyId = row['id'].toString();
        final companyUuid =
            await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
        final uuid = await _getOrCreateUuid(
          companyUuid,
          'journal_lines',
          legacyId,
        );
        final entryId =
            await _lookupUuid(
              companyUuid,
              'journal_entries',
              row['journal_id'],
            ) ??
            await _lookupUuid(
              companyUuid,
              'journal_entries',
              row['entry_id'],
            ) ??
            uuid;
        final accountId =
            await _lookupUuid(companyUuid, 'accounts', row['account_id']) ??
            uuid;
        return JournalLinesCompanion.insert(
          id: Value(uuid),
          entryId: entryId,
          accountId: accountId,
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          debit: Value(_asDouble(row['debit']) ?? 0.0),
          credit: Value(_asDouble(row['credit']) ?? 0.0),
          baseDebit: Value(_asDouble(row['base_debit']) ?? 0.0),
          baseCredit: Value(_asDouble(row['base_credit']) ?? 0.0),
          exchangeRateToBase: Value(_asDouble(row['exchange_rate']) ?? 1.0),
          lineDescription: Value(row['description']?.toString()),
          companyId: Value(companyUuid),
        );
      });

      await _migrateTableIfLegacy(
        'account_currency_balances',
        db.accountCurrencyBalances,
        (row) async {
          final legacyId = row['id'].toString();
          final companyUuid =
              await _resolveCompanyUuid(row['company_id']) ?? '__SYSTEM__';
          final uuid = await _getOrCreateUuid(
            companyUuid,
            'account_currency_balances',
            legacyId,
          );
          final accountId =
              await _lookupUuid(companyUuid, 'accounts', row['account_id']) ??
              (row['account_id']?.toString() ?? uuid);
          return AccountCurrencyBalancesCompanion.insert(
            id: Value(uuid),
            accountId: accountId,
            currencyCode: row['currency_code']?.toString() ?? 'YER',
            totalDebit: Value(_asDouble(row['total_debit']) ?? 0.0),
            totalCredit: Value(_asDouble(row['total_credit']) ?? 0.0),
            netBalance: Value(_asDouble(row['net_balance']) ?? 0.0),
            companyId: Value(companyUuid),
            updatedAt:
                _asInt(row['updated_at']) ??
                DateTime.now().millisecondsSinceEpoch,
          );
        },
      );

      await _migrateTableIfLegacy(
        'canonical_db_metadata',
        db.canonicalDbMetadata,
        (row) async {
          return CanonicalDbMetadataCompanion.insert(
            key: row['key'].toString(),
            value: Value(row['value']?.toString()),
            updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
          );
        },
      );

      // 6. Fail-Closed Unmigrated Legacy Table & Integer ID Detection Check
      final leftoverLegacy = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '_legacy_%' AND name != '_legacy_id_mappings';",
          )
          .get();

      if (leftoverLegacy.isNotEmpty) {
        throw StateError(
          'Migration Safety Fail-Closed: Leftover temporary legacy tables detected after migration: '
          '${leftoverLegacy.map((r) => r.read<String>('name')).toList()}',
        );
      }

      final allMasterTables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_legacy_%' AND name != '_migration_journal';",
          )
          .get();

      for (final tbl in allMasterTables) {
        final tblName = tbl.read<String>('name');
        if (tblName == '_legacy_id_mappings' ||
            tblName == 'canonical_db_metadata') {
          continue;
        }
        final pragma = await db
            .customSelect('PRAGMA table_info($tblName);')
            .get();
        for (final col in pragma) {
          if (col.read<String>('name') == 'id') {
            final colType = col.read<String>('type').toUpperCase();
            if (colType.contains('INT')) {
              throw StateError(
                'Migration Safety Fail-Closed: Table $tblName still has INTEGER primary key id after upgrade!',
              );
            }
          }
        }
      }
    } finally {
      // 7. Re-enable SQLite Foreign Keys and verify zero violations
      await db.customStatement('PRAGMA foreign_keys = ON;');
      final fkViolations = await db
          .customSelect('PRAGMA foreign_key_check;')
          .get();
      if (fkViolations.isNotEmpty) {
        throw StateError(
          'Migration Safety Violation: PRAGMA foreign_key_check reported ${fkViolations.length} orphan foreign key references after upgrade!',
        );
      }
    }
  }

  /// Helper to check if a table exists with legacy integer primary key `id` (or in a crash-recovery `_legacy_*` state)
  /// and migrate its schema and rows with full journal tracking.
  Future<void> _migrateTableIfLegacy(
    String tableName,
    TableInfo tableInfo,
    Future<Insertable> Function(Map<String, dynamic> row) rowMapper,
  ) async {
    final m = Migrator(db);
    final tempName = '_legacy_$tableName';

    // 1. Check if temporary legacy table exists (crash recovery scenario)
    final tempExists =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
                  variables: [Variable.withString(tempName)],
                )
                .get())
            .isNotEmpty;

    // 2. Check if canonical table exists
    final origExists =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
                  variables: [Variable.withString(tableName)],
                )
                .get())
            .isNotEmpty;

    if (!tempExists && !origExists) {
      // Neither table exists in this database
      return;
    }

    if (!tempExists && origExists) {
      // Check if original table has INTEGER primary key id
      final pragmaInfo = await db
          .customSelect('PRAGMA table_info($tableName);')
          .get();
      final idCol = pragmaInfo.firstWhere(
        (c) => c.read<String>('name') == 'id',
        orElse: () => pragmaInfo.first,
      );

      final isIntegerId = idCol
          .read<String>('type')
          .toUpperCase()
          .contains('INT');
      if (!isIntegerId) {
        // Already canonical TEXT UUID v7 schema
        return;
      }

      // Record migration started in journal
      final now = DateTime.now().millisecondsSinceEpoch;
      final countRow = await db
          .customSelect('SELECT COUNT(*) as c FROM $tableName;')
          .getSingle();
      final legacyCount = countRow.read<int>('c');

      await db.customStatement(
        '''
        INSERT OR REPLACE INTO _migration_journal 
        (table_name, status, legacy_count, migrated_count, started_at, completed_at)
        VALUES (?, 'in_progress', ?, 0, ?, NULL);
      ''',
        [tableName, legacyCount, now],
      );

      // Atomic rename
      await db.customStatement('ALTER TABLE $tableName RENAME TO $tempName;');
    } else if (tempExists && origExists) {
      // Recovery: Process crashed midway after rename and destination was created.
      // Drop possibly partial destination table to cleanly replay from legacy.
      await db.customStatement('DROP TABLE $tableName;');
    }

    // At this point, tempName exists containing legacy data.
    final legacyRows = await db.customSelect('SELECT * FROM $tempName;').get();

    // Re-create canonical UUID table schema
    try {
      await m.createTable(tableInfo);
    } catch (e) {
      if (!e.toString().contains('already exists')) {
        rethrow;
      }
    }

    // Migrate rows
    for (final row in legacyRows) {
      final mapData = Map<String, dynamic>.from(row.data);
      final companion = await rowMapper(mapData);
      await db.into(tableInfo).insert(companion);
    }

    // Anti-Data-Loss Count Verification
    final newCount =
        (await db
                .customSelect('SELECT COUNT(*) as c FROM $tableName;')
                .getSingle())
            .read<int>('c');
    if (newCount != legacyRows.length) {
      await db.customStatement(
        '''
        UPDATE _migration_journal 
        SET status = 'failed', migrated_count = ?
        WHERE table_name = ?;
      ''',
        [newCount, tableName],
      );

      throw StateError(
        'Migration Safety Failure: Row count mismatch during $tableName migration. '
        'Legacy count: ${legacyRows.length}, Migrated count: $newCount',
      );
    }

    // Update journal as completed
    final completedNow = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      '''
      UPDATE _migration_journal 
      SET status = 'completed', migrated_count = ?, completed_at = ?
      WHERE table_name = ?;
    ''',
      [newCount, completedNow, tableName],
    );

    // Clean up temporary legacy table
    await db.customStatement('DROP TABLE $tempName;');
  }

  Future<String> _getOrCreateUuid(
    String companyId,
    String entityType,
    String legacyId,
  ) async {
    final existing = await db
        .customSelect(
          'SELECT new_uuid FROM _legacy_id_mappings WHERE company_id = ? AND entity_type = ? AND legacy_id = ?;',
          variables: [
            Variable.withString(companyId),
            Variable.withString(entityType),
            Variable.withString(legacyId),
          ],
        )
        .getSingleOrNull();

    if (existing != null) {
      return existing.read<String>('new_uuid');
    }

    final newUuid = generateUuidV7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO _legacy_id_mappings (company_id, entity_type, legacy_id, new_uuid, created_at) VALUES (?, ?, ?, ?, ?);',
      [companyId, entityType, legacyId, newUuid, now],
    );
    return newUuid;
  }

  Future<String?> _lookupUuid(
    String companyId,
    String entityType,
    dynamic legacyId,
  ) async {
    if (legacyId == null) return null;
    final legStr = legacyId.toString();

    // 1. Direct match with exact company scope
    final existing = await db
        .customSelect(
          'SELECT new_uuid FROM _legacy_id_mappings WHERE company_id = ? AND entity_type = ? AND legacy_id = ?;',
          variables: [
            Variable.withString(companyId),
            Variable.withString(entityType),
            Variable.withString(legStr),
          ],
        )
        .getSingleOrNull();

    if (existing != null) {
      return existing.read<String>('new_uuid');
    }

    // 2. Fallback to system scope if not found under specific company
    if (companyId != '__SYSTEM__') {
      final sysExisting = await db
          .customSelect(
            'SELECT new_uuid FROM _legacy_id_mappings WHERE company_id = ? AND entity_type = ? AND legacy_id = ?;',
            variables: [
              Variable.withString('__SYSTEM__'),
              Variable.withString(entityType),
              Variable.withString(legStr),
            ],
          )
          .getSingleOrNull();
      if (sysExisting != null) {
        return sysExisting.read<String>('new_uuid');
      }
    }

    return null;
  }

  Future<String?> _resolveCompanyUuid(dynamic rawCompanyId) async {
    if (rawCompanyId == null) return null;
    final str = rawCompanyId.toString();
    if (str.length == 36 && str.contains('-')) {
      return str;
    }
    return await _lookupUuid('__SYSTEM__', 'companies', str);
  }

  Future<String?> _resolveDocumentUuid(
    String companyId,
    String? docType,
    dynamic legacyDocId,
  ) async {
    if (legacyDocId == null) return null;
    final str = legacyDocId.toString();
    if (str.length == 36 && str.contains('-')) return str;
    if (docType == null) return null;
    final normalized = docType.toLowerCase();
    if (normalized.contains('receipt')) {
      return await _lookupUuid(companyId, 'stock_receipts', str);
    } else if (normalized.contains('issue')) {
      return await _lookupUuid(companyId, 'stock_issues', str);
    } else if (normalized.contains('sale')) {
      return await _lookupUuid(companyId, 'sales', str);
    } else if (normalized.contains('purchase')) {
      return await _lookupUuid(companyId, 'purchases', str);
    } else if (normalized.contains('return')) {
      return await _lookupUuid(companyId, 'stock_returns', str);
    } else if (normalized.contains('transfer')) {
      return await _lookupUuid(companyId, 'stock_transfers', str);
    }
    return null;
  }

  DateTime? _asDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
    }
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  double? _asDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  int? _asInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  bool? _asBool(dynamic val) {
    if (val == null) return null;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val == '1' || val.toLowerCase() == 'true';
    return null;
  }
}
