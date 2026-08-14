import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';
import 'fiscal_period_policy.dart';

/// Application entry point for posting journals (UI, Sales, imports, sync).
///
/// Centralizes fiscal-period checks before persistence so callers cannot
/// bypass closed-period rules by talking to the repository directly from
/// product features — prefer this service (or its use cases) instead.
class JournalPostingService {
  const JournalPostingService({
    required JournalRepository journals,
    required FiscalPeriodPolicy Function() fiscalPolicyReader,
  }) : _journals = journals,
       _fiscalPolicyReader = fiscalPolicyReader;

  final JournalRepository _journals;
  final FiscalPeriodPolicy Function() _fiscalPolicyReader;

  Future<JournalEntry> post(JournalEntryDraft draft) async {
    _fiscalPolicyReader().assertEntryAllowed(draft.entryDate);
    return _journals.post(draft);
  }

  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final existing = await _journals.findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (existing != null) {
      _fiscalPolicyReader().assertEntryAllowed(existing.entryDate);
    }
    await _journals.softDeleteBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  Future<void> softDeleteByUuid(String uuid) async {
    final existing = await _journals.getByUuid(uuid);
    if (existing != null) {
      _fiscalPolicyReader().assertEntryAllowed(existing.entryDate);
    }
    await _journals.softDeleteByUuid(uuid);
  }
}
