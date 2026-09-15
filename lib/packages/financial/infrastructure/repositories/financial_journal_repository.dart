import '../../domain/journal/journal_entry.dart';

/// Repository port interface for Journal Entries & Lines.
abstract class FinancialJournalRepository {
  Future<void> saveEntry(JournalEntry entry);
  Future<JournalEntry?> findById(String companyId, String id);
  Future<JournalEntry?> findByNumber(String companyId, String entryNumber);
  Future<JournalEntry?> findBySourceDocument({
    required String companyId,
    required String sourceModule,
    required String sourceDocumentId,
  });
  Future<List<JournalEntry>> getCompanyEntries(String companyId);
}
