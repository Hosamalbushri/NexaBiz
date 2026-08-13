import '../../../../app/localization/app_localizations.dart';
import '../../domain/services/sale_treasury_account_port.dart';

/// Localized display labels for treasury/cash accounts in Sales UI.
class SaleAccountLabels {
  const SaleAccountLabels._();

  static String displayName(AppLocalizations l10n, SaleAccountRef account) {
    final key = account.systemKey?.trim();
    if (key == null || key.isEmpty) {
      return account.name;
    }
    return switch (key) {
      'cash' => l10n.accountingAccountCash,
      'bank' => l10n.accountingAccountBank,
      _ => account.name,
    };
  }
}
