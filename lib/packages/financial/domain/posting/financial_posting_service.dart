import 'package:stock_count/core/utils/id_generator.dart';
import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../journal/journal_entry.dart';
import '../journal/journal_line.dart';
import '../journal/journal_status.dart';
import '../../infrastructure/persistence/drift_financial_repositories.dart';
import 'financial_posting_command.dart';
import 'financial_posting_port.dart';
import 'posting_engine.dart';

/// Service implementing canonical [FinancialPostingPort].
class FinancialPostingService implements FinancialPostingPort {
  final DriftFinancialAccountRepository accountRepository;
  final DriftFinancialJournalRepository journalRepository;

  FinancialPostingService({
    required this.accountRepository,
    required this.journalRepository,
  });

  @override
  Future<JournalEntry> postCommand(FinancialPostingCommand command) async {
    // 1. Check idempotency: if entry exists for (companyId, sourceModule, sourceDocumentId), return existing entry.
    final existing = await journalRepository.findBySourceDocument(
      companyId: command.companyId,
      sourceModule: command.sourceModule,
      sourceDocumentId: command.sourceDocumentId,
    );
    if (existing != null) {
      return existing;
    }

    // 2. Resolve accounts for all lines in command
    final accountIds = command.lines.map((l) => l.accountId).toSet();
    final accountsById = <String, FinancialAccount>{};
    for (final id in accountIds) {
      final acc = await accountRepository.findById(command.companyId, id);
      if (acc == null) {
        throw FinancialValidationException(
          'Account $id not found for company ${command.companyId}',
          'ACCOUNT_NOT_FOUND',
        );
      }
      accountsById[id] = acc;
    }

    // 3. Construct draft JournalEntry and JournalLines
    final entryId = generateUuidV7();
    final lines = command.lines.map((l) {
      return JournalLine.create(
        id: generateUuidV7(),
        companyId: command.companyId,
        journalEntryId: entryId,
        lineNumber: l.lineNumber,
        accountId: l.accountId,
        side: l.side,
        transactionAmount: l.transactionAmount,
        exchangeRate: l.exchangeRate,
        baseCurrencyCode: command.baseCurrencyCode,
        description: l.description,
      );
    }).toList();

    final draftEntry = JournalEntry(
      id: entryId,
      companyId: command.companyId,
      entryNumber: command.entryNumber,
      baseCurrencyCode: command.baseCurrencyCode,
      postingDate: command.postingDate,
      sourceModule: command.sourceModule,
      sourceDocumentId: command.sourceDocumentId,
      description: command.description,
      status: JournalStatus.draft,
      lines: lines,
    );

    // 4. Validate & Prepare through PostingEngine
    final now = DateTime.now();
    final preparation = await PostingEngine.prepareAndValidateForPosting(
      entry: draftEntry,
      accountsById: accountsById,
      postingTimestamp: now,
    );

    // 5. Persist prepared entry atomically
    await journalRepository.saveEntry(preparation.preparedEntry);

    return preparation.preparedEntry;
  }
}
