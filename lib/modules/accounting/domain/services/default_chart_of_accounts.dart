import '../entities/account.dart';
import '../entities/account_type.dart';

/// Stable system keys for default Chart of Accounts nodes.
///
/// Names are English seed values; UI labels use localization by [systemKey]
/// where needed. Do not hardcode this list in widgets.
class DefaultChartOfAccounts {
  const DefaultChartOfAccounts._();

  /// Seed drafts with temporary parent keys resolved during seeding.
  ///
  /// [parentKey] refers to another entry's [systemKey], not a UUID.
  static List<DefaultAccountSeed> seeds() => const [
    // Assets — Fixed Assets first, then Current Assets
    DefaultAccountSeed(
      systemKey: 'assets',
      accountCode: '1000',
      name: 'Assets',
      accountType: AccountType.asset,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'fixed_assets',
      parentKey: 'assets',
      accountCode: '1100',
      name: 'Fixed Assets',
      accountType: AccountType.asset,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'buildings',
      parentKey: 'fixed_assets',
      accountCode: '1110',
      name: 'Buildings',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'vehicles',
      parentKey: 'fixed_assets',
      accountCode: '1120',
      name: 'Vehicles',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'equipment',
      parentKey: 'fixed_assets',
      accountCode: '1130',
      name: 'Equipment',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'current_assets',
      parentKey: 'assets',
      accountCode: '1200',
      name: 'Current Assets',
      accountType: AccountType.asset,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'cash',
      parentKey: 'current_assets',
      accountCode: '1211',
      name: 'Cash',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'bank',
      parentKey: 'current_assets',
      accountCode: '1212',
      name: 'Bank',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'accounts_receivable',
      parentKey: 'current_assets',
      accountCode: '1220',
      name: 'Accounts Receivable',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'customers',
      parentKey: 'current_assets',
      accountCode: '1221',
      name: 'Customers',
      accountType: AccountType.asset,
      // Group parent for per-customer receivable accounts.
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'inventory',
      parentKey: 'current_assets',
      accountCode: '1230',
      name: 'Inventory',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    // Liabilities
    DefaultAccountSeed(
      systemKey: 'liabilities',
      accountCode: '2000',
      name: 'Liabilities',
      accountType: AccountType.liability,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'current_liabilities',
      parentKey: 'liabilities',
      accountCode: '2100',
      name: 'Current Liabilities',
      accountType: AccountType.liability,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'accounts_payable',
      parentKey: 'current_liabilities',
      accountCode: '2110',
      name: 'Accounts Payable',
      accountType: AccountType.liability,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'short_term_loans',
      parentKey: 'current_liabilities',
      accountCode: '2120',
      name: 'Short Term Loans',
      accountType: AccountType.liability,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'long_term_liabilities',
      parentKey: 'liabilities',
      accountCode: '2200',
      name: 'Long Term Liabilities',
      accountType: AccountType.liability,
      isGroup: true,
    ),
    // Equity
    DefaultAccountSeed(
      systemKey: 'equity',
      accountCode: '3000',
      name: 'Equity',
      accountType: AccountType.equity,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'capital',
      parentKey: 'equity',
      accountCode: '3100',
      name: 'Capital',
      accountType: AccountType.equity,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'retained_earnings',
      parentKey: 'equity',
      accountCode: '3200',
      name: 'Retained Earnings',
      accountType: AccountType.equity,
      isGroup: false,
    ),
    // Revenue
    DefaultAccountSeed(
      systemKey: 'revenue',
      accountCode: '4000',
      name: 'Revenue',
      accountType: AccountType.revenue,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'sales_revenue',
      parentKey: 'revenue',
      accountCode: '4100',
      name: 'Sales Revenue',
      accountType: AccountType.revenue,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'other_revenue',
      parentKey: 'revenue',
      accountCode: '4200',
      name: 'Other Revenue',
      accountType: AccountType.revenue,
      isGroup: false,
    ),
    // Expenses
    DefaultAccountSeed(
      systemKey: 'expenses',
      accountCode: '5000',
      name: 'Expenses',
      accountType: AccountType.expense,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'cost_of_goods_sold',
      parentKey: 'expenses',
      accountCode: '5100',
      name: 'Cost of Goods Sold',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'salaries',
      parentKey: 'expenses',
      accountCode: '5200',
      name: 'Salaries',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'rent',
      parentKey: 'expenses',
      accountCode: '5300',
      name: 'Rent',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'utilities',
      parentKey: 'expenses',
      accountCode: '5400',
      name: 'Utilities',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'other_expenses',
      parentKey: 'expenses',
      accountCode: '5900',
      name: 'Other Expenses',
      accountType: AccountType.expense,
      isGroup: false,
    ),
  ];
}

class DefaultAccountSeed {
  const DefaultAccountSeed({
    required this.systemKey,
    required this.accountCode,
    required this.name,
    required this.accountType,
    required this.isGroup,
    this.parentKey,
  });

  final String systemKey;
  final String? parentKey;
  final String accountCode;
  final String name;
  final AccountType accountType;
  final bool isGroup;

  AccountDraft toDraft({String? parentId}) {
    return AccountDraft(
      parentId: parentId,
      accountCode: accountCode,
      name: name,
      accountType: accountType,
      isGroup: isGroup,
      isActive: true,
      isSystemAccount: true,
      description: 'system:$systemKey',
    );
  }
}
