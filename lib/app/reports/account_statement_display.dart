import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/reports/domain/services/account_statement_report_data_port.dart';
import '../localization/app_localizations.dart';

/// Resolves localized COA names for account-statement UI (App layer).
String resolveAccountStatementDisplayName(
  AppLocalizations l10n,
  AccountStatementAccountRef account,
) {
  final key = account.systemKey;
  if (key == null) {
    return account.name;
  }
  return AccountLabels.systemName(l10n, key) ?? account.name;
}
