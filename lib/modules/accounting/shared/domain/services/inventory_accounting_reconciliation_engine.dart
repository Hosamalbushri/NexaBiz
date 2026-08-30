import 'package:drift/drift.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';

enum ReconciliationIssueType {
  missingJournalEntry,
  orphanJournalEntry,
  valueMismatch,
  tenantMismatch,
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
  });

  final String companyId;
  final int scannedDocumentCount;
  final List<ReconciliationDiscrepancy> discrepancies;
  final DateTime timestamp;

  bool get hasDiscrepancies => discrepancies.isNotEmpty;
}

class InventoryAccountingReconciliationEngine {
  InventoryAccountingReconciliationEngine({
    required InventoryDatabase inventoryDb,
    required AccountingDatabase accountingDb,
    String Function()? readCompanyId,
  })  : _inventoryDb = inventoryDb,
        _accountingDb = accountingDb,
        _readCompanyId = readCompanyId;

  final InventoryDatabase _inventoryDb;
  final AccountingDatabase _accountingDb;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Future<ReconciliationReport> runReconciliation({String? companyId}) async {
    final targetCompanyId = companyId ?? _currentCompanyId;
    final discrepancies = <ReconciliationDiscrepancy>[];
    int scannedCount = 0;

    // 1. Audit Stock Receipts
    final receipts = await (_inventoryDb.select(_inventoryDb.stockReceipts)
          ..where((tbl) =>
              tbl.companyId.equals(targetCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .get();

    for (final r in receipts) {
      scannedCount++;
      final lines = await (_inventoryDb.select(_inventoryDb.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(r.uuid)))
          .get();

      double subledgerCost = 0.0;
      for (final l in lines) {
        subledgerCost += l.totalCost;
      }

      final je = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals('stock_receipt') &
                tbl.sourceId.equals(r.uuid) &
                tbl.deletedAt.isNull() &
                tbl.isPosted.equals(true)))
          .getSingleOrNull();

      if (je == null) {
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

        final jLines = await (_accountingDb.select(_accountingDb.journalLines)
              ..where((tbl) => tbl.entryUuid.equals(je.uuid)))
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

    // 2. Audit Stock Issues
    final issues = await (_inventoryDb.select(_inventoryDb.stockIssues)
          ..where((tbl) =>
              tbl.companyId.equals(targetCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.status.equals('posted')))
        .get();

    for (final i in issues) {
      scannedCount++;
      final lines = await (_inventoryDb.select(_inventoryDb.stockMovementLines)
            ..where((tbl) => tbl.movementUuid.equals(i.uuid)))
          .get();

      double subledgerCost = 0.0;
      for (final l in lines) {
        subledgerCost += (l.postedCost ?? l.unitCost) * l.quantity;
      }

      final je = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals('stock_issue') &
                tbl.sourceId.equals(i.uuid) &
                tbl.deletedAt.isNull() &
                tbl.isPosted.equals(true)))
          .getSingleOrNull();

      if (je == null) {
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
        final jLines = await (_accountingDb.select(_accountingDb.journalLines)
              ..where((tbl) => tbl.entryUuid.equals(je.uuid)))
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

    // 3. Audit Orphan Journal Entries (Active GL entry for non-existent or draft inventory doc)
    final invJournals = await (_accountingDb.select(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.companyId.equals(targetCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.isPosted.equals(true) &
              tbl.sourceType.isIn(['stock_receipt', 'stock_issue'])))
        .get();

    for (final je in invJournals) {
      if (je.sourceType == 'stock_receipt' && je.sourceId != null) {
        final rec = await (_inventoryDb.select(_inventoryDb.stockReceipts)
              ..where((tbl) =>
                  tbl.uuid.equals(je.sourceId!) &
                  tbl.deletedAt.isNull() &
                  tbl.status.equals('posted')))
            .getSingleOrNull();
        if (rec == null) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: je.sourceId!,
              documentNumber: je.voucherNumber ?? je.uuid,
              documentType: 'stock_receipt',
              issueType: ReconciliationIssueType.orphanJournalEntry,
              description: 'قيد محاسبي نشط لمستند توريد غير موجود أو غير مرحّل',
              glValue: 0.0,
              companyId: targetCompanyId,
            ),
          );
        }
      } else if (je.sourceType == 'stock_issue' && je.sourceId != null) {
        final iss = await (_inventoryDb.select(_inventoryDb.stockIssues)
              ..where((tbl) =>
                  tbl.uuid.equals(je.sourceId!) &
                  tbl.deletedAt.isNull() &
                  tbl.status.equals('posted')))
            .getSingleOrNull();
        if (iss == null) {
          discrepancies.add(
            ReconciliationDiscrepancy(
              documentId: je.sourceId!,
              documentNumber: je.voucherNumber ?? je.uuid,
              documentType: 'stock_issue',
              issueType: ReconciliationIssueType.orphanJournalEntry,
              description: 'قيد محاسبي نشط لمستند صرف غير موجود أو غير مرحّل',
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
    );
  }
}
