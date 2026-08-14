import '../../../../app/localization/app_localizations.dart';
import '../entities/account.dart';
import '../entities/account_type.dart';
import '../entities/normal_balance.dart';

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

  static String typeLabel(AppLocalizations l10n, AccountType type) {
    return switch (type) {
      AccountType.asset => l10n.accountingTypeAsset,
      AccountType.liability => l10n.accountingTypeLiability,
      AccountType.equity => l10n.accountingTypeEquity,
      AccountType.revenue => l10n.accountingTypeRevenue,
      AccountType.expense => l10n.accountingTypeExpense,
    };
  }

  static String normalBalanceLabel(
    AppLocalizations l10n,
    NormalBalance balance,
  ) {
    return switch (balance) {
      NormalBalance.debit => l10n.accountingNormalDebit,
      NormalBalance.credit => l10n.accountingNormalCredit,
    };
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
      'petty_cash' => l10n.accountingAccountPettyCash,
      'accounts_receivable' => l10n.accountingAccountAccountsReceivable,
      'customers' => l10n.accountingAccountCustomers,
      'inventory' => l10n.accountingAccountInventory,
      'inventory_in_transit' => l10n.accountingAccountInventoryInTransit,
      'vat_input' => l10n.accountingAccountVatInput,
      'prepaid_expenses' => l10n.accountingAccountPrepaidExpenses,
      'other_current_assets' => l10n.accountingAccountOtherCurrentAssets,
      'fixed_assets' => l10n.accountingAccountFixedAssets,
      'buildings' => l10n.accountingAccountBuildings,
      'vehicles' => l10n.accountingAccountVehicles,
      'equipment' => l10n.accountingAccountEquipment,
      'liabilities' => l10n.accountingAccountLiabilities,
      'current_liabilities' => l10n.accountingAccountCurrentLiabilities,
      'accounts_payable' => l10n.accountingAccountAccountsPayable,
      'suppliers' => l10n.accountingAccountSuppliers,
      'short_term_loans' => l10n.accountingAccountShortTermLoans,
      'vat_output' => l10n.accountingAccountVatOutput,
      'accrued_expenses' => l10n.accountingAccountAccruedExpenses,
      'customer_advances' => l10n.accountingAccountCustomerAdvances,
      'long_term_liabilities' => l10n.accountingAccountLongTermLiabilities,
      'long_term_loans' => l10n.accountingAccountLongTermLoans,
      'equity' => l10n.accountingAccountEquity,
      'capital' => l10n.accountingAccountCapital,
      'retained_earnings' => l10n.accountingAccountRetainedEarnings,
      'revenue' => l10n.accountingAccountRevenue,
      'sales_revenue' => l10n.accountingAccountSalesRevenue,
      'other_revenue' => l10n.accountingAccountOtherRevenue,
      'purchase_discounts' => l10n.accountingAccountPurchaseDiscounts,
      'expenses' => l10n.accountingAccountExpenses,
      'cost_of_goods_sold' => l10n.accountingAccountCogs,
      'inventory_adjustments' => l10n.accountingAccountInventoryAdjustments,
      'sales_returns' => l10n.accountingAccountSalesReturns,
      'sales_discounts' => l10n.accountingAccountSalesDiscounts,
      'salaries' => l10n.accountingAccountSalaries,
      'rent' => l10n.accountingAccountRent,
      'utilities' => l10n.accountingAccountUtilities,
      'bank_charges' => l10n.accountingAccountBankCharges,
      'depreciation' => l10n.accountingAccountDepreciation,
      'advertising' => l10n.accountingAccountAdvertising,
      'shipping_delivery' => l10n.accountingAccountShippingDelivery,
      'maintenance' => l10n.accountingAccountMaintenance,
      'other_expenses' => l10n.accountingAccountOtherExpenses,
      _ => null,
    };
  }
}
