import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/app/migration/migration_integrity_validator.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late MigrationIntegrityValidator migrationValidator;

  const tenantId = 'tenant-migration-01';

  setUp(() async {
    db = NexabizDatabase.memory();
    migrationValidator = MigrationIntegrityValidator(
      invDb: db,
      accDb: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ROOT FIX 34 — Safe Financial Database Migrations Tests', () {
    test(
      '1. Pre-Migration Diagnostic Detection: NULL companyId, orphan lines, duplicate UUIDs, invalid statuses',
      () async {
        // Insert dirty data: stock_receipt without companyId
        final rcUuid = generateUuidV7();
        await db.customStatement('''
          INSERT INTO stock_receipts (id, receipt_number, currency_code, receipt_date, created_at, updated_at, status, company_id)
          VALUES ('$rcUuid', 'RC-DIRTY-01', 'SAR', 1600000000, 1600000000, 1600000000, 'invalid_unknown_status', NULL)
        ''');

        // Insert journal entry without companyId
        final jeUuid = generateUuidV7();
        await db.customStatement('''
          INSERT INTO journal_entries (id, voucher_number, voucher_type, currency_code, entry_date, created_at, updated_at, company_id)
          VALUES ('$jeUuid', 'JE-DIRTY-01', 'journal', 'SAR', 1600000000, 1600000000, 1600000000, NULL)
        ''');

        // Insert orphan movement line referencing non-existent document
        final lineUuid = generateUuidV7();
        await db.customStatement('''
          INSERT INTO stock_movement_lines (id, movement_type, item_code, item_name, quantity, unit_cost, total_cost, company_id)
          VALUES ('$lineUuid', 'receipt', 'ITEM-MIG-01', 'Migrated Item 1', 10.0, 50.0, 500.0, '$tenantId')
        ''');

        // Audit pre-migration state
        final report = await migrationValidator.auditPreMigration();

        expect(report.hasIssues, isTrue);
        expect(report.nullCompanyIdCount, greaterThanOrEqualTo(2));
        expect(report.orphanLinesCount, equals(1));
        expect(report.invalidStatusCount, equals(1));
      },
    );

    test(
      '2. Safe Tenant Remediation: NULL companyId remediation preserves records without data loss',
      () async {
        final jeUuid = generateUuidV7();
        await db.customStatement('''
          INSERT INTO journal_entries (id, voucher_number, voucher_type, currency_code, entry_date, created_at, updated_at, company_id)
          VALUES ('$jeUuid', 'JE-TENANT-01', 'journal', 'SAR', 1600000000, 1600000000, 1600000000, NULL)
        ''');

        final nullRcUuid = generateUuidV7();
        await db.customStatement('''
          INSERT INTO stock_receipts (id, receipt_number, currency_code, receipt_date, created_at, updated_at, status, company_id)
          VALUES ('$nullRcUuid', 'RC-NULL-TENANT', 'SAR', 1600000000, 1600000000, 1600000000, 'draft', NULL)
        ''');

        // Remediate NULL companyId safely
        await migrationValidator.remediateSafeDefaults(
          targetCompanyId: tenantId,
        );

        // Verify no records deleted and company_id updated to target tenant
        final report = await migrationValidator.auditPreMigration();
        expect(report.nullCompanyIdCount, equals(0));

        final receiptRow = await db
            .customSelect(
              "SELECT company_id, status FROM stock_receipts WHERE id = '$nullRcUuid'",
            )
            .getSingle();
        expect(receiptRow.read<String>('company_id'), equals(tenantId));
        expect(receiptRow.read<String>('status'), equals('draft'));
      },
    );

    test(
      '3. Financial Totals Conservation: Pre & Post Migration inventory valuation & GL balances match 100%',
      () async {
        // Create cost layer with valuation = 10 * 50 = $500
        final now = DateTime.now().millisecondsSinceEpoch;
        final layerUuid = generateUuidV7();
        final movUuid = generateUuidV7();
        await db
            .into(db.inventoryCostLayers)
            .insert(
              InventoryCostLayersCompanion.insert(
                id: Value(layerUuid),
                itemCode: 'ITEM-VAL-01',
                movementId: movUuid,
                movementType: 'receipt',
                receivedDate: now,
                receivedQty: const Value(10.0),
                remainingQty: const Value(10.0),
                unitCost: const Value(50.0),
                totalCost: const Value(500.0),
                inventoryCurrencyId: 'YER',
                documentCurrencyId: 'SAR',
                exchangeRate: const Value(1.0),
                createdAt: now,
                updatedAt: now,
                companyId: Value(tenantId),
              ),
            );

        // Seed Account 1230 in Database and add journal lines balancing to $500
        final accUuid = generateUuidV7();
        await db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(accUuid),
                accountCode: '1230',
                name: 'حساب المخزون',
                accountType: 'asset',
                normalBalance: 'debit',
                companyId: tenantId,
              ),
            );

        final journalUuid = generateUuidV7();
        await db
            .into(db.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                id: Value(journalUuid),
                voucherNumber: 'JE-VAL-01',
                voucherType: 'journal',
                currencyCode: 'SAR',
                entryDate: now,
                createdAt: now,
                updatedAt: now,
                companyId: Value(tenantId),
              ),
            );

        await db
            .into(db.journalLines)
            .insert(
              JournalLinesCompanion.insert(
                id: Value(generateUuidV7()),
                entryId: journalUuid,
                accountId: accUuid,
                currencyCode: 'SAR',
                debit: const Value(500.0),
                credit: const Value(0.0),
                baseDebit: const Value(500.0),
                baseCredit: const Value(0.0),
                companyId: Value(tenantId),
              ),
            );

        // Capture pre-migration snapshot
        final preReport = await migrationValidator.auditPreMigration();
        final preSnapshot = preReport.snapshot;

        expect(preSnapshot.totalInventoryValuation, equals(500.0));
        expect(preSnapshot.totalGLBalance, equals(500.0));

        // Execute post-migration verification
        await migrationValidator.verifyPostMigration(preSnapshot);
      },
    );

    test(
      '4. Safe Status Backfill: Un-posted draft receipts remain draft without premature posting',
      () async {
        // Insert un-posted draft receipt with no cost layers
        final draftRcUuid = generateUuidV7();
        await db.customStatement('''
          INSERT INTO stock_receipts (id, receipt_number, currency_code, receipt_date, created_at, updated_at, status, company_id)
          VALUES ('$draftRcUuid', 'RC-DRAFT-MIG', 'SAR', 1600000000, 1600000000, 1600000000, 'draft', '$tenantId')
        ''');

        // Remediate & run migration validator checks
        await migrationValidator.remediateSafeDefaults(
          targetCompanyId: tenantId,
        );

        final row = await db
            .customSelect(
              "SELECT status FROM stock_receipts WHERE id = '$draftRcUuid'",
            )
            .getSingle();

        expect(row.read<String>('status'), equals('draft'));
      },
    );

    test(
      '5. Anti-Data-Loss Invariant: Post-migration document & product counts equal pre-migration counts',
      () async {
        final preReport = await migrationValidator.auditPreMigration();

        // Ensure verification passes when no data is lost
        await migrationValidator.verifyPostMigration(preReport.snapshot);
      },
    );
  });
}
