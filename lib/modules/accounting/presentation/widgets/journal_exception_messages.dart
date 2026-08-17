import '../../../../app/localization/app_localizations.dart';
import '../../../../core/permissions/permission_error_messages.dart';
import '../../domain/models/journal_exception.dart';

/// Maps domain / unexpected journal-related errors to localized text.
String journalExceptionMessage(AppLocalizations l10n, Object error) {
  final denied = permissionDeniedMessage(l10n, error);
  if (denied != null) {
    return denied;
  }
  if (error is! JournalException) {
    return l10n.somethingWentWrong;
  }
  final e = error;
  return switch (e.code) {
    JournalException.unbalanced => l10n.accountingJournalErrorUnbalanced,
    JournalException.periodClosed => l10n.accountingJournalErrorPeriodClosed,
    JournalException.outsideFiscalYear =>
      l10n.accountingJournalErrorOutsideFiscalYear,
    JournalException.postedImmutable =>
      l10n.accountingJournalErrorPostedImmutable,
    JournalException.alreadyReversed =>
      l10n.accountingJournalErrorAlreadyReversed,
    JournalException.debitAccountMissing =>
      l10n.accountingJournalErrorDebitAccountMissing,
    JournalException.emptyLines => l10n.accountingJournalErrorLines,
    JournalException.invalidAmount => l10n.accountingJournalErrorLines,
    JournalException.notFound => l10n.accountingJournalNotFound,
    _ => l10n.somethingWentWrong,
  };
}
