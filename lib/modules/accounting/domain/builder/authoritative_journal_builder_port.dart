import '../foundation/accounting_effect.dart';
import '../foundation/accounting_journal_contracts.dart';

abstract class AuthoritativeJournalBuilderPort {
  /// Builds an authoritative [AccountingJournal] exclusively from a validated [AccountingEffect].
  ///
  /// First validates [effect] using the validation engine.
  /// Throws [AccountingJournalBuilderException] if validation or journal integrity fails.
  Future<AccountingJournal> buildJournal(AccountingEffect effect);
}
