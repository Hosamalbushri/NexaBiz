import '../../../../app/localization/app_localizations.dart';
import '../entities/account.dart';

/// Resolves user-facing account labels (system seeds stay English in DB).
class AccountLabels {
  const AccountLabels._();

  static const String systemPrefix = 'system:';

  static String? systemKeyOf(Account account) {
    final description = account.description;
    if (description == null || !description.startsWith(systemPrefix)) {
      return null;
    }
    final key = description.substring(systemPrefix.length).trim();
    return key.isEmpty ? null : key;
  }

  static String displayName(AppLocalizations l10n, Account account) {
    final key = systemKeyOf(account);
    if (key == null) {
      return account.name;
    }
    return systemName(l10n, key) ?? account.name;
  }

  /// Whether [query] matches code, stored name, or localized system name.
  static bool matchesQuery(
    AppLocalizations l10n,
    Account account,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (account.accountCode.toLowerCase().contains(normalized)) {
      return true;
    }
    if (account.name.toLowerCase().contains(normalized)) {
      return true;
    }
    final localized = displayName(l10n, account).toLowerCase();
    return localized.contains(normalized);
  }

  static String? systemName(AppLocalizations l10n, String systemKey) {
    return switch (systemKey) {
      'assets' => l10n.accountingAccountAssets,
      'current_assets' => l10n.accountingAccountCurrentAssets,
      'cash' => l10n.accountingAccountCash,
      'bank' => l10n.accountingAccountBank,
      'accounts_receivable' => l10n.accountingAccountAccountsReceivable,
      'customers' => l10n.accountingAccountCustomers,
      'inventory' => l10n.accountingAccountInventory,
      'fixed_assets' => l10n.accountingAccountFixedAssets,
      'buildings' => l10n.accountingAccountBuildings,
      'vehicles' => l10n.accountingAccountVehicles,
      'equipment' => l10n.accountingAccountEquipment,
      'liabilities' => l10n.accountingAccountLiabilities,
      'current_liabilities' => l10n.accountingAccountCurrentLiabilities,
      'accounts_payable' => l10n.accountingAccountAccountsPayable,
      'short_term_loans' => l10n.accountingAccountShortTermLoans,
      'long_term_liabilities' => l10n.accountingAccountLongTermLiabilities,
      'equity' => l10n.accountingAccountEquity,
      'capital' => l10n.accountingAccountCapital,
      'retained_earnings' => l10n.accountingAccountRetainedEarnings,
      'revenue' => l10n.accountingAccountRevenue,
      'sales_revenue' => l10n.accountingAccountSalesRevenue,
      'other_revenue' => l10n.accountingAccountOtherRevenue,
      'expenses' => l10n.accountingAccountExpenses,
      'cost_of_goods_sold' => l10n.accountingAccountCogs,
      'salaries' => l10n.accountingAccountSalaries,
      'rent' => l10n.accountingAccountRent,
      'utilities' => l10n.accountingAccountUtilities,
      'other_expenses' => l10n.accountingAccountOtherExpenses,
      _ => null,
    };
  }
}
