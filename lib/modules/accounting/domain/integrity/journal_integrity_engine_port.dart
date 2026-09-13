import '../foundation/accounting_journal_contracts.dart';
import 'journal_integrity_report.dart';

/// Central Journal Integrity Engine Port.
///
/// Evaluates all 14 mandatory structural invariants of an [AccountingJournal] prior to posting.
abstract class JournalIntegrityEnginePort {
  /// Must be fail-closed: if any invariant fails, returns [JournalIntegrityReport] with errors.
  Future<JournalIntegrityReport> evaluateIntegrity(AccountingJournal journal);
}
