import '../journal/journal_entry.dart';
import 'financial_posting_command.dart';

/// Application port for submitting commercial financial posting commands.
abstract class FinancialPostingPort {
  /// Posts a financial command to the authoritative PostingEngine and persists the result.
  Future<JournalEntry> postCommand(FinancialPostingCommand command);
}
