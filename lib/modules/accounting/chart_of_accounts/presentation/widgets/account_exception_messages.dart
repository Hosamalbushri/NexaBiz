import 'package:stock_count/app/localization/app_localizations.dart';
import '../../domain/models/account_exception.dart';

/// Maps [AccountException] codes to localized user-facing messages.
String accountExceptionMessage(AppLocalizations l10n, AccountException e) {
  return switch (e.code) {
    AccountException.duplicateAccountCode => l10n.accountingErrorDuplicateCode,
    AccountException.invalidAccountCode => l10n.accountingErrorCodeRequired,
    AccountException.invalidName => l10n.accountingErrorNameRequired,
    AccountException.typeMismatch => l10n.accountingErrorTypeMismatch,
    AccountException.invalidParent => l10n.accountingErrorInvalidParent,
    AccountException.parentInactive => l10n.accountingErrorInvalidParent,
    AccountException.parentDeleted => l10n.accountingErrorInvalidParent,
    AccountException.circularParent => l10n.accountingErrorCircularParent,
    AccountException.groupRequiredForChildren =>
      l10n.accountingErrorParentMustBeGroup,
    AccountException.systemAccountProtected =>
      l10n.accountingErrorSystemProtected,
    AccountException.hasChildren => l10n.accountingErrorHasChildren,
    AccountException.accountInUse => l10n.accountingErrorInUse,
    AccountException.notFound => l10n.accountingAccountNotFound,
    _ => l10n.somethingWentWrong,
  };
}
