import '../../journals/domain/repositories/journal_repository.dart';
import '../posting/accounting_posting_authority_port.dart';
import 'accounting_lifecycle_controller_port.dart';

class AccountingLifecycleException implements Exception {
  AccountingLifecycleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Concrete implementation of [AccountingLifecycleControllerPort].
class AccountingLifecycleController implements AccountingLifecycleControllerPort {
  AccountingLifecycleController({
    required this._postingAuthority,
    required this._journalRepository,
    Map<String, bool>? periodStateMap,
  })  : _periodStateMap = periodStateMap ?? {};

  final AccountingPostingAuthorityPort _postingAuthority;
  final JournalRepository _journalRepository;
  final Map<String, bool> _periodStateMap;

  @override
  void assertJournalMutable({required bool isPosted, required String action}) {
    if (isPosted) {
      throw AccountingLifecycleException(
        'Immutability Violation: Cannot $action posted journal entry. Posted journals are immutable.',
      );
    }
  }

  @override
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  }) async {
    final existing = await _journalRepository.getByUuid(journalUuid);
    if (existing == null) {
      throw AccountingLifecycleException('Target journal entry $journalUuid not found for reversal.');
    }

    if (!existing.isPosted) {
      throw AccountingLifecycleException('Cannot reverse unposted journal entry $journalUuid.');
    }

    // Check if entry was already reversed (reversal of reversal policy)
    final existingReverse = await _journalRepository.findBySource(
      sourceType: 'journal_reverse',
      sourceId: existing.uuid,
    );
    if (existingReverse != null) {
      throw AccountingLifecycleException('Journal entry $journalUuid has already been reversed.');
    }

    return _postingAuthority.reverseJournal(
      journalUuid: journalUuid,
      reason: reason,
    );
  }

  @override
  Future<void> setPeriodStatus({
    required String companyId,
    required String periodId,
    required bool isOpen,
  }) async {
    _periodStateMap['$companyId:$periodId'] = isOpen;
  }

  @override
  Future<bool> isPeriodOpen({
    required String companyId,
    required String periodId,
  }) async {
    return _periodStateMap['$companyId:$periodId'] ?? true;
  }
}
