import '../entities/account.dart';
import '../entities/account_type.dart';

/// Stable system keys for default Chart of Accounts nodes.
///
/// Names are English seed values; UI labels use localization by [systemKey]
/// where needed. Do not hardcode this list in widgets.
///
/// Module → system key map (sale journals resolve revenue/discounts/cash/customer):
/// - Sales / Treasury: `cash_boxes`, `cash`, `bank`, `petty_cash`, `sales_revenue`,
///   `sales_returns`, `sales_discounts`, `vat_output`, `cost_of_goods_sold`,
///   `customer_advances`
/// - FX revaluation: `fx_gain`, `fx_loss`
/// - Customers: `customers` (group `1221`)
/// - Inventory: `inventory`, `inventory_in_transit`, `inventory_adjustments`,
///   `cost_of_goods_sold`
/// - Purchases / Suppliers (future): `suppliers`, `accounts_payable`,
///   `vat_input`, `purchase_discounts`
class DefaultChartOfAccounts {
  const DefaultChartOfAccounts._();

  /// Seed drafts with temporary parent keys resolved during seeding.
  ///
  /// [parentKey] refers to another entry's [systemKey], not a UUID.
  /// Existing codes used by modules (`1211`, `1221`, `1230`, `4100`, …) stay
  /// stable; new trading/VAT accounts are additive only.
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
      systemKey: 'cash_boxes',
      parentKey: 'current_assets',
      accountCode: '1210',
      name: 'Cash Boxes',
      accountType: AccountType.asset,
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'cash',
      parentKey: 'cash_boxes',
      accountCode: '1211',
      name: 'Main Cash Box',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'bank',
      parentKey: 'cash_boxes',
      accountCode: '1212',
      name: 'Bank',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'petty_cash',
      parentKey: 'cash_boxes',
      accountCode: '1213',
      name: 'Petty Cash',
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
    DefaultAccountSeed(
      systemKey: 'inventory_in_transit',
      parentKey: 'current_assets',
      accountCode: '1235',
      name: 'Inventory in Transit',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'vat_input',
      parentKey: 'current_assets',
      accountCode: '1250',
      name: 'VAT Input',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'prepaid_expenses',
      parentKey: 'current_assets',
      accountCode: '1260',
      name: 'Prepaid Expenses',
      accountType: AccountType.asset,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'other_current_assets',
      parentKey: 'current_assets',
      accountCode: '1290',
      name: 'Other Current Assets',
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
      systemKey: 'suppliers',
      parentKey: 'current_liabilities',
      accountCode: '2111',
      name: 'Suppliers',
      accountType: AccountType.liability,
      // Group parent for per-supplier payable accounts.
      isGroup: true,
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
      systemKey: 'vat_output',
      parentKey: 'current_liabilities',
      accountCode: '2130',
      name: 'VAT Output Payable',
      accountType: AccountType.liability,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'accrued_expenses',
      parentKey: 'current_liabilities',
      accountCode: '2140',
      name: 'Accrued Expenses',
      accountType: AccountType.liability,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'customer_advances',
      parentKey: 'current_liabilities',
      accountCode: '2150',
      name: 'Customer Advances',
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
    DefaultAccountSeed(
      systemKey: 'long_term_loans',
      parentKey: 'long_term_liabilities',
      accountCode: '2210',
      name: 'Long Term Loans',
      accountType: AccountType.liability,
      isGroup: false,
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
      // Group for other income posting children (e.g. purchase discounts).
      isGroup: true,
    ),
    DefaultAccountSeed(
      systemKey: 'purchase_discounts',
      parentKey: 'other_revenue',
      accountCode: '4210',
      name: 'Purchase Discounts',
      accountType: AccountType.revenue,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'fx_gain',
      parentKey: 'other_revenue',
      accountCode: '4220',
      name: 'Foreign Exchange Gains',
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
      systemKey: 'inventory_adjustments',
      parentKey: 'expenses',
      accountCode: '5150',
      name: 'Inventory Adjustments',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    // Treated as expense (debit) until contra-revenue AccountType exists.
    DefaultAccountSeed(
      systemKey: 'sales_returns',
      parentKey: 'expenses',
      accountCode: '5160',
      name: 'Sales Returns',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'sales_discounts',
      parentKey: 'expenses',
      accountCode: '5170',
      name: 'Sales Discounts',
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
      systemKey: 'bank_charges',
      parentKey: 'expenses',
      accountCode: '5500',
      name: 'Bank Charges',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'depreciation',
      parentKey: 'expenses',
      accountCode: '5600',
      name: 'Depreciation',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'advertising',
      parentKey: 'expenses',
      accountCode: '5700',
      name: 'Advertising',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'shipping_delivery',
      parentKey: 'expenses',
      accountCode: '5800',
      name: 'Shipping and Delivery',
      accountType: AccountType.expense,
      isGroup: false,
    ),
    DefaultAccountSeed(
      systemKey: 'maintenance',
      parentKey: 'expenses',
      accountCode: '5850',
      name: 'Maintenance',
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
    DefaultAccountSeed(
      systemKey: 'fx_loss',
      parentKey: 'expenses',
      accountCode: '5910',
      name: 'Foreign Exchange Losses',
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
