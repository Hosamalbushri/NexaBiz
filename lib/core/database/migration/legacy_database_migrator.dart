import 'package:drift/drift.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Production-safe legacy database migrator for upgrading existing NexaBiz SQLite databases
/// from legacy integer-ID schemas to the canonical UUID v7 physical schema.
class LegacyDatabaseMigrator {
  LegacyDatabaseMigrator(this.db);

  final NexabizDatabase db;

  /// Main entry point for executing schema and data upgrade from legacy schema version.
  Future<void> migrateFromLegacy({
    required Migrator migrator,
    required int fromVersion,
    required int toVersion,
  }) async {
    // 1. Enable foreign keys disabled during DDL transformation if needed
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    try {
      // 2. Initialize persistent migration mapping table
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS _legacy_id_mappings (
          entity_type TEXT NOT NULL,
          legacy_id TEXT NOT NULL,
          new_uuid TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          PRIMARY KEY (entity_type, legacy_id),
          UNIQUE (entity_type, new_uuid)
        );
      ''');

      // 3. Migrate tables in strict dependency order:
      // Order 1: Foundation (Companies, Users, CompanyMemberships, Currencies)
      await _migrateTableIfLegacy('companies', db.companies, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('companies', legacyId);
        return CompaniesCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? 'COMP-$legacyId',
          name: row['name']?.toString() ?? 'Migrated Company $legacyId',
          baseCurrencyCode: Value(row['base_currency_code']?.toString() ?? 'YER'),
          inventoryCurrencyCode: Value(row['inventory_currency_code']?.toString() ?? 'SAR'),
          status: Value(row['status']?.toString() ?? 'active'),
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('users', db.users, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('users', legacyId);
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

      await _migrateTableIfLegacy('company_memberships', db.companyMemberships, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('company_memberships', legacyId);
        final userId = await _lookupUuid('users', row['user_id']) ?? uuid;
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        return CompanyMembershipsCompanion.insert(
          id: Value(uuid),
          userId: userId,
          companyId: companyId,
          role: Value(row['role']?.toString() ?? 'member'),
          status: Value(row['status']?.toString() ?? 'active'),
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('currencies', db.currencies, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('currencies', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']);
        return CurrenciesCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? row['currency_code']?.toString() ?? 'CUR-$legacyId',
          currencyCode: Value(row['currency_code']?.toString() ?? 'CUR-$legacyId'),
          name: Value(row['name']?.toString()),
          nameAr: Value(row['name_ar']?.toString() ?? 'عملة $legacyId'),
          nameEn: Value(row['name_en']?.toString() ?? 'Currency $legacyId'),
          symbol: row['symbol']?.toString() ?? 'SAR',
          isBase: Value(_asBool(row['is_base_currency']) ?? _asBool(row['is_base']) ?? false),
          isDefault: Value(_asBool(row['is_default']) ?? false),
          decimalDigits: Value(_asInt(row['decimal_digits']) ?? 2),
          companyId: Value(companyId),
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      // Order 2: Master Data
      await _migrateTableIfLegacy('product_categories', db.productCategories, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('product_categories', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        final parentId = await _lookupUuid('product_categories', row['parent_id']);
        return ProductCategoriesCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? row['category_code']?.toString() ?? 'CAT-$legacyId',
          name: row['name']?.toString() ?? 'Category $legacyId',
          parentCategoryId: Value(parentId),
          isActive: Value(_asBool(row['is_active']) ?? true),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('warehouses', db.warehouses, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('warehouses', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        return WarehousesCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? row['warehouse_code']?.toString() ?? 'WH-$legacyId',
          name: row['name']?.toString() ?? 'Warehouse $legacyId',
          address: Value(row['address']?.toString() ?? row['location']?.toString()),
          phone: Value(row['phone']?.toString()),
          isActive: Value(_asBool(row['is_active']) ?? true),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('accounts', db.accounts, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('accounts', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        final parentId = await _lookupUuid('accounts', row['parent_id']);
        return AccountsCompanion.insert(
          id: Value(uuid),
          accountCode: row['account_code']?.toString() ?? 'ACC-$legacyId',
          name: row['name']?.toString() ?? 'Account $legacyId',
          accountType: row['account_type']?.toString() ?? 'asset',
          normalBalance: row['normal_balance']?.toString() ?? 'debit',
          parentAccountId: Value(parentId),
          isActive: Value(_asBool(row['is_active']) ?? true),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('products', db.products, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('products', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        final categoryId = await _lookupUuid('product_categories', row['category_id']);
        return ProductsCompanion.insert(
          id: Value(uuid),
          itemCode: row['item_code']?.toString() ?? 'PROD-$legacyId',
          name: row['name']?.toString() ?? 'Product $legacyId',
          barcode: Value(row['barcode']?.toString()),
          categoryId: Value(categoryId),
          packSize: Value(_asInt(row['pack_size']) ?? 1),
          price: Value(_asDouble(row['price']) ?? 0.0),
          unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('customers', db.customers, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('customers', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        final accountId = await _lookupUuid('accounts', row['account_id']);
        return CustomersCompanion.insert(
          id: Value(uuid),
          customerCode: row['customer_code']?.toString() ?? 'CUST-$legacyId',
          name: row['name']?.toString() ?? 'Customer $legacyId',
          phone: Value(row['phone']?.toString()),
          email: Value(row['email']?.toString()),
          address: Value(row['address']?.toString()),
          accountId: Value(accountId),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('suppliers', db.suppliers, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('suppliers', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        final accountId = await _lookupUuid('accounts', row['account_id']);
        return SuppliersCompanion.insert(
          id: Value(uuid),
          supplierCode: row['supplier_code']?.toString() ?? 'SUPP-$legacyId',
          name: row['name']?.toString() ?? 'Supplier $legacyId',
          phone: Value(row['phone']?.toString()),
          email: Value(row['email']?.toString()),
          address: Value(row['address']?.toString()),
          accountId: Value(accountId),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('cash_registers', db.cashRegisters, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('cash_registers', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        final accountId = await _lookupUuid('accounts', row['account_id']);
        return CashRegistersCompanion.insert(
          id: Value(uuid),
          code: row['code']?.toString() ?? row['register_code']?.toString() ?? 'REG-$legacyId',
          name: row['name']?.toString() ?? 'Cash Register $legacyId',
          accountId: Value(accountId),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      await _migrateTableIfLegacy('voucher_books', db.voucherBooks, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('voucher_books', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']) ?? uuid;
        return VoucherBooksCompanion.insert(
          id: Value(uuid),
          name: row['name']?.toString() ?? 'Voucher Book $legacyId',
          bookType: row['voucher_type']?.toString() ?? row['book_type']?.toString() ?? 'receipt',
          nextNumber: Value(_asInt(row['next_number']) ?? 1),
          companyId: companyId,
          createdAt: Value(_asDateTime(row['created_at']) ?? DateTime.now()),
          updatedAt: Value(_asDateTime(row['updated_at']) ?? DateTime.now()),
        );
      });

      // Order 3: Operational Documents & Ledgers
      await _migrateTableIfLegacy('stock_receipts', db.stockReceipts, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('stock_receipts', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']);
        final warehouseId = await _lookupUuid('warehouses', row['warehouse_id']);
        final supplierId = await _lookupUuid('suppliers', row['supplier_id']);
        return StockReceiptsCompanion.insert(
          id: Value(uuid),
          receiptNumber: row['receipt_number']?.toString() ?? 'REC-$legacyId',
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          receiptDate: _asInt(row['receipt_date']) ?? DateTime.now().millisecondsSinceEpoch,
          createdAt: _asInt(row['created_at']) ?? DateTime.now().millisecondsSinceEpoch,
          updatedAt: _asInt(row['updated_at']) ?? DateTime.now().millisecondsSinceEpoch,
          status: Value(row['status']?.toString() ?? 'draft'),
          warehouseId: Value(warehouseId),
          supplierId: Value(supplierId),
          companyId: Value(companyId),
        );
      });

      await _migrateTableIfLegacy('stock_issues', db.stockIssues, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('stock_issues', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']);
        final warehouseId = await _lookupUuid('warehouses', row['warehouse_id']);
        final customerId = await _lookupUuid('customers', row['customer_id']);
        return StockIssuesCompanion.insert(
          id: Value(uuid),
          issueNumber: row['issue_number']?.toString() ?? 'ISS-$legacyId',
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          issueDate: _asInt(row['issue_date']) ?? DateTime.now().millisecondsSinceEpoch,
          createdAt: _asInt(row['created_at']) ?? DateTime.now().millisecondsSinceEpoch,
          updatedAt: _asInt(row['updated_at']) ?? DateTime.now().millisecondsSinceEpoch,
          status: Value(row['status']?.toString() ?? 'draft'),
          warehouseId: Value(warehouseId),
          customerId: Value(customerId),
          companyId: Value(companyId),
        );
      });

      await _migrateTableIfLegacy('inventory_cost_layers', db.inventoryCostLayers, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('inventory_cost_layers', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']);
        final warehouseId = await _lookupUuid('warehouses', row['warehouse_id']);
        final receiptId = await _lookupUuid('stock_receipts', row['receipt_id']);
        final legacyMov = row['movement_uuid']?.toString();
        final movUuid = (legacyMov != null && legacyMov.length == 36)
            ? legacyMov
            : (await _lookupUuid('stock_receipts', legacyMov) ??
                await _lookupUuid('stock_issues', legacyMov) ??
                receiptId ??
                uuid);
        return InventoryCostLayersCompanion.insert(
          id: Value(uuid),
          itemCode: row['item_code']?.toString() ?? 'ITEM-$legacyId',
          movementUuid: movUuid,
          movementType: row['movement_type']?.toString() ?? 'receipt',
          receivedDate: _asInt(row['received_date']) ?? DateTime.now().millisecondsSinceEpoch,
          receivedQty: Value(_asDouble(row['received_qty']) ?? 0.0),
          remainingQty: Value(_asDouble(row['remaining_qty']) ?? 0.0),
          unitCost: Value(_asDouble(row['unit_cost']) ?? 0.0),
          totalCost: Value(_asDouble(row['total_cost']) ?? 0.0),
          inventoryCurrencyId: row['inventory_currency_id']?.toString() ?? 'YER',
          documentCurrencyId: row['currency_code']?.toString() ?? row['document_currency_id']?.toString() ?? 'SAR',
          exchangeRate: Value(_asDouble(row['exchange_rate']) ?? 1.0),
          unitCostInventoryCurrency: Value(_asDouble(row['unit_cost_inventory_currency']) ?? 0.0),
          totalCostInventoryCurrency: Value(_asDouble(row['total_cost_inventory_currency']) ?? 0.0),
          closed: Value(_asInt(row['closed']) ?? 0),
          warehouseId: Value(warehouseId),
          companyId: Value(companyId),
          createdAt: _asInt(row['created_at']) ?? DateTime.now().millisecondsSinceEpoch,
          updatedAt: _asInt(row['updated_at']) ?? DateTime.now().millisecondsSinceEpoch,
        );
      });

      await _migrateTableIfLegacy('journal_entries', db.journalEntries, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('journal_entries', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']);
        return JournalEntriesCompanion.insert(
          id: Value(uuid),
          voucherNumber: row['voucher_number']?.toString() ?? 'JE-$legacyId',
          voucherType: row['voucher_type']?.toString() ?? 'journal',
          currencyCode: row['currency_code']?.toString() ?? 'SAR',
          entryDate: _asInt(row['entry_date']) ?? DateTime.now().millisecondsSinceEpoch,
          description: Value(row['description']?.toString()),
          companyId: Value(companyId),
          createdAt: _asInt(row['created_at']) ?? DateTime.now().millisecondsSinceEpoch,
          updatedAt: _asInt(row['updated_at']) ?? DateTime.now().millisecondsSinceEpoch,
        );
      });

      await _migrateTableIfLegacy('journal_lines', db.journalLines, (row) async {
        final legacyId = row['id'].toString();
        final uuid = await _getOrCreateUuid('journal_lines', legacyId);
        final companyId = await _lookupUuid('companies', row['company_id']);
        final entryId = await _lookupUuid('journal_entries', row['journal_id']) ?? await _lookupUuid('journal_entries', row['entry_id']) ?? uuid;
        final accountId = await _lookupUuid('accounts', row['account_id']) ?? uuid;
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
          companyId: Value(companyId),
        );
      });
    } finally {
      // 4. Re-enable SQLite Foreign Keys and verify zero violations
      await db.customStatement('PRAGMA foreign_keys = ON;');
      final fkViolations = await db.customSelect('PRAGMA foreign_key_check;').get();
      if (fkViolations.isNotEmpty) {
        throw StateError(
          'Migration Safety Violation: PRAGMA foreign_key_check reported ${fkViolations.length} orphan foreign key references after upgrade!',
        );
      }
    }
  }

  /// Helper to check if a table exists with legacy integer primary key `id` and migrate its schema & rows.
  Future<void> _migrateTableIfLegacy(
    String tableName,
    TableInfo tableInfo,
    Future<Insertable> Function(Map<String, dynamic> row) rowMapper,
  ) async {
    // Check if table exists in SQLite
    final tableExists = (await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(tableName)],
    ).get()).isNotEmpty;

    if (!tableExists) return;

    // Check if table has INTEGER id column
    final pragmaInfo = await db.customSelect('PRAGMA table_info($tableName);').get();
    final idCol = pragmaInfo.firstWhere(
      (c) => c.read<String>('name') == 'id',
      orElse: () => pragmaInfo.first,
    );

    final isIntegerId = idCol.read<String>('type').toUpperCase().contains('INT');
    if (!isIntegerId) return; // Already TEXT UUID v7 physical schema!

    // Legacy table detected! Perform non-destructive copy & transform
    final tempName = '_legacy_$tableName';
    await db.customStatement('ALTER TABLE $tableName RENAME TO $tempName;');

    // Re-create canonical UUID table schema
    final m = Migrator(db);
    await m.createTable(tableInfo);

    // Read all rows from legacy table
    final legacyRows = await db.customSelect('SELECT * FROM $tempName;').get();

    for (final row in legacyRows) {
      final mapData = Map<String, dynamic>.from(row.data);
      final companion = await rowMapper(mapData);
      await db.into(tableInfo).insert(companion);
    }

    // Anti-Data-Loss Count Verification
    final newCount = (await db.customSelect('SELECT COUNT(*) as c FROM $tableName;').getSingle()).read<int>('c');
    if (newCount != legacyRows.length) {
      throw StateError(
        'Migration Safety Failure: Row count mismatch during $tableName migration. '
        'Legacy count: ${legacyRows.length}, Migrated count: $newCount',
      );
    }

    // Clean up temporary legacy table
    await db.customStatement('DROP TABLE $tempName;');
  }

  Future<String> _getOrCreateUuid(String entityType, String legacyId) async {
    final existing = await db.customSelect(
      'SELECT new_uuid FROM _legacy_id_mappings WHERE entity_type = ? AND legacy_id = ?;',
      variables: [Variable.withString(entityType), Variable.withString(legacyId)],
    ).getSingleOrNull();

    if (existing != null) {
      return existing.read<String>('new_uuid');
    }

    final newUuid = generateUuidV7();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO _legacy_id_mappings (entity_type, legacy_id, new_uuid, created_at) VALUES (?, ?, ?, ?);',
      [entityType, legacyId, newUuid, now],
    );
    return newUuid;
  }

  Future<String?> _lookupUuid(String entityType, dynamic legacyId) async {
    if (legacyId == null) return null;
    final legStr = legacyId.toString();
    final existing = await db.customSelect(
      'SELECT new_uuid FROM _legacy_id_mappings WHERE entity_type = ? AND legacy_id = ?;',
      variables: [Variable.withString(entityType), Variable.withString(legStr)],
    ).getSingleOrNull();

    return existing?.read<String>('new_uuid');
  }

  DateTime? _asDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
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
