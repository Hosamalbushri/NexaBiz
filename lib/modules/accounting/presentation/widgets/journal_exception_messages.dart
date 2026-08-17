import '../../../../app/localization/app_localizations.dart';
import '../../domain/models/journal_exception.dart';

/// Maps [JournalException] codes to localized user-facing messages.
String journalExceptionMessage(AppLocalizations l10n, JournalException e) {
  return switch (e.code) {
    JournalException.unbalanced => l10n.accountingJournalErrorUnbalanced,
    JournalException.periodClosed => l10n.accountingJournalErrorPeriodClosed,
    JournalException.outsideFiscalYear =>
      l10n.accountingJournalErrorOutsideFiscalYear,
    JournalException.emptyLines => l10n.accountingJournalErrorLines,
    JournalException.invalidAmount => l10n.accountingJournalErrorLines,
    JournalException.notFound => l10n.accountingJournalNotFound,
    _ => l10n.somethingWentWrong,
  };
}
