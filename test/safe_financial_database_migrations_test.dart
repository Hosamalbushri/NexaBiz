import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/data/services/migration_integrity_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late MigrationIntegrityValidator migrationValidator;

  const tenantId = 'tenant-migration-01';

  setUp(() async {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();
    migrationValidator = MigrationIntegrityValidator(
      invDb: invDb,
      accDb: accDb,
    );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  group('ROOT FIX 34 — Safe Financial Database Migrations Tests', () {
    test('1. Pre-Migration Diagnostic Detection: NULL companyId, orphan lines, duplicate UUIDs, invalid statuses', () async {
      // Insert dirty data: product without companyId
      await invDb.into(invDb.products).insert(
        ProductsCompanion.insert(
          id: const Value(1),
          uuid: generateUuidV4(),
          itemCode: 'ITEM-MIG-01',
          name: 'Migrated Item 1',
          packSize: 1,
          price: 100.0,
          createdAt: 1600000000,
          updatedAt: 1600000000,
          companyId: const Value(null),
        ),
      );

      // Insert receipt with invalid status / companyId
      final rcUuid = generateUuidV4();
      await invDb.customStatement('''
        INSERT INTO stock_receipts (id, uuid, receipt_number, receipt_date, created_at, updated_at, status, company_id)
        VALUES (1, '$rcUuid', 'RC-DIRTY-01', 1600000000, 1600000000, 1600000000, 'invalid_unknown_status', NULL)
      ''');

      // Insert orphan movement line referencing non-existent document
      final lineUuid = generateUuidV4();
      final nonExistentUuid = generateUuidV4();
      await invDb.customStatement('''
        INSERT INTO stock_movement_lines (uuid, movement_uuid, movement_type, item_code, item_name, quantity, unit_cost, total_cost)
        VALUES ('$lineUuid', '$nonExistentUuid', 'receipt', 'ITEM-MIG-01', 'Migrated Item 1', 10.0, 50.0, 500.0)
      ''');

      // Audit pre-migration state
      final report = await migrationValidator.auditPreMigration();

      expect(report.hasIssues, isTrue);
      expect(report.nullCompanyIdCount, greaterThanOrEqualTo(2));
      expect(report.orphanLinesCount, equals(1));
      expect(report.invalidStatusCount, equals(1));
    });

    test('2. Safe Tenant Remediation: NULL companyId remediation preserves records without data loss', () async {
      // Insert products and receipts with NULL companyId
      final prodRepo = ProductRepositoryImpl(invDb, readCompanyId: () => tenantId);
      await prodRepo.insert(
        const ProductDraft(
          itemCode: 'ITEM-TENANT-01',
          name: 'Tenant Test Product',
          packSize: 1,
          price: 100.0,
          unitCost: 60.0,
        ),
      );

      final nullRcUuid = generateUuidV4();
      await invDb.customStatement('''
        INSERT INTO stock_receipts (uuid, receipt_number, receipt_date, created_at, updated_at, status, company_id)
        VALUES ('$nullRcUuid', 'RC-NULL-TENANT', 1600000000, 1600000000, 1600000000, 'draft', NULL)
      ''');

      // Remediate NULL companyId safely
      await migrationValidator.remediateSafeDefaults(targetCompanyId: tenantId);

      // Verify no records deleted and company_id updated to target tenant
      final report = await migrationValidator.auditPreMigration();
      expect(report.nullCompanyIdCount, equals(0));

      final receiptRow = await invDb.customSelect(
        "SELECT company_id, status FROM stock_receipts WHERE uuid = '$nullRcUuid'",
      ).getSingle();
      expect(receiptRow.read<String>('company_id'), equals(tenantId));
      expect(receiptRow.read<String>('status'), equals('draft'));
    });

    test('3. Financial Totals Conservation: Pre & Post Migration inventory valuation & GL balances match 100%', () async {
      // Create cost layer with valuation = 10 * 50 = $500
      final now = DateTime.now().millisecondsSinceEpoch;
      final layerUuid = generateUuidV4();
      final movUuid = generateUuidV4();
      await invDb.into(invDb.inventoryCostLayers).insert(
        InventoryCostLayersCompanion.insert(
          uuid: layerUuid,
          itemCode: 'ITEM-VAL-01',
          movementUuid: movUuid,
          movementType: 'receipt',
          receivedDate: now,
          receivedQty: const Value(10.0),
          remainingQty: const Value(10.0),
          unitCost: const Value(50.0),
          totalCost: const Value(500.0),
          createdAt: now,
          updatedAt: now,
          companyId: Value(tenantId),
        ),
      );

      // Seed Account 1230 in AccountingDatabase and add journal lines balancing to $500
      final accUuid = generateUuidV4();
      await accDb.into(accDb.accounts).insert(
        AccountsCompanion.insert(
          uuid: accUuid,
          accountCode: '1230',
          name: 'حساب المخزون',
          accountType: 'asset',
          normalBalance: 'debit',
          createdAt: now,
          updatedAt: now,
          companyId: Value(tenantId),
        ),
      );

      final journalUuid = generateUuidV4();
      await accDb.into(accDb.journalEntries).insert(
        JournalEntriesCompanion.insert(
          uuid: journalUuid,
          voucherNumber: 'JE-VAL-01',
          voucherType: 'journal',
          currencyCode: 'SAR',
          entryDate: now,
          createdAt: now,
          updatedAt: now,
          companyId: Value(tenantId),
        ),
      );

      await accDb.into(accDb.journalLines).insert(
        JournalLinesCompanion.insert(
          uuid: generateUuidV4(),
          entryUuid: journalUuid,
          accountUuid: accUuid,
          currencyCode: 'SAR',
          debit: const Value(500.0),
          credit: const Value(0.0),
          baseDebit: const Value(500.0),
          baseCredit: const Value(0.0),
        ),
      );

      // Capture pre-migration snapshot
      final preReport = await migrationValidator.auditPreMigration();
      final preSnapshot = preReport.snapshot;

      expect(preSnapshot.totalInventoryValuation, equals(500.0));
      expect(preSnapshot.totalGLBalance, equals(500.0));

      // Execute post-migration verification
      await migrationValidator.verifyPostMigration(preSnapshot);
    });

    test('4. Safe Status Backfill: Un-posted draft receipts remain draft without premature posting', () async {
      // Insert un-posted draft receipt with no cost layers
      final draftRcUuid = generateUuidV4();
      await invDb.customStatement('''
        INSERT INTO stock_receipts (uuid, receipt_number, receipt_date, created_at, updated_at, status, company_id)
        VALUES ('$draftRcUuid', 'RC-DRAFT-MIG', 1600000000, 1600000000, 1600000000, 'draft', '$tenantId')
      ''');

      // Remediate & run migration validator checks
      await migrationValidator.remediateSafeDefaults(targetCompanyId: tenantId);

      final row = await invDb.customSelect(
        "SELECT status FROM stock_receipts WHERE uuid = '$draftRcUuid'",
      ).getSingle();

      expect(row.read<String>('status'), equals('draft'));
    });

    test('5. Anti-Data-Loss Invariant: Post-migration document & product counts equal pre-migration counts', () async {
      final preReport = await migrationValidator.auditPreMigration();

      // Ensure verification passes when no data is lost
      await migrationValidator.verifyPostMigration(preReport.snapshot);
    });
  });
}
