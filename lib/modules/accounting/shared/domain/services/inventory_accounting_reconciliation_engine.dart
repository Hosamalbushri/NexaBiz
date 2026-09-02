import 'package:drift/drift.dart';
import 'package:stock_count/core/domain/services/inventory_subledger_port.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';

enum ReconciliationIssueType {
  missingJournalEntry,
  orphanJournalEntry,
  valueMismatch,
  tenantMismatch,
  subledgerGlMismatch,
}

class ReconciliationDiscrepancy {
  const ReconciliationDiscrepancy({
    required this.documentId,
    required this.documentNumber,
    required this.documentType,
    required this.issueType,
    required this.description,
    this.subledgerValue,
    this.glValue,
    this.companyId,
  });

  final String documentId;
  final String documentNumber;
  final String documentType;
  final ReconciliationIssueType issueType;
  final String description;
  final double? subledgerValue;
  final double? glValue;
  final String? companyId;

  @override
  String toString() =>
      'Discrepancy($documentType #$documentNumber: $issueType - $description)';
}

class ReconciliationReport {
  const ReconciliationReport({
    required this.companyId,
    required this.scannedDocumentCount,
    required this.discrepancies,
    required this.timestamp,
    this.subledgerValuation = 0.0,
    this.glInventoryBalance = 0.0,
  });

  final String companyId;
  final int scannedDocumentCount;
  final List<ReconciliationDiscrepancy> discrepancies;
  final DateTime timestamp;
  final double subledgerValuation;
  final double glInventoryBalance;

  bool get hasDiscrepancies => discrepancies.isNotEmpty;
  double get valuationDiscrepancy => (subledgerValuation - glInventoryBalance).abs();
}

class ReconciliationException implements Exception {
  const ReconciliationException(this.report);
  final ReconciliationReport report;

  @override
  String toString() =>
      'ReconciliationException: Found ${report.discrepancies.length} discrepancy(ies) for company ${report.companyId}:\n${report.discrepancies.map((d) => ' - $d').join('\n')}';
}

class InventoryAccountingReconciliationEngine {
  InventoryAccountingReconciliationEngine({
    required this._inventorySubledgerQuery,
    required this._accountingDb,
    this._readCompanyId,
  });

  final InventorySubledgerQueryPort _inventorySubledgerQuery;
  final AccountingDatabase _accountingDb;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  /// Calculate total inventory subledger valuation based on open, non-deleted cost layers
  Future<double> calculateSubledgerValuation({String? companyId}) async {
    final targetCompanyId = companyId ?? _currentCompanyId;
    return _inventorySubledgerQuery.calculateSubledgerValuation(
      companyId: targetCompanyId,
    );
  }

  /// Calculate total General Ledger inventory account balance (Net Debits - Credits)
  Future<double> calculateGlInventoryBalance({String? companyId}) async {
    final targetCompanyId = companyId ?? _currentCompanyId;
    final accounts = await (_accountingDb.select(_accountingDb.accounts)
          ..where((tbl) =>
              tbl.companyId.equals(targetCompanyId) &
              tbl.deletedAt.isNull() &
              (tbl.accountCode.equals('1230') |
                  tbl.description.equals('system:inventory') |
                  tbl.name.like('%Inventory%'))))
        .get();

    if (accounts.isEmpty) return 0.0;
    final accountUuids = accounts.map((a) => a.uuid).toList();

    final journalEntries = await (_accountingDb.select(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.companyId.equals(targetCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.isPosted.equals(true)))
        .get();

    if (journalEntries.isEmpty) return 0.0;
    final entryUuids = journalEntries.map((j) => j.uuid).toList();

    final jLines = await (_accountingDb.select(_accountingDb.journalLines)
          ..where((tbl) =>
              tbl.entryUuid.isIn(entryUuids) &
              tbl.accountUuid.isIn(accountUuids)))
        .get();

    double balance = 0.0;
    for (final jl in jLines) {
      balance += (jl.debit - jl.credit);
    }
    return balance;
  }

  Future<ReconciliationReport> runReconciliation({String? companyId}) async {
    final targetCompanyId = companyId ?? _currentCompanyId;
    final discrepancies = <ReconciliationDiscrepancy>[];
    int scannedCount = 0;

    // 1. Compute Subledger Valuation & GL Inventory Account Balance
    final subledgerValuation = await calculateSubledgerValuation(companyId: targetCompanyId);
    final glInventoryBalance = await calculateGlInventoryBalance(companyId: targetCompanyId);

    // If subledger valuation differs from GL inventory balance beyond tolerance (0.01)
    if ((subledgerValuation - glInventoryBalance).abs() > 0.01 && (subledgerValuation > 0 || glInventoryBalance > 0)) {
      discrepancies.add(
        ReconciliationDiscrepancy(
          documentId: 'subledger_gl_summary',
          documentNumber: 'GL-RECON',
          documentType: 'summary',
          issueType: ReconciliationIssueType.subledgerGlMismatch,
          description:
              'عدم تطابق إجمالي تقييم المخزون ($subledgerValuation) مع رصيد حساب المخزون في دفتر الأستاذ العام ($glInventoryBalance)',
          subledgerValue: subledgerValuation,
          glValue: glInventoryBalance,
          companyId: targetCompanyId,
        ),
      );
    }

    // 2. Audit Stock Receipts
    final receipts = await _inventorySubledgerQuery.getPostedStockReceipts(
      companyId: targetCompanyId,
    );

    for (final r in receipts) {
      scannedCount++;
      final subledgerCost = r.totalCost;

      final jes = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals('stock_receipt') &
                tbl.sourceId.equals(r.uuid) &
                tbl.deletedAt.isNull() &
                tbl.isPosted.equals(true)))
          .get();

      if (jes.isEmpty) {
        discrepancies.add(
          ReconciliationDiscrepancy(
            documentId: r.uuid,
            documentNumber: r.receiptNumber,
            documentType: 'stock_receipt',
            issueType: ReconciliationIssueType.missingJournalEntry,
            description: 'أمر توريد مرحّل بدون قيد محاسبي في الشجرة المحاسبية',
            subledgerValue: subledgerCost,
            glValue: 0.0,
            companyId: targetCompanyId,
          ),
        );
      } else {
        for (final je in jes) {
          if (je.companyId != targetCompanyId) {
            discrepancies.add(
              ReconciliationDiscrepancy(
                documentId: r.uuid,
                documentNumber: r.receiptNumber,
                documentType: 'stock_receipt',
                issueType: ReconciliationIssueType.tenantMismatch,
                description: 'القيد المحاسبي يتبع لشركة أخرى (${je.companyId})',
                companyId: targetCompanyId,
              ),
            );
          }
        }

        final jeUuids = jes.map((j) => j.uuid).toList();
        final jLines = await (_accountingDb.select(_accountingDb.journalLines)
              ..where((tbl) => tbl.entryUuid.isIn(jeUuids)))
            .get();

        double totalDebit = 0.0;
        for (final jl in jLines) {
          totalDebit += jl.debit;
        }

        if ((subledgerCost - totalDebit).abs() > 0.01 && subledgerCost > 0) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: r.uuid,
              documentNumber: r.receiptNumber,
              documentType: 'stock_receipt',
              issueType: ReconciliationIssueType.valueMismatch,
              description:
                  'تفاوت في القيمة بين المخزون ($subledgerCost) والقيود ($totalDebit)',
              subledgerValue: subledgerCost,
              glValue: totalDebit,
              companyId: targetCompanyId,
            ),
          );
        }
      }
    }

    // 3. Audit Stock Issues
    final issues = await _inventorySubledgerQuery.getPostedStockIssues(
      companyId: targetCompanyId,
    );

    for (final i in issues) {
      scannedCount++;
      final subledgerCost = i.totalCost;

      final jes = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals('stock_issue') &
                tbl.sourceId.equals(i.uuid) &
                tbl.deletedAt.isNull() &
                tbl.isPosted.equals(true)))
          .get();

      if (jes.isEmpty) {
        discrepancies.add(
          ReconciliationDiscrepancy(
            documentId: i.uuid,
            documentNumber: i.issueNumber,
            documentType: 'stock_issue',
            issueType: ReconciliationIssueType.missingJournalEntry,
            description: 'أمر صرف مرحّل بدون قيد محاسبي في الشجرة المحاسبية',
            subledgerValue: subledgerCost,
            glValue: 0.0,
            companyId: targetCompanyId,
          ),
        );
      } else {
        final jeUuids = jes.map((j) => j.uuid).toList();
        final jLines = await (_accountingDb.select(_accountingDb.journalLines)
              ..where((tbl) => tbl.entryUuid.isIn(jeUuids)))
            .get();

        double totalDebit = 0.0;
        for (final jl in jLines) {
          totalDebit += jl.debit;
        }

        if ((subledgerCost - totalDebit).abs() > 0.01 && subledgerCost > 0) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: i.uuid,
              documentNumber: i.issueNumber,
              documentType: 'stock_issue',
              issueType: ReconciliationIssueType.valueMismatch,
              description:
                  'تفاوت في القيمة بين تكلفة الصرف المحسوبة ($subledgerCost) والقيد المحاسبي ($totalDebit)',
              subledgerValue: subledgerCost,
              glValue: totalDebit,
              companyId: targetCompanyId,
            ),
          );
        }
      }
    }

    // 4. Audit Stock Returns
    final returns = await _inventorySubledgerQuery.getPostedStockReturns(
      companyId: targetCompanyId,
    );

    for (final ret in returns) {
      scannedCount++;
      final subledgerCost = ret.totalCost;

      final jes = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals('stock_return') &
                tbl.sourceId.equals(ret.uuid) &
                tbl.deletedAt.isNull() &
                tbl.isPosted.equals(true)))
          .get();

      if (jes.isEmpty && subledgerCost > 0) {
        discrepancies.add(
          ReconciliationDiscrepancy(
            documentId: ret.uuid,
            documentNumber: ret.returnNumber,
            documentType: 'stock_return',
            issueType: ReconciliationIssueType.missingJournalEntry,
            description: 'مرتجع مرحّل بدون قيد محاسبي في الشجرة المحاسبية',
            subledgerValue: subledgerCost,
            glValue: 0.0,
            companyId: targetCompanyId,
          ),
        );
      }
    }

    // 5. Audit Orphan Journal Entries
    final invJournals = await (_accountingDb.select(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.companyId.equals(targetCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.isPosted.equals(true) &
              tbl.sourceType.isIn(['stock_receipt', 'stock_issue', 'stock_return'])))
        .get();

    for (final je in invJournals) {
      final reversal = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals('journal_reverse') &
                tbl.sourceId.equals(je.uuid) &
                tbl.deletedAt.isNull() &
                tbl.isPosted.equals(true)))
          .getSingleOrNull();

      if (reversal != null) {
        continue;
      }

      if (je.sourceType == 'stock_receipt' && je.sourceId != null) {
        final exists = await _inventorySubledgerQuery.hasPostedStockReceipt(
          companyId: targetCompanyId,
          uuid: je.sourceId!,
        );
        if (!exists) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: je.sourceId!,
              documentNumber: je.voucherNumber,
              documentType: 'stock_receipt',
              issueType: ReconciliationIssueType.orphanJournalEntry,
              description: 'قيد محاسبي نشط لمستند توريد غير موجود أو غير مرحّل',
              glValue: 0.0,
              companyId: targetCompanyId,
            ),
          );
        }
      } else if (je.sourceType == 'stock_issue' && je.sourceId != null) {
        final exists = await _inventorySubledgerQuery.hasPostedStockIssue(
          companyId: targetCompanyId,
          uuid: je.sourceId!,
        );
        if (!exists) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: je.sourceId!,
              documentNumber: je.voucherNumber,
              documentType: 'stock_issue',
              issueType: ReconciliationIssueType.orphanJournalEntry,
              description: 'قيد محاسبي نشط لمستند صرف غير موجود أو غير مرحّل',
              glValue: 0.0,
              companyId: targetCompanyId,
            ),
          );
        }
      } else if (je.sourceType == 'stock_return' && je.sourceId != null) {
        final exists = await _inventorySubledgerQuery.hasPostedStockReturn(
          companyId: targetCompanyId,
          uuid: je.sourceId!,
        );
        if (!exists) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: je.sourceId!,
              documentNumber: je.voucherNumber,
              documentType: 'stock_return',
              issueType: ReconciliationIssueType.orphanJournalEntry,
              description: 'قيد محاسبي نشط لمستند مرتجع غير موجود أو غير مرحّل',
              glValue: 0.0,
              companyId: targetCompanyId,
            ),
          );
        }
      }
    }

    return ReconciliationReport(
      companyId: targetCompanyId,
      scannedDocumentCount: scannedCount,
      discrepancies: discrepancies,
      timestamp: DateTime.now().toUtc(),
      subledgerValuation: subledgerValuation,
      glInventoryBalance: glInventoryBalance,
    );
  }

  Future<ReconciliationReport> verifyReconciliationOrThrow({String? companyId}) async {
    final report = await runReconciliation(companyId: companyId);
    if (report.hasDiscrepancies) {
      throw ReconciliationException(report);
    }
    return report;
  }
}
