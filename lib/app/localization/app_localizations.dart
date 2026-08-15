import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NexaBiz'**
  String get appTitle;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @servicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a business module to get started.'**
  String get servicesSubtitle;

  /// No description provided for @moduleInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get moduleInventory;

  /// No description provided for @moduleInventoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Inventory services including stock count, and more over time.'**
  String get moduleInventoryDescription;

  /// No description provided for @moduleAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get moduleAccounting;

  /// No description provided for @moduleAccountingDescription.
  ///
  /// In en, this message translates to:
  /// **'Chart of Accounts and the foundation for future ledgers and reports.'**
  String get moduleAccountingDescription;

  /// No description provided for @moduleCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get moduleCustomers;

  /// No description provided for @moduleCustomersDescription.
  ///
  /// In en, this message translates to:
  /// **'Customer master data with optional Chart of Accounts links and external ERP ids.'**
  String get moduleCustomersDescription;

  /// No description provided for @moduleSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get moduleSales;

  /// No description provided for @moduleSalesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create and manage sales offline, with optional accounting and inventory hooks.'**
  String get moduleSalesDescription;

  /// No description provided for @moduleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReports;

  /// No description provided for @moduleReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate, preview, print, and share professional PDF reports.'**
  String get moduleReportsDescription;

  /// No description provided for @reportsSalesPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales by period'**
  String get reportsSalesPeriodTitle;

  /// No description provided for @reportsSalesPeriodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List sales in a date range with status filter, then preview as PDF.'**
  String get reportsSalesPeriodSubtitle;

  /// No description provided for @reportsAccountStatementTitle.
  ///
  /// In en, this message translates to:
  /// **'Account statement'**
  String get reportsAccountStatementTitle;

  /// No description provided for @reportsAccountStatementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print a cumulative Chart of Accounts statement in the account currency (classic layout).'**
  String get reportsAccountStatementSubtitle;

  /// No description provided for @reportsAccountStatementFilters.
  ///
  /// In en, this message translates to:
  /// **'Statement filters'**
  String get reportsAccountStatementFilters;

  /// No description provided for @reportsAccountStatementAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get reportsAccountStatementAccount;

  /// No description provided for @reportsAccountStatementAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get reportsAccountStatementAccountHint;

  /// No description provided for @reportsAccountStatementAccountSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by code or name'**
  String get reportsAccountStatementAccountSearch;

  /// No description provided for @reportsAccountStatementAccountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No posting accounts found.'**
  String get reportsAccountStatementAccountEmpty;

  /// No description provided for @reportsAccountStatementAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an account first.'**
  String get reportsAccountStatementAccountRequired;

  /// No description provided for @reportsAccountStatementAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get reportsAccountStatementAccountName;

  /// No description provided for @reportsAccountStatementAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get reportsAccountStatementAccountNumber;

  /// No description provided for @reportsAccountStatementCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get reportsAccountStatementCurrency;

  /// No description provided for @reportsAccountStatementCurrencyAll.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get reportsAccountStatementCurrencyAll;

  /// No description provided for @reportsAccountStatementType.
  ///
  /// In en, this message translates to:
  /// **'Statement type'**
  String get reportsAccountStatementType;

  /// No description provided for @reportsAccountStatementTypeCumulative.
  ///
  /// In en, this message translates to:
  /// **'Cumulative statement (account currency)'**
  String get reportsAccountStatementTypeCumulative;

  /// No description provided for @reportsAccountStatementTypeDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed statement'**
  String get reportsAccountStatementTypeDetailed;

  /// No description provided for @reportsAccountStatementTypeSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary statement'**
  String get reportsAccountStatementTypeSummary;

  /// No description provided for @reportsAccountStatementPostingStatus.
  ///
  /// In en, this message translates to:
  /// **'Posting status'**
  String get reportsAccountStatementPostingStatus;

  /// No description provided for @reportsAccountStatementPostingAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsAccountStatementPostingAll;

  /// No description provided for @reportsAccountStatementPostingPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get reportsAccountStatementPostingPosted;

  /// No description provided for @reportsAccountStatementPostingUnposted.
  ///
  /// In en, this message translates to:
  /// **'Unposted'**
  String get reportsAccountStatementPostingUnposted;

  /// No description provided for @reportsAccountStatementFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get reportsAccountStatementFromDate;

  /// No description provided for @reportsAccountStatementToDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get reportsAccountStatementToDate;

  /// No description provided for @reportsAccountStatementColSide.
  ///
  /// In en, this message translates to:
  /// **'D/C'**
  String get reportsAccountStatementColSide;

  /// No description provided for @reportsAccountStatementColVoucherType.
  ///
  /// In en, this message translates to:
  /// **'Voucher type'**
  String get reportsAccountStatementColVoucherType;

  /// No description provided for @reportsAccountStatementColVoucherNumber.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get reportsAccountStatementColVoucherNumber;

  /// No description provided for @reportsAccountStatementColDescription.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportsAccountStatementColDescription;

  /// No description provided for @reportsAccountStatementColDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get reportsAccountStatementColDebit;

  /// No description provided for @reportsAccountStatementColCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get reportsAccountStatementColCredit;

  /// No description provided for @reportsAccountStatementColBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get reportsAccountStatementColBalance;

  /// No description provided for @reportsAccountStatementColCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get reportsAccountStatementColCurrency;

  /// No description provided for @reportsAccountStatementColInCurrency.
  ///
  /// In en, this message translates to:
  /// **'In currency'**
  String get reportsAccountStatementColInCurrency;

  /// No description provided for @reportsAccountStatementTotalsDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get reportsAccountStatementTotalsDebit;

  /// No description provided for @reportsAccountStatementTotalsCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get reportsAccountStatementTotalsCredit;

  /// No description provided for @reportsAccountStatementFinalBalanceByCurrency.
  ///
  /// In en, this message translates to:
  /// **'Final balance by currency'**
  String get reportsAccountStatementFinalBalanceByCurrency;

  /// No description provided for @reportsAccountStatementDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This account statement is considered correct unless an objection is received within two weeks from its date.'**
  String get reportsAccountStatementDisclaimer;

  /// No description provided for @reportsAccountStatementAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get reportsAccountStatementAccountant;

  /// No description provided for @reportsAccountStatementReviewer.
  ///
  /// In en, this message translates to:
  /// **'Reviewer'**
  String get reportsAccountStatementReviewer;

  /// No description provided for @reportsAccountStatementFinanceManager.
  ///
  /// In en, this message translates to:
  /// **'Finance manager:'**
  String get reportsAccountStatementFinanceManager;

  /// No description provided for @reportsAccountStatementPrintedBy.
  ///
  /// In en, this message translates to:
  /// **'NexaBiz'**
  String get reportsAccountStatementPrintedBy;

  /// No description provided for @reportsAccountStatementEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ledger movements for this account yet. Journal entries will appear here when available.'**
  String get reportsAccountStatementEmpty;

  /// No description provided for @reportsCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'All PDF reports'**
  String get reportsCatalogTitle;

  /// No description provided for @reportsCatalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the reports catalog to generate and preview PDFs.'**
  String get reportsCatalogSubtitle;

  /// No description provided for @reportsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Report preview'**
  String get reportsPreviewTitle;

  /// No description provided for @reportsPreviewMissing.
  ///
  /// In en, this message translates to:
  /// **'No report is ready to preview. Generate a report first.'**
  String get reportsPreviewMissing;

  /// No description provided for @reportsActionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get reportsActionPrint;

  /// No description provided for @reportsActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get reportsActionShare;

  /// No description provided for @reportsGeneratePreview.
  ///
  /// In en, this message translates to:
  /// **'Generate & preview'**
  String get reportsGeneratePreview;

  /// No description provided for @reportsGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating report…'**
  String get reportsGenerating;

  /// No description provided for @reportsGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get reportsGeneratedAt;

  /// No description provided for @reportsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsPeriod;

  /// No description provided for @reportsPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get reportsPeriodAll;

  /// No description provided for @reportsFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get reportsFromDate;

  /// No description provided for @reportsToDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get reportsToDate;

  /// No description provided for @reportsDateAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get reportsDateAny;

  /// No description provided for @reportsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get reportsStatusAll;

  /// No description provided for @reportsGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get reportsGrandTotal;

  /// No description provided for @reportsRowCount.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get reportsRowCount;

  /// No description provided for @reportsColSaleNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get reportsColSaleNumber;

  /// No description provided for @reportsColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsColDate;

  /// No description provided for @reportsColCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get reportsColCustomer;

  /// No description provided for @reportsColSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get reportsColSettlement;

  /// No description provided for @reportsColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reportsColStatus;

  /// No description provided for @reportsColCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get reportsColCurrency;

  /// No description provided for @reportsColTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reportsColTotal;

  /// No description provided for @reportsEmptySales.
  ///
  /// In en, this message translates to:
  /// **'No sales match the selected filters.'**
  String get reportsEmptySales;

  /// No description provided for @reportsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the report.'**
  String get reportsErrorGeneric;

  /// No description provided for @reportsErrorPrint.
  ///
  /// In en, this message translates to:
  /// **'Printing failed.'**
  String get reportsErrorPrint;

  /// No description provided for @reportsErrorShare.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed.'**
  String get reportsErrorShare;

  /// No description provided for @reportsErrorFile.
  ///
  /// In en, this message translates to:
  /// **'Could not save the PDF file.'**
  String get reportsErrorFile;

  /// No description provided for @reportsErrorFont.
  ///
  /// In en, this message translates to:
  /// **'Could not load report fonts.'**
  String get reportsErrorFont;

  /// No description provided for @salesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesListTitle;

  /// No description provided for @salesListCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse, search, and manage sales documents.'**
  String get salesListCardSubtitle;

  /// No description provided for @salesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get salesCreateTitle;

  /// No description provided for @salesCreateCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a POS-style sale with products and payment.'**
  String get salesCreateCardSubtitle;

  /// No description provided for @salesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit sale'**
  String get salesEditTitle;

  /// No description provided for @salesDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get salesDetailsTitle;

  /// No description provided for @salesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by number, customer, or product'**
  String get salesSearchHint;

  /// No description provided for @salesSearchCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get salesSearchCustomerHint;

  /// No description provided for @salesSearchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Type product name'**
  String get salesSearchProductHint;

  /// No description provided for @salesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get salesEmptyTitle;

  /// No description provided for @salesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first sale to get started.'**
  String get salesEmptyMessage;

  /// No description provided for @salesCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get salesCustomer;

  /// No description provided for @salesSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get salesSelectCustomer;

  /// No description provided for @salesCashCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name or select a customer'**
  String get salesCashCustomerHint;

  /// No description provided for @salesWalkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get salesWalkInCustomer;

  /// No description provided for @salesCustomerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers found.'**
  String get salesCustomerEmpty;

  /// No description provided for @salesCustomerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Customer not found.'**
  String get salesCustomerNotFound;

  /// No description provided for @salesProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get salesProducts;

  /// No description provided for @salesProductName.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get salesProductName;

  /// No description provided for @salesAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get salesAddProduct;

  /// No description provided for @salesAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get salesAddRow;

  /// No description provided for @salesProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products added.'**
  String get salesProductsEmpty;

  /// No description provided for @salesProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get salesProductNotFound;

  /// No description provided for @salesAutocompleteSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load results. Try again.'**
  String get salesAutocompleteSearchFailed;

  /// No description provided for @salesRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get salesRemoveItem;

  /// No description provided for @salesScanProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan product'**
  String get salesScanProduct;

  /// No description provided for @salesScanHint.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode or QR payload'**
  String get salesScanHint;

  /// No description provided for @salesUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get salesUnitPrice;

  /// No description provided for @salesSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get salesSubtotal;

  /// No description provided for @salesDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get salesDiscount;

  /// No description provided for @salesItemDiscount.
  ///
  /// In en, this message translates to:
  /// **'Item discounts'**
  String get salesItemDiscount;

  /// No description provided for @salesDiscountType.
  ///
  /// In en, this message translates to:
  /// **'Discount type'**
  String get salesDiscountType;

  /// No description provided for @salesDiscountFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get salesDiscountFixed;

  /// No description provided for @salesDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get salesDiscountPercent;

  /// No description provided for @salesTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get salesTax;

  /// No description provided for @salesTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax rate (%)'**
  String get salesTaxRate;

  /// No description provided for @salesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get salesTotal;

  /// No description provided for @salesPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get salesPaid;

  /// No description provided for @salesRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get salesRemaining;

  /// No description provided for @salesPayFull.
  ///
  /// In en, this message translates to:
  /// **'Pay full amount'**
  String get salesPayFull;

  /// No description provided for @salesPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get salesPayment;

  /// No description provided for @salesPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get salesPaymentMethod;

  /// No description provided for @salesPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get salesPaymentStatus;

  /// No description provided for @salesPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get salesPaymentCash;

  /// No description provided for @salesPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get salesPaymentCard;

  /// No description provided for @salesPaymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get salesPaymentBankTransfer;

  /// No description provided for @salesPaymentCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get salesPaymentCredit;

  /// No description provided for @salesPaymentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get salesPaymentOther;

  /// No description provided for @salesDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get salesDate;

  /// No description provided for @salesSettlementType.
  ///
  /// In en, this message translates to:
  /// **'Invoice type'**
  String get salesSettlementType;

  /// No description provided for @salesSettlementCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get salesSettlementCash;

  /// No description provided for @salesSettlementCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get salesSettlementCredit;

  /// No description provided for @salesSettlementCashHint.
  ///
  /// In en, this message translates to:
  /// **'Collect now via cash box'**
  String get salesSettlementCashHint;

  /// No description provided for @salesSettlementCreditHint.
  ///
  /// In en, this message translates to:
  /// **'Charge to customer account'**
  String get salesSettlementCreditHint;

  /// No description provided for @salesVoucherBook.
  ///
  /// In en, this message translates to:
  /// **'Sales book'**
  String get salesVoucherBook;

  /// No description provided for @salesSelectVoucherBook.
  ///
  /// In en, this message translates to:
  /// **'Select sales book'**
  String get salesSelectVoucherBook;

  /// No description provided for @salesVoucherBookEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sales books found. Create one in Accounting.'**
  String get salesVoucherBookEmpty;

  /// No description provided for @salesInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get salesInvoiceNumber;

  /// No description provided for @salesCashAccount.
  ///
  /// In en, this message translates to:
  /// **'Cash box account'**
  String get salesCashAccount;

  /// No description provided for @salesSelectCashAccount.
  ///
  /// In en, this message translates to:
  /// **'Select cash box account'**
  String get salesSelectCashAccount;

  /// No description provided for @salesCashAccountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cash box accounts found.'**
  String get salesCashAccountEmpty;

  /// No description provided for @salesCustomerAccount.
  ///
  /// In en, this message translates to:
  /// **'Customer account'**
  String get salesCustomerAccount;

  /// No description provided for @salesCustomerAccountMissing.
  ///
  /// In en, this message translates to:
  /// **'Customer has no accounting account linked.'**
  String get salesCustomerAccountMissing;

  /// No description provided for @salesClearCustomer.
  ///
  /// In en, this message translates to:
  /// **'Clear customer'**
  String get salesClearCustomer;

  /// No description provided for @salesCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get salesCurrency;

  /// No description provided for @salesBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get salesBaseCurrency;

  /// No description provided for @salesExchangeRateHint.
  ///
  /// In en, this message translates to:
  /// **'1 {currency} = {rate} {base}'**
  String salesExchangeRateHint(String currency, String rate, String base);

  /// No description provided for @salesCreditHint.
  ///
  /// In en, this message translates to:
  /// **'Credit sale — the amount is posted to the customer account. Remaining stays outstanding.'**
  String get salesCreditHint;

  /// No description provided for @salesSearchOrScanProduct.
  ///
  /// In en, this message translates to:
  /// **'Search or scan product'**
  String get salesSearchOrScanProduct;

  /// No description provided for @salesInvoiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Invoice options'**
  String get salesInvoiceOptions;

  /// No description provided for @salesItemMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get salesItemMore;

  /// No description provided for @salesAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get salesAddCustomer;

  /// No description provided for @salesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get salesAdd;

  /// No description provided for @salesIncreaseQty.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get salesIncreaseQty;

  /// No description provided for @salesDecreaseQty.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get salesDecreaseQty;

  /// No description provided for @salesErrorCustomerRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a customer for credit sales.'**
  String get salesErrorCustomerRequired;

  /// No description provided for @salesErrorCustomerAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Link an accounting account to the customer first.'**
  String get salesErrorCustomerAccountRequired;

  /// No description provided for @salesErrorCashAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a cash box account.'**
  String get salesErrorCashAccountRequired;

  /// No description provided for @salesErrorVoucherBookRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a sales voucher book.'**
  String get salesErrorVoucherBookRequired;

  /// No description provided for @salesErrorCurrencyRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a valid currency.'**
  String get salesErrorCurrencyRequired;

  /// No description provided for @salesPaymentUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get salesPaymentUnpaid;

  /// No description provided for @salesPaymentPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get salesPaymentPartiallyPaid;

  /// No description provided for @salesPaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get salesPaymentPaid;

  /// No description provided for @salesStatus.
  ///
  /// In en, this message translates to:
  /// **'Sale status'**
  String get salesStatus;

  /// No description provided for @salesStatusUnposted.
  ///
  /// In en, this message translates to:
  /// **'Unposted'**
  String get salesStatusUnposted;

  /// No description provided for @salesStatusPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get salesStatusPosted;

  /// No description provided for @salesStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Unposted'**
  String get salesStatusDraft;

  /// No description provided for @salesStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Unposted'**
  String get salesStatusPending;

  /// No description provided for @salesStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get salesStatusConfirmed;

  /// No description provided for @salesStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get salesStatusCompleted;

  /// No description provided for @salesStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get salesStatusCancelled;

  /// No description provided for @salesStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get salesStatusRejected;

  /// No description provided for @salesNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get salesNotes;

  /// No description provided for @salesSave.
  ///
  /// In en, this message translates to:
  /// **'Save sale'**
  String get salesSave;

  /// No description provided for @salesSaveAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save & post'**
  String get salesSaveAndConfirm;

  /// No description provided for @salesSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving sale…'**
  String get salesSaving;

  /// No description provided for @salesLoadingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Loading invoice…'**
  String get salesLoadingInvoice;

  /// No description provided for @salesConfirming.
  ///
  /// In en, this message translates to:
  /// **'Posting sale…'**
  String get salesConfirming;

  /// No description provided for @salesPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get salesPosting;

  /// No description provided for @salesSaved.
  ///
  /// In en, this message translates to:
  /// **'Sale saved'**
  String get salesSaved;

  /// No description provided for @salesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Sale posted'**
  String get salesConfirmed;

  /// No description provided for @salesPosted.
  ///
  /// In en, this message translates to:
  /// **'Sale posted'**
  String get salesPosted;

  /// No description provided for @salesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale completed'**
  String get salesCompleted;

  /// No description provided for @salesCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sale cancelled'**
  String get salesCancelled;

  /// No description provided for @salesDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Sale duplicated'**
  String get salesDuplicated;

  /// No description provided for @salesConfirmSale.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get salesConfirmSale;

  /// No description provided for @salesPostSale.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get salesPostSale;

  /// No description provided for @salesCompleteSale.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get salesCompleteSale;

  /// No description provided for @salesCancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get salesCancelSale;

  /// No description provided for @salesCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale?'**
  String get salesCancelTitle;

  /// No description provided for @salesCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'Cancel {saleNumber}? Inventory effects will reverse when applicable.'**
  String salesCancelMessage(String saleNumber);

  /// No description provided for @salesDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get salesDuplicate;

  /// No description provided for @salesPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get salesPrintInvoice;

  /// No description provided for @salesPreviewInvoice.
  ///
  /// In en, this message translates to:
  /// **'Preview & print'**
  String get salesPreviewInvoice;

  /// No description provided for @salesPrintingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Preparing invoice preview…'**
  String get salesPrintingInvoice;

  /// No description provided for @salesPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not print the invoice.'**
  String get salesPrintFailed;

  /// No description provided for @salesShareInvoice.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get salesShareInvoice;

  /// No description provided for @salesSharingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Preparing share…'**
  String get salesSharingInvoice;

  /// No description provided for @salesShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the invoice.'**
  String get salesShareFailed;

  /// No description provided for @salesInvoiceSaved.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved to the invoices folder.'**
  String get salesInvoiceSaved;

  /// No description provided for @salesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sale not found'**
  String get salesNotFound;

  /// No description provided for @salesFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get salesFiltersTitle;

  /// No description provided for @salesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get salesFilterAll;

  /// No description provided for @salesApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get salesApplyFilters;

  /// No description provided for @salesClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get salesClearFilters;

  /// No description provided for @salesSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get salesSyncStatus;

  /// No description provided for @salesExternalId.
  ///
  /// In en, this message translates to:
  /// **'External id'**
  String get salesExternalId;

  /// No description provided for @salesExternalNumber.
  ///
  /// In en, this message translates to:
  /// **'External document number'**
  String get salesExternalNumber;

  /// No description provided for @salesErrorEmptyItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one product.'**
  String get salesErrorEmptyItems;

  /// No description provided for @salesErrorInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero.'**
  String get salesErrorInvalidQuantity;

  /// No description provided for @salesErrorInvalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be negative.'**
  String get salesErrorInvalidPrice;

  /// No description provided for @salesErrorPriceBelowCatalog.
  ///
  /// In en, this message translates to:
  /// **'Unit price cannot be lower than the product default price.'**
  String get salesErrorPriceBelowCatalog;

  /// No description provided for @salesPriceBelowCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Below default price'**
  String get salesPriceBelowCatalogHint;

  /// No description provided for @salesErrorInvalidDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount is invalid.'**
  String get salesErrorInvalidDiscount;

  /// No description provided for @salesErrorInvalidTax.
  ///
  /// In en, this message translates to:
  /// **'Tax rate must be between 0 and 100.'**
  String get salesErrorInvalidTax;

  /// No description provided for @salesErrorInvalidPayment.
  ///
  /// In en, this message translates to:
  /// **'Paid amount is invalid.'**
  String get salesErrorInvalidPayment;

  /// No description provided for @salesErrorInvalidStatus.
  ///
  /// In en, this message translates to:
  /// **'This action is not allowed for the current status.'**
  String get salesErrorInvalidStatus;

  /// No description provided for @customersListTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersListTitle;

  /// No description provided for @customersListCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse, create, and manage customers.'**
  String get customersListCardSubtitle;

  /// No description provided for @customersAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer accounts'**
  String get customersAccountsTitle;

  /// No description provided for @customersAccountsCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chart of Accounts entries under the customers parent, same as the CoA tree.'**
  String get customersAccountsCardSubtitle;

  /// No description provided for @customersAccountsUnderParent.
  ///
  /// In en, this message translates to:
  /// **'Under {code} · {name}'**
  String customersAccountsUnderParent(String code, String name);

  /// No description provided for @customersAccountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get customersAccountsEmptyTitle;

  /// No description provided for @customersAccountsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'When you create a customer with auto-link, their posting account appears here and in the Chart of Accounts.'**
  String get customersAccountsEmptyMessage;

  /// No description provided for @customersAccountGroupBadge.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get customersAccountGroupBadge;

  /// No description provided for @customersAccountNonPostingBadge.
  ///
  /// In en, this message translates to:
  /// **'Non-posting'**
  String get customersAccountNonPostingBadge;

  /// No description provided for @customersAccountMissingInChart.
  ///
  /// In en, this message translates to:
  /// **'Account missing from chart'**
  String get customersAccountMissingInChart;

  /// No description provided for @customersCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get customersCreateTitle;

  /// No description provided for @customersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customersEditTitle;

  /// No description provided for @customersDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get customersDetailsTitle;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code, name, phone, or email'**
  String get customersSearchHint;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a customer or import an Excel list to start building your master list.'**
  String get customersEmptyMessage;

  /// No description provided for @customersFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Customer code'**
  String get customersFieldCode;

  /// No description provided for @customersFieldCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Sequential code from the customers parent CoA account (e.g. 12210001). Auto-generated, imported, or manual.'**
  String get customersFieldCodeHelper;

  /// No description provided for @customersGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get customersGenerateCode;

  /// No description provided for @customersFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customersFieldName;

  /// No description provided for @customersFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customersFieldPhone;

  /// No description provided for @customersFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customersFieldEmail;

  /// No description provided for @customersFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customersFieldAddress;

  /// No description provided for @customersFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get customersFieldNotes;

  /// No description provided for @customersFieldActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersFieldActive;

  /// No description provided for @customersFieldAccount.
  ///
  /// In en, this message translates to:
  /// **'Accounting account'**
  String get customersFieldAccount;

  /// No description provided for @customersFieldAccountHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave empty to auto-create under the customers parent when auto-link is on, or enter an existing posting account code.'**
  String get customersFieldAccountHelper;

  /// No description provided for @customersFieldAccountHelperAuto.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to auto-create a Chart of Accounts account under the customers parent (same code as the customer).'**
  String get customersFieldAccountHelperAuto;

  /// No description provided for @customersAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked: {code} · {name}'**
  String customersAccountLinked(String code, String name);

  /// No description provided for @customersAccountLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'No matching posting account found for that code.'**
  String get customersAccountLinkInvalid;

  /// No description provided for @customersAccountAutoLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create or link the Chart of Accounts account for this customer.'**
  String get customersAccountAutoLinkFailed;

  /// No description provided for @customersAccountMustBeUnderParent.
  ///
  /// In en, this message translates to:
  /// **'Linked account must be under parent {code} · {name}.'**
  String customersAccountMustBeUnderParent(String code, String name);

  /// No description provided for @customersSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers settings'**
  String get customersSettingsTitle;

  /// No description provided for @customersSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure Chart of Accounts linking and other customer options.'**
  String get customersSettingsSubtitle;

  /// No description provided for @customersSettingsCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Parent account, auto-link, and more'**
  String get customersSettingsCardSubtitle;

  /// No description provided for @customersAutoLinkSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-link Chart of Accounts'**
  String get customersAutoLinkSectionTitle;

  /// No description provided for @customersAutoLinkSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, saving a customer without an account creates a posting account under the customers parent group.'**
  String get customersAutoLinkSectionSubtitle;

  /// No description provided for @customersAutoLinkToggle.
  ///
  /// In en, this message translates to:
  /// **'Create CoA account automatically'**
  String get customersAutoLinkToggle;

  /// No description provided for @customersLinkMissingAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Link existing customers'**
  String get customersLinkMissingAccountsTitle;

  /// No description provided for @customersLinkMissingAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create Chart of Accounts accounts for customers imported or saved without a link.'**
  String get customersLinkMissingAccountsSubtitle;

  /// No description provided for @customersLinkMissingAccountsAction.
  ///
  /// In en, this message translates to:
  /// **'Link missing accounts now'**
  String get customersLinkMissingAccountsAction;

  /// No description provided for @customersLinkMissingAccountsDone.
  ///
  /// In en, this message translates to:
  /// **'Linked {count} customers to the Chart of Accounts.'**
  String customersLinkMissingAccountsDone(int count);

  /// No description provided for @customersParentAccountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers parent account'**
  String get customersParentAccountSectionTitle;

  /// No description provided for @customersParentAccountSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the Chart of Accounts group under which customer accounts nest (default: Customers 1221).'**
  String get customersParentAccountSectionSubtitle;

  /// No description provided for @customersParentAccountCurrent.
  ///
  /// In en, this message translates to:
  /// **'Parent: {code} · {name}'**
  String customersParentAccountCurrent(String code, String name);

  /// No description provided for @customersParentAccountNotSet.
  ///
  /// In en, this message translates to:
  /// **'Parent account is not set. Configure it in Customers settings.'**
  String get customersParentAccountNotSet;

  /// No description provided for @customersParentAccountField.
  ///
  /// In en, this message translates to:
  /// **'Parent account code'**
  String get customersParentAccountField;

  /// No description provided for @customersParentAccountFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter a group account code from the Chart of Accounts (e.g. 1221).'**
  String get customersParentAccountFieldHelper;

  /// No description provided for @customersParentAccountUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get customersParentAccountUseDefault;

  /// No description provided for @customersParentAccountSaved.
  ///
  /// In en, this message translates to:
  /// **'Customers parent account saved.'**
  String get customersParentAccountSaved;

  /// No description provided for @customersParentAccountInvalid.
  ///
  /// In en, this message translates to:
  /// **'No matching group account found for that code.'**
  String get customersParentAccountInvalid;

  /// No description provided for @customersFieldDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get customersFieldDataSource;

  /// No description provided for @customersDataSourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get customersDataSourceLocal;

  /// No description provided for @customersDataSourceLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Created and owned in this app.'**
  String get customersDataSourceLocalHint;

  /// No description provided for @customersDataSourceExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get customersDataSourceExternal;

  /// No description provided for @customersDataSourceExternalHint.
  ///
  /// In en, this message translates to:
  /// **'Imported or maintained from an external accounting/ERP system.'**
  String get customersDataSourceExternalHint;

  /// No description provided for @customersFieldExternalId.
  ///
  /// In en, this message translates to:
  /// **'External ID'**
  String get customersFieldExternalId;

  /// No description provided for @customersFieldExternalIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Required when the data source is external.'**
  String get customersFieldExternalIdHelper;

  /// No description provided for @customersStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get customersStatusActive;

  /// No description provided for @customersStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get customersStatusInactive;

  /// No description provided for @customersCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer created.'**
  String get customersCreated;

  /// No description provided for @customersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated.'**
  String get customersUpdated;

  /// No description provided for @customersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get customersDelete;

  /// No description provided for @customersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete customer?'**
  String get customersDeleteTitle;

  /// No description provided for @customersDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the customer list?'**
  String customersDeleteMessage(String name);

  /// No description provided for @customersDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted.'**
  String get customersDeleted;

  /// No description provided for @customersErrorDuplicateCode.
  ///
  /// In en, this message translates to:
  /// **'A customer with this code already exists.'**
  String get customersErrorDuplicateCode;

  /// No description provided for @customersErrorDuplicateExternalId.
  ///
  /// In en, this message translates to:
  /// **'A customer with this external ID already exists.'**
  String get customersErrorDuplicateExternalId;

  /// No description provided for @customersErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Customer code is required.'**
  String get customersErrorInvalidCode;

  /// No description provided for @customersErrorInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required.'**
  String get customersErrorInvalidName;

  /// No description provided for @customersErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get customersErrorInvalidEmail;

  /// No description provided for @customersErrorExternalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'External ID is required for external customers.'**
  String get customersErrorExternalIdRequired;

  /// No description provided for @customersImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import customers'**
  String get customersImportTitle;

  /// No description provided for @customersImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import customer rows from an Excel file.'**
  String get customersImportSubtitle;

  /// No description provided for @customersImportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import customers'**
  String get customersImportPageTitle;

  /// No description provided for @customersImportFormatHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers Excel layout'**
  String get customersImportFormatHintTitle;

  /// No description provided for @customersImportFormatHintIntro.
  ///
  /// In en, this message translates to:
  /// **'First row = headers. Required: code and name. Use .xlsx or .xls.'**
  String get customersImportFormatHintIntro;

  /// No description provided for @customersImportFormatColCodeAliases.
  ///
  /// In en, this message translates to:
  /// **'Customer Code · Code · رمز العميل'**
  String get customersImportFormatColCodeAliases;

  /// No description provided for @customersImportFormatColNameAliases.
  ///
  /// In en, this message translates to:
  /// **'Customer Name · Name · اسم العميل'**
  String get customersImportFormatColNameAliases;

  /// No description provided for @customersImportFormatColPhoneAliases.
  ///
  /// In en, this message translates to:
  /// **'Phone · Mobile · الهاتف'**
  String get customersImportFormatColPhoneAliases;

  /// No description provided for @customersImportFormatColEmailAliases.
  ///
  /// In en, this message translates to:
  /// **'Email · البريد'**
  String get customersImportFormatColEmailAliases;

  /// No description provided for @customersImportFormatColAddressAliases.
  ///
  /// In en, this message translates to:
  /// **'Address · العنوان'**
  String get customersImportFormatColAddressAliases;

  /// No description provided for @customersImportFormatColNotesAliases.
  ///
  /// In en, this message translates to:
  /// **'Notes · ملاحظات'**
  String get customersImportFormatColNotesAliases;

  /// No description provided for @customersImportFormatColExternalIdAliases.
  ///
  /// In en, this message translates to:
  /// **'External ID · المعرف الخارجي'**
  String get customersImportFormatColExternalIdAliases;

  /// No description provided for @customersImportFormatSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Without headers, columns are read as: code, name. Matching rows update by customer code (or external ID when present).'**
  String get customersImportFormatSampleNote;

  /// No description provided for @customersImportInsertedCount.
  ///
  /// In en, this message translates to:
  /// **'Inserted {count} customers'**
  String customersImportInsertedCount(int count);

  /// No description provided for @customersImportUpdatedCount.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} customers'**
  String customersImportUpdatedCount(int count);

  /// No description provided for @customersNoValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid customer rows were found in the file.'**
  String get customersNoValidRows;

  /// No description provided for @loadingImportingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Importing customers…'**
  String get loadingImportingCustomers;

  /// No description provided for @accountingModeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounting mode'**
  String get accountingModeSectionTitle;

  /// No description provided for @accountingModeSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether this app owns accounting locally or complements an external ERP.'**
  String get accountingModeSectionSubtitle;

  /// No description provided for @accountingModeStandalone.
  ///
  /// In en, this message translates to:
  /// **'Standalone'**
  String get accountingModeStandalone;

  /// No description provided for @accountingModeStandaloneDescription.
  ///
  /// In en, this message translates to:
  /// **'The app owns Chart of Accounts and future local accounting features.'**
  String get accountingModeStandaloneDescription;

  /// No description provided for @accountingModeIntegrated.
  ///
  /// In en, this message translates to:
  /// **'Integrated'**
  String get accountingModeIntegrated;

  /// No description provided for @accountingModeIntegratedDescription.
  ///
  /// In en, this message translates to:
  /// **'The app is an operational interface beside an existing accounting/ERP system.'**
  String get accountingModeIntegratedDescription;

  /// No description provided for @accountingModeStandaloneHint.
  ///
  /// In en, this message translates to:
  /// **'Local accounting data is authoritative. Standalone sales create local journal entries on save/post.'**
  String get accountingModeStandaloneHint;

  /// No description provided for @accountingModeIntegratedHint.
  ///
  /// In en, this message translates to:
  /// **'Operational documents can be prepared here and posted later in the external system. Local journals are not auto-created.'**
  String get accountingModeIntegratedHint;

  /// No description provided for @accountingModeSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Accounting mode saved.'**
  String get accountingModeSavedSuccess;

  /// No description provided for @accountingFiscalClosedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Closed fiscal period'**
  String get accountingFiscalClosedSectionTitle;

  /// No description provided for @accountingFiscalClosedSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Journal entries on or before this date cannot be posted or changed.'**
  String get accountingFiscalClosedSectionSubtitle;

  /// No description provided for @accountingFiscalClosedThroughLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed through'**
  String get accountingFiscalClosedThroughLabel;

  /// No description provided for @accountingFiscalClosedNone.
  ///
  /// In en, this message translates to:
  /// **'No closed period'**
  String get accountingFiscalClosedNone;

  /// No description provided for @accountingFiscalClosedSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Closed fiscal period saved.'**
  String get accountingFiscalClosedSavedSuccess;

  /// No description provided for @accountingFiscalClosedClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get accountingFiscalClosedClear;

  /// No description provided for @accountingJournalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal entries'**
  String get accountingJournalsTitle;

  /// No description provided for @accountingJournalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse, create, and review journal vouchers.'**
  String get accountingJournalsSubtitle;

  /// No description provided for @accountingJournalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet'**
  String get accountingJournalsEmptyTitle;

  /// No description provided for @accountingJournalsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a manual journal or post a standalone sale.'**
  String get accountingJournalsEmptyMessage;

  /// No description provided for @accountingJournalsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search voucher number or description'**
  String get accountingJournalsSearchHint;

  /// No description provided for @accountingJournalAdd.
  ///
  /// In en, this message translates to:
  /// **'New journal'**
  String get accountingJournalAdd;

  /// No description provided for @accountingJournalDetails.
  ///
  /// In en, this message translates to:
  /// **'Journal details'**
  String get accountingJournalDetails;

  /// No description provided for @accountingJournalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit journal'**
  String get accountingJournalEdit;

  /// No description provided for @accountingJournalSave.
  ///
  /// In en, this message translates to:
  /// **'Save journal'**
  String get accountingJournalSave;

  /// No description provided for @accountingJournalSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Journal saved.'**
  String get accountingJournalSavedSuccess;

  /// No description provided for @accountingJournalVoid.
  ///
  /// In en, this message translates to:
  /// **'Void entry'**
  String get accountingJournalVoid;

  /// No description provided for @accountingJournalVoidConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this journal?'**
  String get accountingJournalVoidConfirmTitle;

  /// No description provided for @accountingJournalVoidConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The entry will be soft-deleted and removed from ledgers. Lines are kept for audit.'**
  String get accountingJournalVoidConfirmMessage;

  /// No description provided for @accountingJournalVoidedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Journal voided.'**
  String get accountingJournalVoidedSuccess;

  /// No description provided for @accountingJournalNotFound.
  ///
  /// In en, this message translates to:
  /// **'Journal entry not found.'**
  String get accountingJournalNotFound;

  /// No description provided for @accountingJournalFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get accountingJournalFieldDate;

  /// No description provided for @accountingJournalFieldVoucherNumber.
  ///
  /// In en, this message translates to:
  /// **'Voucher number'**
  String get accountingJournalFieldVoucherNumber;

  /// No description provided for @accountingJournalFieldVoucherType.
  ///
  /// In en, this message translates to:
  /// **'Voucher type'**
  String get accountingJournalFieldVoucherType;

  /// No description provided for @accountingJournalFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get accountingJournalFieldDescription;

  /// No description provided for @accountingJournalFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountingJournalFieldCurrency;

  /// No description provided for @accountingJournalFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get accountingJournalFieldStatus;

  /// No description provided for @accountingJournalPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get accountingJournalPosted;

  /// No description provided for @accountingJournalUnposted.
  ///
  /// In en, this message translates to:
  /// **'Unposted'**
  String get accountingJournalUnposted;

  /// No description provided for @accountingJournalSourceLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to {source}'**
  String accountingJournalSourceLinked(String source);

  /// No description provided for @accountingJournalLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get accountingJournalLines;

  /// No description provided for @accountingJournalAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get accountingJournalAddLine;

  /// No description provided for @accountingJournalAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountingJournalAccount;

  /// No description provided for @accountingJournalDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get accountingJournalDebit;

  /// No description provided for @accountingJournalCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get accountingJournalCredit;

  /// No description provided for @accountingJournalTotals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get accountingJournalTotals;

  /// No description provided for @accountingJournalPickAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get accountingJournalPickAccount;

  /// No description provided for @accountingJournalErrorUnbalanced.
  ///
  /// In en, this message translates to:
  /// **'Total debit must equal total credit.'**
  String get accountingJournalErrorUnbalanced;

  /// No description provided for @accountingJournalErrorPeriodClosed.
  ///
  /// In en, this message translates to:
  /// **'This date falls in a closed fiscal period.'**
  String get accountingJournalErrorPeriodClosed;

  /// No description provided for @accountingJournalErrorLines.
  ///
  /// In en, this message translates to:
  /// **'Add at least two balanced lines.'**
  String get accountingJournalErrorLines;

  /// No description provided for @accountingJournalManualType.
  ///
  /// In en, this message translates to:
  /// **'Manual journal'**
  String get accountingJournalManualType;

  /// No description provided for @accountingChartOfAccounts.
  ///
  /// In en, this message translates to:
  /// **'Chart of Accounts'**
  String get accountingChartOfAccounts;

  /// No description provided for @accountingChartOfAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse and manage the hierarchical account structure.'**
  String get accountingChartOfAccountsDescription;

  /// No description provided for @accountingReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounting reports'**
  String get accountingReportsTitle;

  /// No description provided for @accountingReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Statements and financial reports built on the Chart of Accounts.'**
  String get accountingReportsSubtitle;

  /// No description provided for @accountingReportTrialBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial balance'**
  String get accountingReportTrialBalanceTitle;

  /// No description provided for @accountingReportJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get accountingReportJournalTitle;

  /// No description provided for @accountingReportComingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later release.'**
  String get accountingReportComingSoonSubtitle;

  /// No description provided for @accountingReportComingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get accountingReportComingSoonBadge;

  /// No description provided for @accountingCurrencyRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency rates'**
  String get accountingCurrencyRatesTitle;

  /// No description provided for @accountingCurrencyRatesCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add only the currencies you need and set their rates.'**
  String get accountingCurrencyRatesCardSubtitle;

  /// No description provided for @accountingCurrencyRatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add currencies on demand. Only enabled currencies (plus the company base) appear here — later used for multi-currency account balances.'**
  String get accountingCurrencyRatesSubtitle;

  /// No description provided for @accountingCurrencyRatesBase.
  ///
  /// In en, this message translates to:
  /// **'Base currency: {code} · {name}'**
  String accountingCurrencyRatesBase(String code, String name);

  /// No description provided for @accountingCurrencyRatesBaseBadge.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get accountingCurrencyRatesBaseBadge;

  /// No description provided for @accountingCurrencyRatesBaseHint.
  ///
  /// In en, this message translates to:
  /// **'Company base currency — rate is always 1.'**
  String get accountingCurrencyRatesBaseHint;

  /// No description provided for @accountingCurrencyRatesNotSet.
  ///
  /// In en, this message translates to:
  /// **'Rate not set — tap to enter.'**
  String get accountingCurrencyRatesNotSet;

  /// No description provided for @accountingCurrencyRatesEquals.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String accountingCurrencyRatesEquals(String from, String rate, String to);

  /// No description provided for @accountingCurrencyRatesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {when}'**
  String accountingCurrencyRatesUpdated(String when);

  /// No description provided for @accountingCurrencyRatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No currencies enabled'**
  String get accountingCurrencyRatesEmptyTitle;

  /// No description provided for @accountingCurrencyRatesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap Add currency to enable a currency and set its rate.'**
  String get accountingCurrencyRatesEmptyMessage;

  /// No description provided for @accountingCurrencyRatesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add currency'**
  String get accountingCurrencyRatesAdd;

  /// No description provided for @accountingCurrencyRatesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable currency'**
  String get accountingCurrencyRatesAddTitle;

  /// No description provided for @accountingCurrencyRatesAddHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a currency you need for the business and enter its rate against the base currency.'**
  String get accountingCurrencyRatesAddHint;

  /// No description provided for @accountingCurrencyRatesCurrencyField.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountingCurrencyRatesCurrencyField;

  /// No description provided for @accountingCurrencyRatesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get accountingCurrencyRatesRemove;

  /// No description provided for @accountingCurrencyRatesRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove currency?'**
  String get accountingCurrencyRatesRemoveTitle;

  /// No description provided for @accountingCurrencyRatesRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} ({code})? It will no longer be available for multi-currency balances until you add it again.'**
  String accountingCurrencyRatesRemoveMessage(String name, String code);

  /// No description provided for @accountingCurrencyRatesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Currency removed.'**
  String get accountingCurrencyRatesRemoved;

  /// No description provided for @accountingCurrencyRatesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {code} rate'**
  String accountingCurrencyRatesEditTitle(String code);

  /// No description provided for @accountingCurrencyRatesEditHint.
  ///
  /// In en, this message translates to:
  /// **'How many {base} equal 1 {currency}?'**
  String accountingCurrencyRatesEditHint(String currency, String base);

  /// No description provided for @accountingCurrencyRatesRateField.
  ///
  /// In en, this message translates to:
  /// **'Rate to base'**
  String get accountingCurrencyRatesRateField;

  /// No description provided for @accountingCurrencyRatesRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Example: if base is {base}, enter how many {base} equal 1 unit of this currency.'**
  String accountingCurrencyRatesRateHelper(String base);

  /// No description provided for @accountingCurrencyRatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive rate.'**
  String get accountingCurrencyRatesInvalid;

  /// No description provided for @accountingCurrencyRatesSaved.
  ///
  /// In en, this message translates to:
  /// **'Currency rate saved.'**
  String get accountingCurrencyRatesSaved;

  /// No description provided for @accountingVoucherBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher books'**
  String get accountingVoucherBooksTitle;

  /// No description provided for @accountingVoucherBooksCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up numbering books for sales, receipts, and other vouchers.'**
  String get accountingVoucherBooksCardSubtitle;

  /// No description provided for @accountingVoucherBooksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a section, then use tabs for each type (e.g. sales and sales returns). Each type has its own list and add action.'**
  String get accountingVoucherBooksSubtitle;

  /// No description provided for @accountingVoucherBooksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No voucher books'**
  String get accountingVoucherBooksEmptyTitle;

  /// No description provided for @accountingVoucherBooksEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a book under a section to prepare sequential voucher numbers.'**
  String get accountingVoucherBooksEmptyMessage;

  /// No description provided for @accountingVoucherBooksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get accountingVoucherBooksAdd;

  /// No description provided for @accountingVoucherBooksAddOfType.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String accountingVoucherBooksAddOfType(String type);

  /// No description provided for @accountingVoucherBooksAddUnderSection.
  ///
  /// In en, this message translates to:
  /// **'Add book in this section'**
  String get accountingVoucherBooksAddUnderSection;

  /// No description provided for @accountingVoucherBooksSectionKinds.
  ///
  /// In en, this message translates to:
  /// **'{kinds} types · {books} books'**
  String accountingVoucherBooksSectionKinds(int kinds, int books);

  /// No description provided for @accountingVoucherBooksTypeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No {type} books'**
  String accountingVoucherBooksTypeEmptyTitle(String type);

  /// No description provided for @accountingVoucherBooksTypeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap add to create a numbering book for this type.'**
  String get accountingVoucherBooksTypeEmptyMessage;

  /// No description provided for @accountingVoucherBooksEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get accountingVoucherBooksEdit;

  /// No description provided for @accountingVoucherBooksSave.
  ///
  /// In en, this message translates to:
  /// **'Save book'**
  String get accountingVoucherBooksSave;

  /// No description provided for @accountingVoucherBooksName.
  ///
  /// In en, this message translates to:
  /// **'Book name'**
  String get accountingVoucherBooksName;

  /// No description provided for @accountingVoucherBooksNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main sales / Sales returns branch A'**
  String get accountingVoucherBooksNameHint;

  /// No description provided for @accountingVoucherBooksParentSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get accountingVoucherBooksParentSection;

  /// No description provided for @accountingVoucherBooksType.
  ///
  /// In en, this message translates to:
  /// **'Book type'**
  String get accountingVoucherBooksType;

  /// No description provided for @accountingVoucherBooksCurrentNumber.
  ///
  /// In en, this message translates to:
  /// **'Current number'**
  String get accountingVoucherBooksCurrentNumber;

  /// No description provided for @accountingVoucherBooksCurrentNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'The next voucher number that will be issued from this book.'**
  String get accountingVoucherBooksCurrentNumberHelper;

  /// No description provided for @accountingVoucherBooksEndNumber.
  ///
  /// In en, this message translates to:
  /// **'End number'**
  String get accountingVoucherBooksEndNumber;

  /// No description provided for @accountingVoucherBooksEndNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Last number available in this book.'**
  String get accountingVoucherBooksEndNumberHelper;

  /// No description provided for @accountingVoucherBooksRangePreview.
  ///
  /// In en, this message translates to:
  /// **'Current {current} · ends at {end}'**
  String accountingVoucherBooksRangePreview(String current, String end);

  /// No description provided for @accountingVoucherBooksSectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No books yet} one{1 book} other{{count} books}}'**
  String accountingVoucherBooksSectionCount(int count);

  /// No description provided for @accountingVoucherBooksSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No books in this section yet. Add sales, returns, or other series as needed.'**
  String get accountingVoucherBooksSectionEmpty;

  /// No description provided for @accountingVoucherBooksNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get accountingVoucherBooksNotes;

  /// No description provided for @accountingVoucherBooksActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountingVoucherBooksActive;

  /// No description provided for @accountingVoucherBooksInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get accountingVoucherBooksInactive;

  /// No description provided for @accountingVoucherBooksDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountingVoucherBooksDelete;

  /// No description provided for @accountingVoucherBooksDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete voucher book?'**
  String get accountingVoucherBooksDeleteTitle;

  /// No description provided for @accountingVoucherBooksDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? This cannot be undone.'**
  String accountingVoucherBooksDeleteMessage(String name);

  /// No description provided for @accountingVoucherBooksDeleted.
  ///
  /// In en, this message translates to:
  /// **'Voucher book deleted.'**
  String get accountingVoucherBooksDeleted;

  /// No description provided for @accountingVoucherBooksSaved.
  ///
  /// In en, this message translates to:
  /// **'Voucher book saved.'**
  String get accountingVoucherBooksSaved;

  /// No description provided for @accountingVoucherBooksErrorName.
  ///
  /// In en, this message translates to:
  /// **'Enter a book name.'**
  String get accountingVoucherBooksErrorName;

  /// No description provided for @accountingVoucherBooksErrorParent.
  ///
  /// In en, this message translates to:
  /// **'Choose a parent section.'**
  String get accountingVoucherBooksErrorParent;

  /// No description provided for @accountingVoucherBooksErrorCurrentNumber.
  ///
  /// In en, this message translates to:
  /// **'Current number must be at least 1.'**
  String get accountingVoucherBooksErrorCurrentNumber;

  /// No description provided for @accountingVoucherBooksErrorEndNumber.
  ///
  /// In en, this message translates to:
  /// **'End number must be at least 1.'**
  String get accountingVoucherBooksErrorEndNumber;

  /// No description provided for @accountingVoucherBooksErrorEndBeforeCurrent.
  ///
  /// In en, this message translates to:
  /// **'End number must be greater than or equal to current number.'**
  String get accountingVoucherBooksErrorEndBeforeCurrent;

  /// No description provided for @accountingVoucherBookTypeSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get accountingVoucherBookTypeSales;

  /// No description provided for @accountingVoucherBookTypeSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales returns'**
  String get accountingVoucherBookTypeSalesReturns;

  /// No description provided for @accountingVoucherBookTypeReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get accountingVoucherBookTypeReceipts;

  /// No description provided for @accountingVoucherBookTypePayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get accountingVoucherBookTypePayments;

  /// No description provided for @accountingVoucherBookTypePurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get accountingVoucherBookTypePurchases;

  /// No description provided for @accountingVoucherBookTypePurchaseReturns.
  ///
  /// In en, this message translates to:
  /// **'Purchase returns'**
  String get accountingVoucherBookTypePurchaseReturns;

  /// No description provided for @accountingVoucherBookTypeJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get accountingVoucherBookTypeJournal;

  /// No description provided for @accountingAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountingAddAccount;

  /// No description provided for @accountingEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountingEditAccount;

  /// No description provided for @accountingSaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get accountingSaveAccount;

  /// No description provided for @accountingAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountingAccountDetails;

  /// No description provided for @accountingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code'**
  String get accountingSearchHint;

  /// No description provided for @accountingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountingEmptyTitle;

  /// No description provided for @accountingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Default accounts will appear after first open, or add your own.'**
  String get accountingEmptyMessage;

  /// No description provided for @accountingNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching accounts'**
  String get accountingNoSearchResults;

  /// No description provided for @accountingNoSearchResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or account code.'**
  String get accountingNoSearchResultsMessage;

  /// No description provided for @accountingExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get accountingExpandAll;

  /// No description provided for @accountingCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get accountingCollapseAll;

  /// No description provided for @accountingShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get accountingShowInactive;

  /// No description provided for @accountingHideInactive.
  ///
  /// In en, this message translates to:
  /// **'Hide inactive'**
  String get accountingHideInactive;

  /// No description provided for @accountingFieldName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountingFieldName;

  /// No description provided for @accountingFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Account code'**
  String get accountingFieldCode;

  /// No description provided for @accountingFieldParent.
  ///
  /// In en, this message translates to:
  /// **'Parent account'**
  String get accountingFieldParent;

  /// No description provided for @accountingFieldType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountingFieldType;

  /// No description provided for @accountingFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get accountingFieldDescription;

  /// No description provided for @accountingFieldNormalBalance.
  ///
  /// In en, this message translates to:
  /// **'Normal balance'**
  String get accountingFieldNormalBalance;

  /// No description provided for @accountingFieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get accountingFieldLevel;

  /// No description provided for @accountingFieldKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get accountingFieldKind;

  /// No description provided for @accountingFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get accountingFieldStatus;

  /// No description provided for @accountingFieldSystem.
  ///
  /// In en, this message translates to:
  /// **'System account'**
  String get accountingFieldSystem;

  /// No description provided for @accountingFieldCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get accountingFieldCreatedAt;

  /// No description provided for @accountingFieldUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get accountingFieldUpdatedAt;

  /// No description provided for @accountingRootAccount.
  ///
  /// In en, this message translates to:
  /// **'No parent (root)'**
  String get accountingRootAccount;

  /// No description provided for @accountingTypeAsset.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get accountingTypeAsset;

  /// No description provided for @accountingTypeLiability.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get accountingTypeLiability;

  /// No description provided for @accountingTypeEquity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get accountingTypeEquity;

  /// No description provided for @accountingTypeRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get accountingTypeRevenue;

  /// No description provided for @accountingTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get accountingTypeExpense;

  /// No description provided for @accountingTypeInheritedHint.
  ///
  /// In en, this message translates to:
  /// **'Type is inherited from the parent account.'**
  String get accountingTypeInheritedHint;

  /// No description provided for @accountingNormalDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get accountingNormalDebit;

  /// No description provided for @accountingNormalCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get accountingNormalCredit;

  /// No description provided for @accountingAccountGroup.
  ///
  /// In en, this message translates to:
  /// **'Group account'**
  String get accountingAccountGroup;

  /// No description provided for @accountingAccountGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Group accounts organize the tree and are not used for posting.'**
  String get accountingAccountGroupHint;

  /// No description provided for @accountingAccountPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting account'**
  String get accountingAccountPosting;

  /// No description provided for @accountingAccountActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountingAccountActive;

  /// No description provided for @accountingAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get accountingAccountInactive;

  /// No description provided for @accountingSystemAccount.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get accountingSystemAccount;

  /// No description provided for @accountingSystemAccountHint.
  ///
  /// In en, this message translates to:
  /// **'System accounts have protected code and type.'**
  String get accountingSystemAccountHint;

  /// No description provided for @accountingYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get accountingYes;

  /// No description provided for @accountingNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get accountingNo;

  /// No description provided for @accountingComingSoonSection.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get accountingComingSoonSection;

  /// No description provided for @accountingComingSoonHint.
  ///
  /// In en, this message translates to:
  /// **'Available after journal entries are implemented.'**
  String get accountingComingSoonHint;

  /// No description provided for @accountingCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get accountingCurrentBalance;

  /// No description provided for @accountingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get accountingTransactions;

  /// No description provided for @accountingLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get accountingLedger;

  /// No description provided for @accountingDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get accountingDeactivate;

  /// No description provided for @accountingSoftDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove account'**
  String get accountingSoftDelete;

  /// No description provided for @accountingDeactivateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account?'**
  String get accountingDeactivateConfirmTitle;

  /// No description provided for @accountingDeactivateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The account stays in history but cannot be selected for new activity.'**
  String get accountingDeactivateConfirmMessage;

  /// No description provided for @accountingDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove account?'**
  String get accountingDeleteConfirmTitle;

  /// No description provided for @accountingDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This soft-deletes the account. System accounts and accounts with children cannot be removed.'**
  String get accountingDeleteConfirmMessage;

  /// No description provided for @accountingSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account saved successfully.'**
  String get accountingSavedSuccess;

  /// No description provided for @accountingDeactivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated.'**
  String get accountingDeactivatedSuccess;

  /// No description provided for @accountingDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account removed.'**
  String get accountingDeletedSuccess;

  /// No description provided for @accountingAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found.'**
  String get accountingAccountNotFound;

  /// No description provided for @accountingErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Account name is required.'**
  String get accountingErrorNameRequired;

  /// No description provided for @accountingErrorCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Account code is required.'**
  String get accountingErrorCodeRequired;

  /// No description provided for @accountingErrorDuplicateCode.
  ///
  /// In en, this message translates to:
  /// **'An account with this code already exists.'**
  String get accountingErrorDuplicateCode;

  /// No description provided for @accountingErrorTypeMismatch.
  ///
  /// In en, this message translates to:
  /// **'Account type must match the parent account.'**
  String get accountingErrorTypeMismatch;

  /// No description provided for @accountingErrorInvalidParent.
  ///
  /// In en, this message translates to:
  /// **'Parent account is invalid or inactive.'**
  String get accountingErrorInvalidParent;

  /// No description provided for @accountingErrorCircularParent.
  ///
  /// In en, this message translates to:
  /// **'An account cannot be nested under itself.'**
  String get accountingErrorCircularParent;

  /// No description provided for @accountingErrorParentMustBeGroup.
  ///
  /// In en, this message translates to:
  /// **'Only group accounts can have children.'**
  String get accountingErrorParentMustBeGroup;

  /// No description provided for @accountingErrorSystemProtected.
  ///
  /// In en, this message translates to:
  /// **'System accounts cannot be changed this way.'**
  String get accountingErrorSystemProtected;

  /// No description provided for @accountingErrorHasChildren.
  ///
  /// In en, this message translates to:
  /// **'Remove or move child accounts first.'**
  String get accountingErrorHasChildren;

  /// No description provided for @accountingErrorInUse.
  ///
  /// In en, this message translates to:
  /// **'This account is used in transactions and cannot be removed.'**
  String get accountingErrorInUse;

  /// No description provided for @accountingAccountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String accountingAccountsCount(int count);

  /// No description provided for @accountingSectionChildrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String accountingSectionChildrenCount(int count);

  /// No description provided for @accountingFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get accountingFilterAll;

  /// No description provided for @accountingFilterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get accountingFilterByType;

  /// No description provided for @accountingToolbarActions.
  ///
  /// In en, this message translates to:
  /// **'Tree actions'**
  String get accountingToolbarActions;

  /// No description provided for @accountingAccountAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get accountingAccountAssets;

  /// No description provided for @accountingAccountCurrentAssets.
  ///
  /// In en, this message translates to:
  /// **'Current Assets'**
  String get accountingAccountCurrentAssets;

  /// No description provided for @accountingAccountCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountingAccountCash;

  /// No description provided for @accountingAccountBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountingAccountBank;

  /// No description provided for @accountingAccountPettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get accountingAccountPettyCash;

  /// No description provided for @accountingAccountAccountsReceivable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Receivable'**
  String get accountingAccountAccountsReceivable;

  /// No description provided for @accountingAccountCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get accountingAccountCustomers;

  /// No description provided for @accountingAccountInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get accountingAccountInventory;

  /// No description provided for @accountingAccountInventoryInTransit.
  ///
  /// In en, this message translates to:
  /// **'Inventory in Transit'**
  String get accountingAccountInventoryInTransit;

  /// No description provided for @accountingAccountVatInput.
  ///
  /// In en, this message translates to:
  /// **'VAT Input'**
  String get accountingAccountVatInput;

  /// No description provided for @accountingAccountPrepaidExpenses.
  ///
  /// In en, this message translates to:
  /// **'Prepaid Expenses'**
  String get accountingAccountPrepaidExpenses;

  /// No description provided for @accountingAccountOtherCurrentAssets.
  ///
  /// In en, this message translates to:
  /// **'Other Current Assets'**
  String get accountingAccountOtherCurrentAssets;

  /// No description provided for @accountingAccountFixedAssets.
  ///
  /// In en, this message translates to:
  /// **'Fixed Assets'**
  String get accountingAccountFixedAssets;

  /// No description provided for @accountingAccountBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get accountingAccountBuildings;

  /// No description provided for @accountingAccountVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get accountingAccountVehicles;

  /// No description provided for @accountingAccountEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get accountingAccountEquipment;

  /// No description provided for @accountingAccountLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get accountingAccountLiabilities;

  /// No description provided for @accountingAccountCurrentLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Current Liabilities'**
  String get accountingAccountCurrentLiabilities;

  /// No description provided for @accountingAccountAccountsPayable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Payable'**
  String get accountingAccountAccountsPayable;

  /// No description provided for @accountingAccountSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get accountingAccountSuppliers;

  /// No description provided for @accountingAccountShortTermLoans.
  ///
  /// In en, this message translates to:
  /// **'Short Term Loans'**
  String get accountingAccountShortTermLoans;

  /// No description provided for @accountingAccountVatOutput.
  ///
  /// In en, this message translates to:
  /// **'VAT Output Payable'**
  String get accountingAccountVatOutput;

  /// No description provided for @accountingAccountAccruedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Accrued Expenses'**
  String get accountingAccountAccruedExpenses;

  /// No description provided for @accountingAccountCustomerAdvances.
  ///
  /// In en, this message translates to:
  /// **'Customer Advances'**
  String get accountingAccountCustomerAdvances;

  /// No description provided for @accountingAccountLongTermLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Long Term Liabilities'**
  String get accountingAccountLongTermLiabilities;

  /// No description provided for @accountingAccountLongTermLoans.
  ///
  /// In en, this message translates to:
  /// **'Long Term Loans'**
  String get accountingAccountLongTermLoans;

  /// No description provided for @accountingAccountEquity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get accountingAccountEquity;

  /// No description provided for @accountingAccountCapital.
  ///
  /// In en, this message translates to:
  /// **'Capital'**
  String get accountingAccountCapital;

  /// No description provided for @accountingAccountRetainedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Retained Earnings'**
  String get accountingAccountRetainedEarnings;

  /// No description provided for @accountingAccountRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get accountingAccountRevenue;

  /// No description provided for @accountingAccountSalesRevenue.
  ///
  /// In en, this message translates to:
  /// **'Sales Revenue'**
  String get accountingAccountSalesRevenue;

  /// No description provided for @accountingAccountOtherRevenue.
  ///
  /// In en, this message translates to:
  /// **'Other Revenue'**
  String get accountingAccountOtherRevenue;

  /// No description provided for @accountingAccountPurchaseDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Purchase Discounts'**
  String get accountingAccountPurchaseDiscounts;

  /// No description provided for @accountingAccountExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get accountingAccountExpenses;

  /// No description provided for @accountingAccountCogs.
  ///
  /// In en, this message translates to:
  /// **'Cost of Goods Sold'**
  String get accountingAccountCogs;

  /// No description provided for @accountingAccountInventoryAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Inventory Adjustments'**
  String get accountingAccountInventoryAdjustments;

  /// No description provided for @accountingAccountSalesReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales Returns'**
  String get accountingAccountSalesReturns;

  /// No description provided for @accountingAccountSalesDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Sales Discounts'**
  String get accountingAccountSalesDiscounts;

  /// No description provided for @accountingAccountSalaries.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get accountingAccountSalaries;

  /// No description provided for @accountingAccountRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get accountingAccountRent;

  /// No description provided for @accountingAccountUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get accountingAccountUtilities;

  /// No description provided for @accountingAccountBankCharges.
  ///
  /// In en, this message translates to:
  /// **'Bank Charges'**
  String get accountingAccountBankCharges;

  /// No description provided for @accountingAccountDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Depreciation'**
  String get accountingAccountDepreciation;

  /// No description provided for @accountingAccountAdvertising.
  ///
  /// In en, this message translates to:
  /// **'Advertising'**
  String get accountingAccountAdvertising;

  /// No description provided for @accountingAccountShippingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Shipping and Delivery'**
  String get accountingAccountShippingDelivery;

  /// No description provided for @accountingAccountMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get accountingAccountMaintenance;

  /// No description provided for @accountingAccountOtherExpenses.
  ///
  /// In en, this message translates to:
  /// **'Other Expenses'**
  String get accountingAccountOtherExpenses;

  /// No description provided for @inventoryStockCountService.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get inventoryStockCountService;

  /// No description provided for @inventoryStockCountServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Count items, import stock lists, and view count reports.'**
  String get inventoryStockCountServiceDescription;

  /// No description provided for @inventoryProductsService.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get inventoryProductsService;

  /// No description provided for @inventoryProductsServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the product catalog, prices, and pack sizes.'**
  String get inventoryProductsServiceDescription;

  /// No description provided for @productsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsHubTitle;

  /// No description provided for @productsHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse the catalog, manage barcodes, or import from Excel.'**
  String get productsHubDescription;

  /// No description provided for @productsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Product list'**
  String get productsListTitle;

  /// No description provided for @productsListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, add, edit, and delete products.'**
  String get productsListSubtitle;

  /// No description provided for @productsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import products'**
  String get productsImportTitle;

  /// No description provided for @productsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import catalog rows from an Excel file.'**
  String get productsImportSubtitle;

  /// No description provided for @productsBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcodes'**
  String get productsBarcodeTitle;

  /// No description provided for @productsBarcodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate, scan, preview, and print product barcodes.'**
  String get productsBarcodeSubtitle;

  /// No description provided for @productsBarcodeSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Search or scan to select a product.'**
  String get productsBarcodeSelectHint;

  /// No description provided for @productsBarcodeSearchResults.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsBarcodeSearchResults(int count);

  /// No description provided for @productsBarcodeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get productsBarcodeNoResults;

  /// No description provided for @productsBarcodeChangeProduct.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get productsBarcodeChangeProduct;

  /// No description provided for @productsBarcodeHasCode.
  ///
  /// In en, this message translates to:
  /// **'Has barcode'**
  String get productsBarcodeHasCode;

  /// No description provided for @productsBarcodeNoCode.
  ///
  /// In en, this message translates to:
  /// **'No barcode'**
  String get productsBarcodeNoCode;

  /// No description provided for @productsBarcodeReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace barcode?'**
  String get productsBarcodeReplaceTitle;

  /// No description provided for @productsBarcodeReplaceMessage.
  ///
  /// In en, this message translates to:
  /// **'This product already has a barcode. Generate a new one and save it?'**
  String get productsBarcodeReplaceMessage;

  /// No description provided for @productsBarcodeSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Barcode saved successfully.'**
  String get productsBarcodeSavedSuccess;

  /// No description provided for @productsBarcodeMissingForPrint.
  ///
  /// In en, this message translates to:
  /// **'Generate or assign a barcode before printing.'**
  String get productsBarcodeMissingForPrint;

  /// No description provided for @productsBarcodePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get productsBarcodePrint;

  /// No description provided for @productsBarcodeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get productsBarcodeShare;

  /// No description provided for @productsBarcodeThermalPrint.
  ///
  /// In en, this message translates to:
  /// **'Thermal printer'**
  String get productsBarcodeThermalPrint;

  /// No description provided for @productsBarcodeThermalComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Thermal printing will be available in a future update.'**
  String get productsBarcodeThermalComingSoon;

  /// No description provided for @productsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code, name, or barcode'**
  String get productsSearchHint;

  /// No description provided for @catalogSearchFieldAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogSearchFieldAll;

  /// No description provided for @catalogSearchFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catalogSearchFieldName;

  /// No description provided for @catalogSearchFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get catalogSearchFieldCode;

  /// No description provided for @catalogSearchFieldBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get catalogSearchFieldBarcode;

  /// No description provided for @catalogSearchHintName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get catalogSearchHintName;

  /// No description provided for @catalogSearchHintCode.
  ///
  /// In en, this message translates to:
  /// **'Search by code'**
  String get catalogSearchHintCode;

  /// No description provided for @catalogSearchHintBarcode.
  ///
  /// In en, this message translates to:
  /// **'Search by barcode'**
  String get catalogSearchHintBarcode;

  /// No description provided for @catalogSearchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get catalogSearchFilterLabel;

  /// No description provided for @productsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsEmptyTitle;

  /// No description provided for @productsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a product manually or import an Excel catalog.'**
  String get productsEmptyMessage;

  /// No description provided for @productsGoToImport.
  ///
  /// In en, this message translates to:
  /// **'Go to import'**
  String get productsGoToImport;

  /// No description provided for @productsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productsAdd;

  /// No description provided for @productsViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get productsViewList;

  /// No description provided for @productsViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get productsViewGrid;

  /// No description provided for @productsViewModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change product layout'**
  String get productsViewModeTooltip;

  /// No description provided for @productsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsEdit;

  /// No description provided for @productsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get productsDelete;

  /// No description provided for @productsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get productsDeleteConfirmTitle;

  /// No description provided for @productsDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the product from the catalog. Stock-count data is not changed.'**
  String get productsDeleteConfirmMessage;

  /// No description provided for @productsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully.'**
  String get productsSavedSuccess;

  /// No description provided for @productsDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productsDeletedSuccess;

  /// No description provided for @productsDuplicateCode.
  ///
  /// In en, this message translates to:
  /// **'A product with this item code already exists.'**
  String get productsDuplicateCode;

  /// No description provided for @productsDuplicateBarcode.
  ///
  /// In en, this message translates to:
  /// **'A product with this barcode already exists.'**
  String get productsDuplicateBarcode;

  /// No description provided for @productsInvalidForm.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid code, name, pack size, and price.'**
  String get productsInvalidForm;

  /// No description provided for @productsItemCodeAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Generated automatically and cannot be edited.'**
  String get productsItemCodeAutoHint;

  /// No description provided for @productsFieldLockedHint.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be edited.'**
  String get productsFieldLockedHint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12.50'**
  String get priceRequiredHint;

  /// No description provided for @productsImportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import products'**
  String get productsImportPageTitle;

  /// No description provided for @productsImportFormatHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Products Excel layout'**
  String get productsImportFormatHintTitle;

  /// No description provided for @productsImportFormatHintIntro.
  ///
  /// In en, this message translates to:
  /// **'First row = headers. Required columns only. Use .xlsx or .xls.'**
  String get productsImportFormatHintIntro;

  /// No description provided for @productsImportFormatColPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productsImportFormatColPrice;

  /// No description provided for @productsImportFormatColPriceAliases.
  ///
  /// In en, this message translates to:
  /// **'Price · Unit Price · السعر'**
  String get productsImportFormatColPriceAliases;

  /// No description provided for @productsImportFormatColPackAliases.
  ///
  /// In en, this message translates to:
  /// **'Pack Size · Pack · العبوة'**
  String get productsImportFormatColPackAliases;

  /// No description provided for @productsImportFormatSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Without headers, columns are read as: code, name, pack size, price.'**
  String get productsImportFormatSampleNote;

  /// No description provided for @productsImportFormatSamplePriceHeader.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productsImportFormatSamplePriceHeader;

  /// No description provided for @productsImportInsertedCount.
  ///
  /// In en, this message translates to:
  /// **'Inserted {count} products'**
  String productsImportInsertedCount(int count);

  /// No description provided for @productsImportUpdatedCount.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} products'**
  String productsImportUpdatedCount(int count);

  /// No description provided for @productsNoValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid product rows were found in the file.'**
  String get productsNoValidRows;

  /// No description provided for @productsScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or QR'**
  String get productsScanBarcode;

  /// No description provided for @productsScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get productsScanAction;

  /// No description provided for @productsScannerAlignHint.
  ///
  /// In en, this message translates to:
  /// **'Align barcode or QR code here'**
  String get productsScannerAlignHint;

  /// No description provided for @productsScannerScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get productsScannerScanning;

  /// No description provided for @productsScannerDetected.
  ///
  /// In en, this message translates to:
  /// **'Code detected'**
  String get productsScannerDetected;

  /// No description provided for @productsScannerProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get productsScannerProcessing;

  /// No description provided for @productsScannerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Unsupported code'**
  String get productsScannerInvalid;

  /// No description provided for @productsGenerateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get productsGenerateBarcode;

  /// No description provided for @productsGenerateBarcodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate a unique barcode value'**
  String get productsGenerateBarcodeTooltip;

  /// No description provided for @productsBarcodePreview.
  ///
  /// In en, this message translates to:
  /// **'Barcode preview'**
  String get productsBarcodePreview;

  /// No description provided for @productsBarcodeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode type'**
  String get productsBarcodeTypeLabel;

  /// No description provided for @productsBarcodeFormatBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get productsBarcodeFormatBarcode;

  /// No description provided for @productsBarcodeFormatQr.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get productsBarcodeFormatQr;

  /// No description provided for @productsQrCodePreview.
  ///
  /// In en, this message translates to:
  /// **'QR Code preview'**
  String get productsQrCodePreview;

  /// No description provided for @productsGenerateQrCode.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get productsGenerateQrCode;

  /// No description provided for @productsSaveQrCode.
  ///
  /// In en, this message translates to:
  /// **'Save QR Code'**
  String get productsSaveQrCode;

  /// No description provided for @productsShareQrCode.
  ///
  /// In en, this message translates to:
  /// **'Share QR Code'**
  String get productsShareQrCode;

  /// No description provided for @productsInvalidProductData.
  ///
  /// In en, this message translates to:
  /// **'Invalid product data'**
  String get productsInvalidProductData;

  /// No description provided for @productsQrScanRecognized.
  ///
  /// In en, this message translates to:
  /// **'Product loaded from QR Code'**
  String get productsQrScanRecognized;

  /// No description provided for @productsQrScanOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Product shown from QR data (not found in catalog)'**
  String get productsQrScanOfflineData;

  /// No description provided for @productsQrProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productsQrProductDetails;

  /// No description provided for @productsCodesSection.
  ///
  /// In en, this message translates to:
  /// **'Product codes'**
  String get productsCodesSection;

  /// No description provided for @productsPrintBarcode.
  ///
  /// In en, this message translates to:
  /// **'Print barcode'**
  String get productsPrintBarcode;

  /// No description provided for @productsPrintQr.
  ///
  /// In en, this message translates to:
  /// **'Print QR Code'**
  String get productsPrintQr;

  /// No description provided for @productsBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for this barcode.'**
  String get productsBarcodeNotFound;

  /// No description provided for @productsCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan barcodes.'**
  String get productsCameraPermissionDenied;

  /// No description provided for @productsCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is not available on this device.'**
  String get productsCameraUnavailable;

  /// No description provided for @productsEnterBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the barcode manually, or use camera scan on Android/iOS after a full app restart.'**
  String get productsEnterBarcodeHint;

  /// No description provided for @inventoryOpenStockCount.
  ///
  /// In en, this message translates to:
  /// **'Open stock count'**
  String get inventoryOpenStockCount;

  /// No description provided for @inventoryCustomizeServices.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get inventoryCustomizeServices;

  /// No description provided for @inventoryCustomizeServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose services to show, then drag to change their order.'**
  String get inventoryCustomizeServicesHint;

  /// No description provided for @inventorySaveServices.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get inventorySaveServices;

  /// No description provided for @inventoryPinnedServices.
  ///
  /// In en, this message translates to:
  /// **'Pinned services'**
  String get inventoryPinnedServices;

  /// No description provided for @inventoryAvailableServices.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get inventoryAvailableServices;

  /// No description provided for @inventoryAddService.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get inventoryAddService;

  /// No description provided for @inventoryRemoveService.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get inventoryRemoveService;

  /// No description provided for @inventoryNoServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No services on inventory home'**
  String get inventoryNoServicesTitle;

  /// No description provided for @inventoryNoServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize to pin the inventory services you use most.'**
  String get inventoryNoServicesMessage;

  /// No description provided for @inventoryNoServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No inventory services are available yet.'**
  String get inventoryNoServicesAvailable;

  /// No description provided for @modulePlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'This module is registered and ready. Business features will be added in the next stages.'**
  String get modulePlaceholderMessage;

  /// No description provided for @inventoryOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get inventoryOverview;

  /// No description provided for @inventoryCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get inventoryCountTitle;

  /// No description provided for @inventoryCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search items and enter counted quantities.'**
  String get inventoryCountSubtitle;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search Items'**
  String get searchItems;

  /// No description provided for @searchItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code'**
  String get searchItemsHint;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String searchResultsCount(int count);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noItemSelected.
  ///
  /// In en, this message translates to:
  /// **'No item selected'**
  String get noItemSelected;

  /// No description provided for @saveCount.
  ///
  /// In en, this message translates to:
  /// **'Save Count'**
  String get saveCount;

  /// No description provided for @editCount.
  ///
  /// In en, this message translates to:
  /// **'Edit Count'**
  String get editCount;

  /// No description provided for @editCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Count'**
  String get editCountTitle;

  /// No description provided for @editCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the new count quantities.'**
  String get editCountSubtitle;

  /// No description provided for @countSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Count saved successfully.'**
  String get countSavedSuccess;

  /// No description provided for @negativeQuantityNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Negative quantities are not allowed.'**
  String get negativeQuantityNotAllowed;

  /// No description provided for @packSize.
  ///
  /// In en, this message translates to:
  /// **'Pack Size'**
  String get packSize;

  /// No description provided for @packSizeMissingWarning.
  ///
  /// In en, this message translates to:
  /// **'This product has no pack size. Enter the pack size before counting.'**
  String get packSizeMissingWarning;

  /// No description provided for @packSizeIncompleteMarkerWarning.
  ///
  /// In en, this message translates to:
  /// **'The product name has * without a pack number. Enter the pack size to continue.'**
  String get packSizeIncompleteMarkerWarning;

  /// No description provided for @packSizeInvalidWarning.
  ///
  /// In en, this message translates to:
  /// **'The pack size in the product name is invalid. Enter a valid pack size.'**
  String get packSizeInvalidWarning;

  /// No description provided for @packSizeRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 24'**
  String get packSizeRequiredHint;

  /// No description provided for @savePackSize.
  ///
  /// In en, this message translates to:
  /// **'Save Pack Size'**
  String get savePackSize;

  /// No description provided for @packSizeSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pack size saved successfully.'**
  String get packSizeSavedSuccess;

  /// No description provided for @packSizeRequiredBeforeCount.
  ///
  /// In en, this message translates to:
  /// **'Enter the pack size before counting.'**
  String get packSizeRequiredBeforeCount;

  /// No description provided for @invalidPackSize.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid pack size greater than zero.'**
  String get invalidPackSize;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @mainQuantity.
  ///
  /// In en, this message translates to:
  /// **'Main Quantity'**
  String get mainQuantity;

  /// No description provided for @subQuantity.
  ///
  /// In en, this message translates to:
  /// **'Sub Quantity'**
  String get subQuantity;

  /// No description provided for @systemQuantity.
  ///
  /// In en, this message translates to:
  /// **'System Quantity'**
  String get systemQuantity;

  /// No description provided for @actualQuantity.
  ///
  /// In en, this message translates to:
  /// **'Actual Quantity'**
  String get actualQuantity;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @countDetails.
  ///
  /// In en, this message translates to:
  /// **'Count Details'**
  String get countDetails;

  /// No description provided for @shortageQuantity.
  ///
  /// In en, this message translates to:
  /// **'Shortage Quantity'**
  String get shortageQuantity;

  /// No description provided for @overageQuantity.
  ///
  /// In en, this message translates to:
  /// **'Overage Quantity'**
  String get overageQuantity;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @countedItems.
  ///
  /// In en, this message translates to:
  /// **'Counted Items'**
  String get countedItems;

  /// No description provided for @remainingItems.
  ///
  /// In en, this message translates to:
  /// **'Remaining Items'**
  String get remainingItems;

  /// No description provided for @matched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matched;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @overage.
  ///
  /// In en, this message translates to:
  /// **'Overage'**
  String get overage;

  /// No description provided for @matchedStatus.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matchedStatus;

  /// No description provided for @shortageStatus.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortageStatus;

  /// No description provided for @overageStatus.
  ///
  /// In en, this message translates to:
  /// **'Overage'**
  String get overageStatus;

  /// No description provided for @notCountedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Counted'**
  String get notCountedStatus;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get allItems;

  /// No description provided for @matchedItems.
  ///
  /// In en, this message translates to:
  /// **'Matched Items'**
  String get matchedItems;

  /// No description provided for @shortageItems.
  ///
  /// In en, this message translates to:
  /// **'Shortages'**
  String get shortageItems;

  /// No description provided for @overageItems.
  ///
  /// In en, this message translates to:
  /// **'Overages'**
  String get overageItems;

  /// No description provided for @notCountedItems.
  ///
  /// In en, this message translates to:
  /// **'Not Counted Items'**
  String get notCountedItems;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or import inventory first.'**
  String get emptyStateSubtitle;

  /// No description provided for @inventoryEmptyNeedsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory items yet'**
  String get inventoryEmptyNeedsImportTitle;

  /// No description provided for @inventoryEmptyNeedsImportMessage.
  ///
  /// In en, this message translates to:
  /// **'Import an Excel list to start counting and viewing reports.'**
  String get inventoryEmptyNeedsImportMessage;

  /// No description provided for @inventoryGoToImport.
  ///
  /// In en, this message translates to:
  /// **'Go to Import'**
  String get inventoryGoToImport;

  /// No description provided for @importPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Inventory'**
  String get importPageTitle;

  /// No description provided for @selectExcelFile.
  ///
  /// In en, this message translates to:
  /// **'Select Excel File'**
  String get selectExcelFile;

  /// No description provided for @selectedFileName.
  ///
  /// In en, this message translates to:
  /// **'Selected File'**
  String get selectedFileName;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importFormatHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Excel file layout'**
  String get importFormatHintTitle;

  /// No description provided for @importFormatHintIntro.
  ///
  /// In en, this message translates to:
  /// **'First row = headers. Use .xlsx or .xls.'**
  String get importFormatHintIntro;

  /// No description provided for @importFormatRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get importFormatRequired;

  /// No description provided for @importFormatOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get importFormatOptional;

  /// No description provided for @importFormatColCode.
  ///
  /// In en, this message translates to:
  /// **'Item code'**
  String get importFormatColCode;

  /// No description provided for @importFormatColCodeAliases.
  ///
  /// In en, this message translates to:
  /// **'Item Code · Code · رقم السلعة'**
  String get importFormatColCodeAliases;

  /// No description provided for @importFormatColName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get importFormatColName;

  /// No description provided for @importFormatColNameAliases.
  ///
  /// In en, this message translates to:
  /// **'Item Name · Name · اسم السلعة'**
  String get importFormatColNameAliases;

  /// No description provided for @importFormatColMainQty.
  ///
  /// In en, this message translates to:
  /// **'Main quantity'**
  String get importFormatColMainQty;

  /// No description provided for @importFormatColMainQtyAliases.
  ///
  /// In en, this message translates to:
  /// **'Main Quantity · الكمية الرئيسية'**
  String get importFormatColMainQtyAliases;

  /// No description provided for @importFormatColSubQty.
  ///
  /// In en, this message translates to:
  /// **'Sub quantity'**
  String get importFormatColSubQty;

  /// No description provided for @importFormatColSubQtyAliases.
  ///
  /// In en, this message translates to:
  /// **'Sub Quantity · الكمية الفرعية'**
  String get importFormatColSubQtyAliases;

  /// No description provided for @importFormatColBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get importFormatColBarcode;

  /// No description provided for @importFormatColBarcodeAliases.
  ///
  /// In en, this message translates to:
  /// **'Barcode · الباركود'**
  String get importFormatColBarcodeAliases;

  /// No description provided for @importFormatColPack.
  ///
  /// In en, this message translates to:
  /// **'Pack size'**
  String get importFormatColPack;

  /// No description provided for @importFormatColPackAliases.
  ///
  /// In en, this message translates to:
  /// **'Pack Size · حجم العبوة'**
  String get importFormatColPackAliases;

  /// No description provided for @importFormatSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get importFormatSampleTitle;

  /// No description provided for @importFormatSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Without headers, columns are read as: code, name, main qty, sub qty.'**
  String get importFormatSampleNote;

  /// No description provided for @importFormatSampleCodeHeader.
  ///
  /// In en, this message translates to:
  /// **'Item Code'**
  String get importFormatSampleCodeHeader;

  /// No description provided for @importFormatSampleNameHeader.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get importFormatSampleNameHeader;

  /// No description provided for @importFormatSampleMainHeader.
  ///
  /// In en, this message translates to:
  /// **'Main Qty'**
  String get importFormatSampleMainHeader;

  /// No description provided for @importFormatSampleSubHeader.
  ///
  /// In en, this message translates to:
  /// **'Sub Qty'**
  String get importFormatSampleSubHeader;

  /// No description provided for @importFormatSamplePackHeader.
  ///
  /// In en, this message translates to:
  /// **'Pack Size'**
  String get importFormatSamplePackHeader;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed successfully.'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed.'**
  String get importFailed;

  /// No description provided for @importedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} items'**
  String importedItemsCount(int count);

  /// No description provided for @ignoredRowsCount.
  ///
  /// In en, this message translates to:
  /// **'Ignored {count} rows'**
  String ignoredRowsCount(int count);

  /// No description provided for @invalidFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid Excel file.'**
  String get invalidFile;

  /// No description provided for @fileSelectedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select an Excel file to continue.'**
  String get fileSelectedPrompt;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report exported successfully.'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report export failed.'**
  String get exportFailed;

  /// No description provided for @exportNoItems.
  ///
  /// In en, this message translates to:
  /// **'There are no items to print for the current filter.'**
  String get exportNoItems;

  /// No description provided for @exportDataNotReady.
  ///
  /// In en, this message translates to:
  /// **'Inventory data is not ready yet. Please wait and try again.'**
  String get exportDataNotReady;

  /// No description provided for @inventoryReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Report'**
  String get inventoryReportTitle;

  /// No description provided for @systemMainQuantity.
  ///
  /// In en, this message translates to:
  /// **'System Main Qty'**
  String get systemMainQuantity;

  /// No description provided for @systemSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'System Sub Qty'**
  String get systemSubQuantity;

  /// No description provided for @countedMainQuantity.
  ///
  /// In en, this message translates to:
  /// **'Counted Main Qty'**
  String get countedMainQuantity;

  /// No description provided for @countedSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'Counted Sub Qty'**
  String get countedSubQuantity;

  /// No description provided for @varianceQuantity.
  ///
  /// In en, this message translates to:
  /// **'Shortage / Overage'**
  String get varianceQuantity;

  /// No description provided for @varianceMainQuantity.
  ///
  /// In en, this message translates to:
  /// **'Main Shortage/Overage'**
  String get varianceMainQuantity;

  /// No description provided for @varianceSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'Sub Shortage/Overage'**
  String get varianceSubQuantity;

  /// No description provided for @reportSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get reportSection;

  /// No description provided for @generatedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generatedAt;

  /// No description provided for @inventorySheetName.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventorySheetName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @setupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup settings'**
  String get setupSettingsTitle;

  /// No description provided for @setupSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure company identity, logo, default currency, and related business details.'**
  String get setupSettingsSubtitle;

  /// No description provided for @setupSettingsCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Company name, logo, currency, and legal details.'**
  String get setupSettingsCardSubtitle;

  /// No description provided for @moduleSystemSetup.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moduleSystemSetup;

  /// No description provided for @moduleSystemSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Company, modules, language, currency, and system initialization.'**
  String get moduleSystemSetupDescription;

  /// No description provided for @systemSettingsHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage company details and settings for every business module.'**
  String get systemSettingsHubSubtitle;

  /// No description provided for @systemSetupInitializationSection.
  ///
  /// In en, this message translates to:
  /// **'System initialization'**
  String get systemSetupInitializationSection;

  /// No description provided for @systemSetupReviewSteps.
  ///
  /// In en, this message translates to:
  /// **'Review setup steps'**
  String get systemSetupReviewSteps;

  /// No description provided for @systemSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get systemSetupTitle;

  /// No description provided for @systemSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your business environment. You can resume anytime.'**
  String get systemSetupSubtitle;

  /// No description provided for @systemSetupProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Setup progress'**
  String get systemSetupProgressLabel;

  /// No description provided for @systemSetupPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String systemSetupPercent(int percent);

  /// No description provided for @systemSetupRequiredSection.
  ///
  /// In en, this message translates to:
  /// **'Required steps'**
  String get systemSetupRequiredSection;

  /// No description provided for @systemSetupOptionalSection.
  ///
  /// In en, this message translates to:
  /// **'Optional steps'**
  String get systemSetupOptionalSection;

  /// No description provided for @systemSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get systemSetupContinue;

  /// No description provided for @systemSetupRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get systemSetupRetry;

  /// No description provided for @systemSetupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get systemSetupSkip;

  /// No description provided for @systemSetupFinish.
  ///
  /// In en, this message translates to:
  /// **'Go to app'**
  String get systemSetupFinish;

  /// No description provided for @systemSetupEditCompany.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get systemSetupEditCompany;

  /// No description provided for @systemSetupOpenFromSettings.
  ///
  /// In en, this message translates to:
  /// **'System initialization'**
  String get systemSetupOpenFromSettings;

  /// No description provided for @systemSetupOpenFromSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review setup progress or re-run initialization steps.'**
  String get systemSetupOpenFromSettingsSubtitle;

  /// No description provided for @systemSetupStepWelcome.
  ///
  /// In en, this message translates to:
  /// **'Deployment mode'**
  String get systemSetupStepWelcome;

  /// No description provided for @systemSetupStepWelcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose standalone local accounting or connection to an external system.'**
  String get systemSetupStepWelcomeHint;

  /// No description provided for @systemSetupStepCompany.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get systemSetupStepCompany;

  /// No description provided for @systemSetupStepCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Company name and fiscal year start.'**
  String get systemSetupStepCompanyHint;

  /// No description provided for @systemSetupStepLocale.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get systemSetupStepLocale;

  /// No description provided for @systemSetupStepLocaleHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language or keep the device default.'**
  String get systemSetupStepLocaleHint;

  /// No description provided for @systemSetupStepPrimaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get systemSetupStepPrimaryCurrency;

  /// No description provided for @systemSetupStepPrimaryCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the main system currency. This cannot be changed later.'**
  String get systemSetupStepPrimaryCurrencyHint;

  /// No description provided for @systemSetupCurrencyLocked.
  ///
  /// In en, this message translates to:
  /// **'Base currency is locked and cannot be changed.'**
  String get systemSetupCurrencyLocked;

  /// No description provided for @systemSetupStepSeed.
  ///
  /// In en, this message translates to:
  /// **'Local defaults'**
  String get systemSetupStepSeed;

  /// No description provided for @systemSetupStepSeedHint.
  ///
  /// In en, this message translates to:
  /// **'Create the default chart of accounts and voucher books.'**
  String get systemSetupStepSeedHint;

  /// No description provided for @systemSetupStepExternal.
  ///
  /// In en, this message translates to:
  /// **'External connection'**
  String get systemSetupStepExternal;

  /// No description provided for @systemSetupStepExternalHint.
  ///
  /// In en, this message translates to:
  /// **'Configure an ERP connection when using integrated mode.'**
  String get systemSetupStepExternalHint;

  /// No description provided for @systemSetupStepSync.
  ///
  /// In en, this message translates to:
  /// **'Initial sync'**
  String get systemSetupStepSync;

  /// No description provided for @systemSetupStepSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Run a synchronization pass when a remote backend is available.'**
  String get systemSetupStepSyncHint;

  /// No description provided for @systemSetupModeStandalone.
  ///
  /// In en, this message translates to:
  /// **'Standalone'**
  String get systemSetupModeStandalone;

  /// No description provided for @systemSetupModeStandaloneHint.
  ///
  /// In en, this message translates to:
  /// **'This app owns local accounting data and journals.'**
  String get systemSetupModeStandaloneHint;

  /// No description provided for @systemSetupModeIntegrated.
  ///
  /// In en, this message translates to:
  /// **'Integrated'**
  String get systemSetupModeIntegrated;

  /// No description provided for @systemSetupModeIntegratedHint.
  ///
  /// In en, this message translates to:
  /// **'Operate beside an existing accounting/ERP system.'**
  String get systemSetupModeIntegratedHint;

  /// No description provided for @systemSetupLocaleSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get systemSetupLocaleSystem;

  /// No description provided for @systemSetupLocaleEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get systemSetupLocaleEnglish;

  /// No description provided for @systemSetupLocaleArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get systemSetupLocaleArabic;

  /// No description provided for @systemSetupSeedRunning.
  ///
  /// In en, this message translates to:
  /// **'Preparing local defaults…'**
  String get systemSetupSeedRunning;

  /// No description provided for @systemSetupSeedDone.
  ///
  /// In en, this message translates to:
  /// **'Default accounts and voucher books are ready.'**
  String get systemSetupSeedDone;

  /// No description provided for @systemSetupExternalPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'External ERP adapters are registered by the App layer. You can skip this and connect later from Settings.'**
  String get systemSetupExternalPlaceholder;

  /// No description provided for @systemSetupSyncRunning.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing…'**
  String get systemSetupSyncRunning;

  /// No description provided for @systemSetupSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Sync finished.'**
  String get systemSetupSyncDone;

  /// No description provided for @systemSetupSyncSkippedHint.
  ///
  /// In en, this message translates to:
  /// **'You can sync anytime from Settings.'**
  String get systemSetupSyncSkippedHint;

  /// No description provided for @systemSetupStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get systemSetupStatusPending;

  /// No description provided for @systemSetupStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get systemSetupStatusInProgress;

  /// No description provided for @systemSetupStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get systemSetupStatusCompleted;

  /// No description provided for @systemSetupStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get systemSetupStatusFailed;

  /// No description provided for @systemSetupStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get systemSetupStatusSkipped;

  /// No description provided for @systemSetupReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready'**
  String get systemSetupReadyTitle;

  /// No description provided for @systemSetupReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Required setup is complete. Optional steps can be finished later.'**
  String get systemSetupReadyMessage;

  /// No description provided for @systemSetupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'This step failed. Fix the issue and retry.'**
  String get systemSetupErrorGeneric;

  /// No description provided for @setupCompanyIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'Company identity'**
  String get setupCompanyIdentitySection;

  /// No description provided for @setupCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get setupCompanyName;

  /// No description provided for @setupCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required.'**
  String get setupCompanyNameRequired;

  /// No description provided for @setupLegalName.
  ///
  /// In en, this message translates to:
  /// **'Legal name'**
  String get setupLegalName;

  /// No description provided for @setupLegalNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Official registered name if different from the display name.'**
  String get setupLegalNameHelper;

  /// No description provided for @setupPickLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose logo'**
  String get setupPickLogo;

  /// No description provided for @setupRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove logo'**
  String get setupRemoveLogo;

  /// No description provided for @setupLogoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Company logo updated.'**
  String get setupLogoUpdated;

  /// No description provided for @setupLogoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Company logo removed.'**
  String get setupLogoRemoved;

  /// No description provided for @setupLogoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the logo. Try another image.'**
  String get setupLogoFailed;

  /// No description provided for @setupCurrencySection.
  ///
  /// In en, this message translates to:
  /// **'Currency & fiscal year'**
  String get setupCurrencySection;

  /// No description provided for @setupCurrencySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used as the default for amounts, invoices, and reports.'**
  String get setupCurrencySectionSubtitle;

  /// No description provided for @setupDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get setupDefaultCurrency;

  /// No description provided for @setupFiscalYearStart.
  ///
  /// In en, this message translates to:
  /// **'Fiscal year starts in'**
  String get setupFiscalYearStart;

  /// No description provided for @setupFiscalYearStartHelper.
  ///
  /// In en, this message translates to:
  /// **'First month of your accounting year.'**
  String get setupFiscalYearStartHelper;

  /// No description provided for @setupLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal identifiers'**
  String get setupLegalSection;

  /// No description provided for @setupTaxNumber.
  ///
  /// In en, this message translates to:
  /// **'Tax / VAT number'**
  String get setupTaxNumber;

  /// No description provided for @setupCommercialRegister.
  ///
  /// In en, this message translates to:
  /// **'Commercial registration'**
  String get setupCommercialRegister;

  /// No description provided for @setupContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact & address'**
  String get setupContactSection;

  /// No description provided for @setupPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get setupPhone;

  /// No description provided for @setupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get setupEmail;

  /// No description provided for @setupWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get setupWebsite;

  /// No description provided for @setupAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get setupAddress;

  /// No description provided for @setupCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get setupCity;

  /// No description provided for @setupCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get setupCountry;

  /// No description provided for @setupInvoiceHeaderSection.
  ///
  /// In en, this message translates to:
  /// **'Sales invoice header'**
  String get setupInvoiceHeaderSection;

  /// No description provided for @setupInvoiceHeaderSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Text for the right and left columns around the company logo on printed invoices.'**
  String get setupInvoiceHeaderSectionSubtitle;

  /// No description provided for @setupInvoiceHeaderRight.
  ///
  /// In en, this message translates to:
  /// **'Right column text'**
  String get setupInvoiceHeaderRight;

  /// No description provided for @setupInvoiceHeaderLeft.
  ///
  /// In en, this message translates to:
  /// **'Left column text'**
  String get setupInvoiceHeaderLeft;

  /// No description provided for @setupInvoiceHeaderHelper.
  ///
  /// In en, this message translates to:
  /// **'You can enter multiple lines (e.g. address or phone).'**
  String get setupInvoiceHeaderHelper;

  /// No description provided for @setupSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Setup settings saved.'**
  String get setupSavedSuccess;

  /// No description provided for @settingsGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralSection;

  /// No description provided for @settingsGeneralSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language for the whole app.'**
  String get settingsGeneralSectionSubtitle;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data & sync'**
  String get settingsDataSection;

  /// No description provided for @settingsDataSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connection status and manual synchronization.'**
  String get settingsDataSectionSubtitle;

  /// No description provided for @settingsModulesSection.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get settingsModulesSection;

  /// No description provided for @settingsModulesSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings owned by each business module.'**
  String get settingsModulesSectionSubtitle;

  /// No description provided for @settingsAboutSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Application identity and maintenance.'**
  String get settingsAboutSectionSubtitle;

  /// No description provided for @settingsResetHint.
  ///
  /// In en, this message translates to:
  /// **'Restore theme, language, and module settings to defaults.'**
  String get settingsResetHint;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @applicationName.
  ///
  /// In en, this message translates to:
  /// **'Application Name'**
  String get applicationName;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @resetApplication.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetApplication;

  /// No description provided for @resetApplicationConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get resetApplicationConfirmationTitle;

  /// No description provided for @resetApplicationConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Theme and language preferences will be restored to defaults.'**
  String get resetApplicationConfirmationMessage;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @notificationsUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnreadBadge;

  /// No description provided for @notificationsSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications'**
  String notificationsSummaryTotal(int count);

  /// No description provided for @notificationsSummaryUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsSummaryUnread(int count);

  /// No description provided for @notificationsSummaryAllRead.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notificationsSummaryAllRead;

  /// No description provided for @notificationsTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsTimeJustNow;

  /// No description provided for @notificationsTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String notificationsTimeMinutes(int count);

  /// No description provided for @notificationsTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String notificationsTimeHours(int count);

  /// No description provided for @notificationsTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String notificationsTimeDays(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Application?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get exitAppMessage;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitAppConfirm;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business Management Platform'**
  String get splashSubtitle;

  /// No description provided for @splashInitErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start application'**
  String get splashInitErrorTitle;

  /// No description provided for @splashInitErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while initializing the application.'**
  String get splashInitErrorMessage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @errorStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again. If the problem continues, check your data and return later.'**
  String get errorStateSubtitle;

  /// No description provided for @moduleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get moduleComingSoon;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navigationDashboard;

  /// No description provided for @navigationServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navigationServices;

  /// No description provided for @navigationReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navigationReports;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsTitle;

  /// No description provided for @quickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your pinned shortcuts. Customize to add or reorder.'**
  String get quickActionsSubtitle;

  /// No description provided for @quickActionsCreateProduct.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get quickActionsCreateProduct;

  /// No description provided for @quickActionsCreateProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the new product form.'**
  String get quickActionsCreateProductSubtitle;

  /// No description provided for @quickActionsScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or QR'**
  String get quickActionsScanBarcode;

  /// No description provided for @quickActionsScanBarcodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or QR and open the product.'**
  String get quickActionsScanBarcodeSubtitle;

  /// No description provided for @quickActionsCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get quickActionsCustomize;

  /// No description provided for @quickActionsCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize quick actions'**
  String get quickActionsCustomizeTitle;

  /// No description provided for @quickActionsCustomizeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose actions to show, then drag to change their order.'**
  String get quickActionsCustomizeHint;

  /// No description provided for @quickActionsPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned actions'**
  String get quickActionsPinned;

  /// No description provided for @quickActionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available actions'**
  String get quickActionsAvailable;

  /// No description provided for @quickActionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get quickActionsAdd;

  /// No description provided for @quickActionsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get quickActionsRemove;

  /// No description provided for @quickActionsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quickActionsSave;

  /// No description provided for @quickActionsPinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} pinned'**
  String quickActionsPinnedCount(int count, int max);

  /// No description provided for @quickActionsMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You can pin up to {max} quick actions.'**
  String quickActionsMaxReached(int max);

  /// No description provided for @quickActionsEmptyPinned.
  ///
  /// In en, this message translates to:
  /// **'No shortcuts pinned yet. Tap Customize to add some.'**
  String get quickActionsEmptyPinned;

  /// No description provided for @quickActionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin shortcuts here for faster access. You will be able to customize them later.'**
  String get quickActionsEmptyMessage;

  /// No description provided for @quickActionsAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get quickActionsAddLabel;

  /// No description provided for @quickActionsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Quick action customization is coming soon.'**
  String get quickActionsComingSoon;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overview of your business platform.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardOpenServices.
  ///
  /// In en, this message translates to:
  /// **'Browse all services'**
  String get dashboardOpenServices;

  /// No description provided for @dashboardOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get dashboardOpenSettings;

  /// No description provided for @dashboardMyServices.
  ///
  /// In en, this message translates to:
  /// **'My services'**
  String get dashboardMyServices;

  /// No description provided for @dashboardCustomizeServices.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get dashboardCustomizeServices;

  /// No description provided for @dashboardCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize dashboard services'**
  String get dashboardCustomizeTitle;

  /// No description provided for @dashboardCustomizeServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which services appear on your dashboard, then drag to reorder.'**
  String get dashboardCustomizeServicesHint;

  /// No description provided for @dashboardPinnedServices.
  ///
  /// In en, this message translates to:
  /// **'Pinned services'**
  String get dashboardPinnedServices;

  /// No description provided for @dashboardAvailableServices.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get dashboardAvailableServices;

  /// No description provided for @dashboardAddService.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dashboardAddService;

  /// No description provided for @dashboardRemoveService.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dashboardRemoveService;

  /// No description provided for @dashboardSaveServices.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dashboardSaveServices;

  /// No description provided for @dashboardPinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} pinned'**
  String dashboardPinnedCount(int count, int max);

  /// No description provided for @dashboardServicesMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You can pin up to {max} dashboard services.'**
  String dashboardServicesMaxReached(int max);

  /// No description provided for @dashboardNoServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No services on dashboard'**
  String get dashboardNoServicesTitle;

  /// No description provided for @dashboardNoServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize your dashboard to add the services you use most.'**
  String get dashboardNoServicesMessage;

  /// No description provided for @dashboardNoModulesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services are available yet.'**
  String get dashboardNoModulesAvailable;

  /// No description provided for @dashboardStatsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get dashboardStatsComingSoon;

  /// No description provided for @dashboardStatsSlideOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get dashboardStatsSlideOverviewTitle;

  /// No description provided for @dashboardStatsSlideOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily performance indicators will appear here.'**
  String get dashboardStatsSlideOverviewSubtitle;

  /// No description provided for @dashboardStatsSlideSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get dashboardStatsSlideSalesTitle;

  /// No description provided for @dashboardStatsSlideSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales summaries by period will be added later.'**
  String get dashboardStatsSlideSalesSubtitle;

  /// No description provided for @dashboardStatsSlideBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get dashboardStatsSlideBalanceTitle;

  /// No description provided for @dashboardStatsSlideBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer and cash balances are coming soon.'**
  String get dashboardStatsSlideBalanceSubtitle;

  /// No description provided for @dashboardStatsPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardStatsPeriodToday;

  /// No description provided for @dashboardStatsPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashboardStatsPeriodWeek;

  /// No description provided for @dashboardStatsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardStatsPeriodMonth;

  /// No description provided for @dashboardStatsCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'YER'**
  String get dashboardStatsCurrencyHint;

  /// No description provided for @dashboardStatsItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get dashboardStatsItemsLabel;

  /// No description provided for @dashboardStatsInvoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get dashboardStatsInvoicesLabel;

  /// No description provided for @dashboardStatsCustomersLabel.
  ///
  /// In en, this message translates to:
  /// **'Active customers'**
  String get dashboardStatsCustomersLabel;

  /// No description provided for @dashboardStatsLowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get dashboardStatsLowStockLabel;

  /// No description provided for @dashboardRecentOperations.
  ///
  /// In en, this message translates to:
  /// **'Recent operations'**
  String get dashboardRecentOperations;

  /// No description provided for @dashboardRecentOperationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent sales yet.'**
  String get dashboardRecentOperationsEmpty;

  /// No description provided for @dashboardRecentOperationsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardRecentOperationsViewAll;

  /// No description provided for @dashboardRecentSaleInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sales invoice'**
  String get dashboardRecentSaleInvoice;

  /// No description provided for @dashboardRecentSaleInvoiceLine.
  ///
  /// In en, this message translates to:
  /// **'Sales invoice {type} No. {number}'**
  String dashboardRecentSaleInvoiceLine(String type, String number);

  /// No description provided for @platformReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get platformReportsTitle;

  /// No description provided for @platformReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a module to browse its service reports.'**
  String get platformReportsSubtitle;

  /// No description provided for @platformReportsInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory reports'**
  String get platformReportsInventory;

  /// No description provided for @platformReportsInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock count and product reports.'**
  String get platformReportsInventorySubtitle;

  /// No description provided for @platformReportsBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business PDF reports'**
  String get platformReportsBusiness;

  /// No description provided for @platformReportsBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales and cross-module PDF reports with preview.'**
  String get platformReportsBusinessSubtitle;

  /// No description provided for @platformReportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Cross-module reports will be available in a future release.'**
  String get platformReportsComingSoon;

  /// No description provided for @platformReportsStockCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock count report'**
  String get platformReportsStockCountTitle;

  /// No description provided for @platformReportsStockCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count summary, variances, and export.'**
  String get platformReportsStockCountSubtitle;

  /// No description provided for @platformReportsProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products report'**
  String get platformReportsProductsTitle;

  /// No description provided for @platformReportsServiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reports for this service are coming soon.'**
  String get platformReportsServiceComingSoon;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get notFoundMessage;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @availableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Available Quantity'**
  String get availableQuantity;

  /// No description provided for @statusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Status Breakdown'**
  String get statusBreakdown;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @exportAs.
  ///
  /// In en, this message translates to:
  /// **'Export as'**
  String get exportAs;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx)'**
  String get exportExcel;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (.pdf)'**
  String get exportPdf;

  /// No description provided for @exportPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String exportPath(String path);

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareExport;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @paginationPage.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String paginationPage(int current, int total);

  /// No description provided for @paginationRange.
  ///
  /// In en, this message translates to:
  /// **'{from}-{to} of {total}'**
  String paginationRange(int from, int to, int total);

  /// No description provided for @paginationItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Items per page'**
  String get paginationItemsPerPage;

  /// No description provided for @importParsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing Excel file...'**
  String get importParsing;

  /// No description provided for @importSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving items...'**
  String get importSaving;

  /// No description provided for @emptyWorkbook.
  ///
  /// In en, this message translates to:
  /// **'The Excel file is empty or has no sheets.'**
  String get emptyWorkbook;

  /// No description provided for @noValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid inventory rows were found in the file.'**
  String get noValidRows;

  /// No description provided for @duplicateRowsCount.
  ///
  /// In en, this message translates to:
  /// **'Replaced {count} duplicate item codes'**
  String duplicateRowsCount(int count);

  /// No description provided for @syncSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get syncSectionTitle;

  /// No description provided for @syncBackendLabel.
  ///
  /// In en, this message translates to:
  /// **'Sync backend'**
  String get syncBackendLabel;

  /// No description provided for @syncConnectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get syncConnectionLabel;

  /// No description provided for @syncConnectionOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncConnectionOnline;

  /// No description provided for @syncConnectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncConnectionOffline;

  /// No description provided for @syncLastSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Last synchronization'**
  String get syncLastSyncLabel;

  /// No description provided for @syncLastSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get syncLastSyncNever;

  /// No description provided for @syncPendingChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get syncPendingChangesLabel;

  /// No description provided for @syncFailedChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed changes'**
  String get syncFailedChangesLabel;

  /// No description provided for @syncNowAction.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNowAction;

  /// No description provided for @syncOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes will sync automatically when an internet connection is available.'**
  String get syncOfflineMessage;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get syncStatusPending;

  /// No description provided for @syncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncStatusFailed;

  /// No description provided for @syncStatusConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get syncStatusConflict;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// No description provided for @syncCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed'**
  String get syncCompletedTitle;

  /// No description provided for @syncCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'All changes have been synchronized.'**
  String get syncCompletedMessage;

  /// No description provided for @syncPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Some changes could not be synchronized'**
  String get syncPartialTitle;

  /// No description provided for @syncFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Synchronization failed'**
  String get syncFailedTitle;

  /// No description provided for @syncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get syncFailedMessage;

  /// No description provided for @loadingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get loadingPleaseWait;

  /// No description provided for @loadingProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get loadingProcessing;

  /// No description provided for @loadingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get loadingSaving;

  /// No description provided for @loadingDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get loadingDeleting;

  /// No description provided for @loadingImportingProducts.
  ///
  /// In en, this message translates to:
  /// **'Importing products…'**
  String get loadingImportingProducts;

  /// No description provided for @loadingImportingInventory.
  ///
  /// In en, this message translates to:
  /// **'Importing inventory…'**
  String get loadingImportingInventory;

  /// No description provided for @loadingSavingInventory.
  ///
  /// In en, this message translates to:
  /// **'Saving inventory…'**
  String get loadingSavingInventory;

  /// No description provided for @loadingSynchronizing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing…'**
  String get loadingSynchronizing;

  /// No description provided for @loadingExportingReport.
  ///
  /// In en, this message translates to:
  /// **'Preparing report…'**
  String get loadingExportingReport;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
