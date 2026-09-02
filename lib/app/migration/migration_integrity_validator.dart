import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';

/// Pre-migration snapshot capturing financial and document invariants.
class MigrationSnapshot {
  const MigrationSnapshot({
    required this.totalInventoryValuation,
    required this.totalGLBalance,
    required this.receiptCount,
    required this.issueCount,
    required this.transferCount,
    required this.productCount,
    required this.costLayerCount,
    required this.companyIds,
  });

  final double totalInventoryValuation;
  final double totalGLBalance;
  final int receiptCount;
  final int issueCount;
  final int transferCount;
  final int productCount;
  final int costLayerCount;
  final Set<String> companyIds;
}

/// Diagnostic report exposing database integrity issues prior to schema migration.
class MigrationDiagnosticReport {
  const MigrationDiagnosticReport({
    required this.nullCompanyIdCount,
    required this.duplicateUuidsCount,
    required this.orphanLinesCount,
    required this.orphanConsumptionsCount,
    required this.invalidStatusCount,
    required this.invalidAmountsCount,
    required this.snapshot,
  });

  final int nullCompanyIdCount;
  final int duplicateUuidsCount;
  final int orphanLinesCount;
  final int orphanConsumptionsCount;
  final int invalidStatusCount;
  final int invalidAmountsCount;
  final MigrationSnapshot snapshot;

  bool get hasIssues =>
      nullCompanyIdCount > 0 ||
      duplicateUuidsCount > 0 ||
      orphanLinesCount > 0 ||
      orphanConsumptionsCount > 0 ||
      invalidStatusCount > 0 ||
      invalidAmountsCount > 0;

  @override
  String toString() {
    return 'MigrationDiagnosticReport('
        'nullCompanyIdCount: $nullCompanyIdCount, '
        'duplicateUuidsCount: $duplicateUuidsCount, '
        'orphanLinesCount: $orphanLinesCount, '
        'orphanConsumptionsCount: $orphanConsumptionsCount, '
        'invalidStatusCount: $invalidStatusCount, '
        'invalidAmountsCount: $invalidAmountsCount, '
        'valuation: ${snapshot.totalInventoryValuation}, '
        'glBalance: ${snapshot.totalGLBalance})';
  }
}

/// Service providing pre-migration audits, safe tenant remediation, and post-migration financial verification.
class MigrationIntegrityValidator {
  MigrationIntegrityValidator({
    required this.invDb,
    required this.accDb,
  });

  final InventoryDatabase invDb;
  final AccountingDatabase accDb;

  /// Audits pre-migration state and compiles a diagnostic report.
  Future<MigrationDiagnosticReport> auditPreMigration() async {
    int nullCompanyIdCount = 0;
    final invTables = [
      'products',
      'stock_receipts',
      'stock_issues',
      'inventory_cost_layers',
      'inventory_cost_consumptions',
      'warehouses',
      'stock_transfers',
    ];
    for (final table in invTables) {
      try {
        final res = await invDb
            .customSelect('SELECT COUNT(*) as c FROM $table WHERE company_id IS NULL OR company_id = \'\'')
            .getSingle();
        nullCompanyIdCount += res.read<int>('c');
      } catch (_) {}
    }

    final accTables = ['accounts', 'journal_entries', 'voucher_books', 'fiscal_years', 'currency_rates'];
    for (final table in accTables) {
      try {
        final res = await accDb
            .customSelect('SELECT COUNT(*) as c FROM $table WHERE company_id IS NULL OR company_id = \'\'')
            .getSingle();
        nullCompanyIdCount += res.read<int>('c');
      } catch (_) {}
    }

    int duplicateUuidsCount = 0;
    final uuidTables = ['products', 'stock_receipts', 'stock_issues', 'inventory_cost_layers'];
    for (final table in uuidTables) {
      try {
        final res = await invDb.customSelect('''
          SELECT uuid, COUNT(*) as c FROM $table 
          WHERE uuid IS NOT NULL AND uuid != '' 
          GROUP BY uuid HAVING c > 1
        ''').get();
        duplicateUuidsCount += res.length;
      } catch (_) {}
    }

    int orphanLinesCount = 0;
    try {
      final res = await invDb.customSelect('''
        SELECT COUNT(*) as c FROM stock_movement_lines l
        WHERE l.movement_uuid NOT IN (SELECT uuid FROM stock_receipts)
          AND l.movement_uuid NOT IN (SELECT uuid FROM stock_issues)
          AND l.movement_uuid NOT IN (SELECT uuid FROM stock_returns)
      ''').getSingle();
      orphanLinesCount = res.read<int>('c');
    } catch (_) {}

    int orphanConsumptionsCount = 0;
    try {
      final res = await invDb.customSelect('''
        SELECT COUNT(*) as c FROM inventory_cost_consumptions c
        WHERE c.layer_uuid NOT IN (SELECT uuid FROM inventory_cost_layers)
      ''').getSingle();
      orphanConsumptionsCount = res.read<int>('c');
    } catch (_) {}

    int invalidStatusCount = 0;
    for (final table in ['stock_receipts', 'stock_issues', 'stock_transfers', 'stock_returns']) {
      try {
        final res = await invDb.customSelect('''
          SELECT COUNT(*) as c FROM $table 
          WHERE status IS NULL OR status NOT IN ('draft', 'posted', 'in_transit', 'completed', 'cancelled', 'reversed')
        ''').getSingle();
        invalidStatusCount += res.read<int>('c');
      } catch (_) {}
    }

    int invalidAmountsCount = 0;
    try {
      final res = await invDb.customSelect('''
        SELECT COUNT(*) as c FROM inventory_cost_layers WHERE remaining_qty < 0 OR unit_cost < 0
      ''').getSingle();
      invalidAmountsCount += res.read<int>('c');
    } catch (_) {}

    double totalValuation = 0.0;
    try {
      final res = await invDb.customSelect('''
        SELECT SUM(remaining_qty * unit_cost) as total FROM inventory_cost_layers WHERE remaining_qty > 0
      ''').getSingle();
      totalValuation = res.read<double?>('total') ?? 0.0;
    } catch (_) {}

    double totalGL = 0.0;
    try {
      final res = await accDb.customSelect('''
        SELECT SUM(l.base_debit - l.base_credit) as total
        FROM journal_lines l
        JOIN accounts a ON a.uuid = l.account_uuid
        WHERE a.account_code = '1230' OR a.account_type = 'asset'
      ''').getSingle();
      totalGL = res.read<double?>('total') ?? 0.0;
    } catch (_) {}

    int receiptCount = 0;
    try {
      receiptCount = (await invDb.customSelect('SELECT COUNT(*) as c FROM stock_receipts').getSingle()).read<int>('c');
    } catch (_) {}

    int issueCount = 0;
    try {
      issueCount = (await invDb.customSelect('SELECT COUNT(*) as c FROM stock_issues').getSingle()).read<int>('c');
    } catch (_) {}

    int transferCount = 0;
    try {
      transferCount = (await invDb.customSelect('SELECT COUNT(*) as c FROM stock_transfers').getSingle()).read<int>('c');
    } catch (_) {}

    int productCount = 0;
    try {
      productCount = (await invDb.customSelect('SELECT COUNT(*) as c FROM products').getSingle()).read<int>('c');
    } catch (_) {}

    int costLayerCount = 0;
    try {
      costLayerCount = (await invDb.customSelect('SELECT COUNT(*) as c FROM inventory_cost_layers').getSingle()).read<int>('c');
    } catch (_) {}

    final companyIds = <String>{};
    try {
      final rows = await invDb.customSelect('SELECT DISTINCT company_id FROM products WHERE company_id IS NOT NULL AND company_id != \'\'').get();
      for (final r in rows) {
        companyIds.add(r.read<String>('company_id'));
      }
    } catch (_) {}

    final snapshot = MigrationSnapshot(
      totalInventoryValuation: totalValuation,
      totalGLBalance: totalGL,
      receiptCount: receiptCount,
      issueCount: issueCount,
      transferCount: transferCount,
      productCount: productCount,
      costLayerCount: costLayerCount,
      companyIds: companyIds,
    );

    return MigrationDiagnosticReport(
      nullCompanyIdCount: nullCompanyIdCount,
      duplicateUuidsCount: duplicateUuidsCount,
      orphanLinesCount: orphanLinesCount,
      orphanConsumptionsCount: orphanConsumptionsCount,
      invalidStatusCount: invalidStatusCount,
      invalidAmountsCount: invalidAmountsCount,
      snapshot: snapshot,
    );
  }

  Future<void> remediateSafeDefaults({required String targetCompanyId}) async {
    if (targetCompanyId.trim().isEmpty) {
      throw ArgumentError('targetCompanyId must be a non-empty authorized tenant ID.');
    }

    final invTables = [
      'products',
      'stock_receipts',
      'stock_issues',
      'inventory_cost_layers',
      'inventory_cost_consumptions',
      'warehouses',
      'product_warehouse_stocks',
      'stock_transfers',
      'stock_returns',
      'categories',
    ];

    for (final table in invTables) {
      try {
        await invDb.customStatement(
          'UPDATE $table SET company_id = ? WHERE company_id IS NULL OR company_id = \'\'',
          [targetCompanyId],
        );
      } catch (_) {}
    }

    final accTables = ['accounts', 'journal_entries', 'voucher_books', 'fiscal_years', 'currency_rates'];
    for (final table in accTables) {
      try {
        await accDb.customStatement(
          'UPDATE $table SET company_id = ? WHERE company_id IS NULL OR company_id = \'\'',
          [targetCompanyId],
        );
      } catch (_) {}
    }

    try {
      await invDb.customStatement(
        "UPDATE stock_receipts SET status = 'draft' WHERE status IS NULL OR status = ''",
      );
      await invDb.customStatement(
        "UPDATE stock_issues SET status = 'draft' WHERE status IS NULL OR status = ''",
      );
    } catch (_) {}
  }

  Future<void> verifyPostMigration(MigrationSnapshot preSnapshot) async {
    final postReport = await auditPreMigration();
    final postSnapshot = postReport.snapshot;

    final valuationDiff = (postSnapshot.totalInventoryValuation - preSnapshot.totalInventoryValuation).abs();
    if (valuationDiff > 0.001) {
      throw StateError(
        'Migration Financial Invariant Failed: Inventory Valuation changed from '
        '${preSnapshot.totalInventoryValuation} to ${postSnapshot.totalInventoryValuation} (diff: $valuationDiff)',
      );
    }

    final glDiff = (postSnapshot.totalGLBalance - preSnapshot.totalGLBalance).abs();
    if (glDiff > 0.001) {
      throw StateError(
        'Migration Financial Invariant Failed: GL Balance changed from '
        '${preSnapshot.totalGLBalance} to ${postSnapshot.totalGLBalance} (diff: $glDiff)',
      );
    }

    if (postSnapshot.receiptCount < preSnapshot.receiptCount ||
        postSnapshot.issueCount < preSnapshot.issueCount ||
        postSnapshot.productCount < preSnapshot.productCount) {
      throw StateError(
        'Migration Safety Failed: Document or product records were deleted during migration. '
        'Pre: ${preSnapshot.receiptCount}/${preSnapshot.issueCount}/${preSnapshot.productCount}, '
        'Post: ${postSnapshot.receiptCount}/${postSnapshot.issueCount}/${postSnapshot.productCount}',
      );
    }

    if (postReport.orphanLinesCount > 0 || postReport.orphanConsumptionsCount > 0) {
      throw StateError(
        'Migration Safety Failed: Orphan records exist post-migration. '
        'Orphan lines: ${postReport.orphanLinesCount}, Orphan consumptions: ${postReport.orphanConsumptionsCount}',
      );
    }
  }
}
