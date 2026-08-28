import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'accounting_entry_builder.dart';

class SyncAuditResult {
  const SyncAuditResult({
    required this.isSynced,
    required this.documentId,
    this.documentAmount,
    this.journalAmount,
    this.message,
  });

  final bool isSynced;
  final String documentId;
  final double? documentAmount;
  final double? journalAmount;
  final String? message;

  static SyncAuditResult synced(String documentId) => SyncAuditResult(
        isSynced: true,
        documentId: documentId,
        message: 'المستند والقيد المحاسبي متطابقان تماماً',
      );
}

class DocumentEntrySync {
  DocumentEntrySync({
    required JournalRepository journalRepository,
    required AccountingEntryBuilder entryBuilder,
  })  : _journalRepository = journalRepository,
        _entryBuilder = entryBuilder;

  final JournalRepository _journalRepository;
  final AccountingEntryBuilder _entryBuilder;

  Future<SyncAuditResult> auditDocumentSync({
    required InventoryDocumentRef document,
    required double expectedAmount,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;

    final entry = await _journalRepository.findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );

    if (entry == null) {
      if (expectedAmount <= 0) {
        return SyncAuditResult.synced(sourceId);
      }
      return SyncAuditResult(
        isSynced: false,
        documentId: sourceId,
        documentAmount: expectedAmount,
        journalAmount: 0.0,
        message: 'المستند مرحّل ولكن القيد المحاسبي المرتبط مفقود!',
      );
    }

    final journalTotalDebit = entry.lines.fold<double>(0.0, (sum, line) => sum + line.debit);
    final diff = (expectedAmount - journalTotalDebit).abs();

    if (diff > 0.001) {
      return SyncAuditResult(
        isSynced: false,
        documentId: sourceId,
        documentAmount: expectedAmount,
        journalAmount: journalTotalDebit,
        message:
            'عدم تطابق المبالغ: مبلغ المستند ($expectedAmount) يختلف عن اجمالي القيد ($journalTotalDebit)',
      );
    }

    return SyncAuditResult.synced(sourceId);
  }
}
