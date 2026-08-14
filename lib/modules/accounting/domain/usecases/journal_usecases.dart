import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';
import '../services/journal_posting_service.dart';

class PostJournalEntry {
  const PostJournalEntry(this._posting);

  final JournalPostingService _posting;

  Future<JournalEntry> call(JournalEntryDraft draft) => _posting.post(draft);
}

class GetJournalEntryByUuid {
  const GetJournalEntryByUuid(this._repository);

  final JournalRepository _repository;

  Future<JournalEntry?> call(String uuid) => _repository.getByUuid(uuid);
}

class ListJournalEntryHeaders {
  const ListJournalEntryHeaders(this._repository);

  final JournalRepository _repository;

  Future<List<JournalEntryHeader>> call({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? query,
    int? limit,
    int? afterId,
  }) {
    return _repository.listHeaders(
      fromDate: fromDate,
      toDate: toDate,
      isPosted: isPosted,
      query: query,
      limit: limit,
      afterId: afterId,
    );
  }
}

class SoftDeleteJournalEntry {
  const SoftDeleteJournalEntry(this._posting);

  final JournalPostingService _posting;

  Future<void> call(String uuid) => _posting.softDeleteByUuid(uuid);
}
