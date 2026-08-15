// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NexaBiz';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesSubtitle => 'Choose a business module to get started.';

  @override
  String get moduleInventory => 'Inventory';

  @override
  String get moduleInventoryDescription =>
      'Inventory services including stock count, and more over time.';

  @override
  String get moduleAccounting => 'Accounting';

  @override
  String get moduleAccountingDescription =>
      'Chart of Accounts and the foundation for future ledgers and reports.';

  @override
  String get moduleCustomers => 'Customers';

  @override
  String get moduleCustomersDescription =>
      'Customer master data with optional Chart of Accounts links and external ERP ids.';

  @override
  String get moduleSales => 'Sales';

  @override
  String get moduleSalesDescription =>
      'Create and manage sales offline, with optional accounting and inventory hooks.';

  @override
  String get moduleReports => 'Reports';

  @override
  String get moduleReportsDescription =>
      'Generate, preview, print, and share professional PDF reports.';

  @override
  String get reportsSalesPeriodTitle => 'Sales by period';

  @override
  String get reportsSalesPeriodSubtitle =>
      'List sales in a date range with status filter, then preview as PDF.';

  @override
  String get reportsAccountStatementTitle => 'Account statement';

  @override
  String get reportsAccountStatementSubtitle =>
      'Print a cumulative Chart of Accounts statement in the account currency (classic layout).';

  @override
  String get reportsAccountStatementFilters => 'Statement filters';

  @override
  String get reportsAccountStatementAccount => 'Account';

  @override
  String get reportsAccountStatementAccountHint => 'Select an account';

  @override
  String get reportsAccountStatementAccountSearch => 'Search by code or name';

  @override
  String get reportsAccountStatementAccountEmpty =>
      'No posting accounts found.';

  @override
  String get reportsAccountStatementAccountRequired =>
      'Select an account first.';

  @override
  String get reportsAccountStatementAccountName => 'Account name';

  @override
  String get reportsAccountStatementAccountNumber => 'Account number';

  @override
  String get reportsAccountStatementCurrency => 'Currency';

  @override
  String get reportsAccountStatementCurrencyAll => 'All currencies';

  @override
  String get reportsAccountStatementType => 'Statement type';

  @override
  String get reportsAccountStatementTypeCumulative =>
      'Cumulative statement (account currency)';

  @override
  String get reportsAccountStatementTypeDetailed => 'Detailed statement';

  @override
  String get reportsAccountStatementTypeSummary => 'Summary statement';

  @override
  String get reportsAccountStatementPostingStatus => 'Posting status';

  @override
  String get reportsAccountStatementPostingAll => 'All';

  @override
  String get reportsAccountStatementPostingPosted => 'Posted';

  @override
  String get reportsAccountStatementPostingUnposted => 'Unposted';

  @override
  String get reportsAccountStatementFromDate => 'From date';

  @override
  String get reportsAccountStatementToDate => 'To date';

  @override
  String get reportsAccountStatementColSide => 'D/C';

  @override
  String get reportsAccountStatementColVoucherType => 'Voucher type';

  @override
  String get reportsAccountStatementColVoucherNumber => 'No.';

  @override
  String get reportsAccountStatementColDescription => 'Details';

  @override
  String get reportsAccountStatementColDebit => 'Debit';

  @override
  String get reportsAccountStatementColCredit => 'Credit';

  @override
  String get reportsAccountStatementColBalance => 'Balance';

  @override
  String get reportsAccountStatementColCurrency => 'Currency';

  @override
  String get reportsAccountStatementColInCurrency => 'In currency';

  @override
  String get reportsAccountStatementTotalsDebit => 'Debit';

  @override
  String get reportsAccountStatementTotalsCredit => 'Credit';

  @override
  String get reportsAccountStatementFinalBalanceByCurrency =>
      'Final balance by currency';

  @override
  String get reportsAccountStatementDisclaimer =>
      'This account statement is considered correct unless an objection is received within two weeks from its date.';

  @override
  String get reportsAccountStatementAccountant => 'Accountant';

  @override
  String get reportsAccountStatementReviewer => 'Reviewer';

  @override
  String get reportsAccountStatementFinanceManager => 'Finance manager:';

  @override
  String get reportsAccountStatementPrintedBy => 'NexaBiz';

  @override
  String get reportsAccountStatementEmpty =>
      'No ledger movements for this account yet. Journal entries will appear here when available.';

  @override
  String get reportsCatalogTitle => 'All PDF reports';

  @override
  String get reportsCatalogSubtitle =>
      'Open the reports catalog to generate and preview PDFs.';

  @override
  String get reportsPreviewTitle => 'Report preview';

  @override
  String get reportsPreviewMissing =>
      'No report is ready to preview. Generate a report first.';

  @override
  String get reportsActionPrint => 'Print';

  @override
  String get reportsActionShare => 'Share';

  @override
  String get reportsGeneratePreview => 'Generate & preview';

  @override
  String get reportsGenerating => 'Generating report…';

  @override
  String get reportsGeneratedAt => 'Generated';

  @override
  String get reportsPeriod => 'Period';

  @override
  String get reportsPeriodAll => 'All dates';

  @override
  String get reportsFromDate => 'From date';

  @override
  String get reportsToDate => 'To date';

  @override
  String get reportsDateAny => 'Any';

  @override
  String get reportsStatusAll => 'All statuses';

  @override
  String get reportsGrandTotal => 'Grand total';

  @override
  String get reportsRowCount => 'Rows';

  @override
  String get reportsColSaleNumber => 'Number';

  @override
  String get reportsColDate => 'Date';

  @override
  String get reportsColCustomer => 'Customer';

  @override
  String get reportsColSettlement => 'Settlement';

  @override
  String get reportsColStatus => 'Status';

  @override
  String get reportsColCurrency => 'Currency';

  @override
  String get reportsColTotal => 'Total';

  @override
  String get reportsEmptySales => 'No sales match the selected filters.';

  @override
  String get reportsErrorGeneric => 'Could not generate the report.';

  @override
  String get reportsErrorPrint => 'Printing failed.';

  @override
  String get reportsErrorShare => 'Sharing failed.';

  @override
  String get reportsErrorFile => 'Could not save the PDF file.';

  @override
  String get reportsErrorFont => 'Could not load report fonts.';

  @override
  String get salesListTitle => 'Sales';

  @override
  String get salesListCardSubtitle =>
      'Browse, search, and manage sales documents.';

  @override
  String get salesCreateTitle => 'New sale';

  @override
  String get salesCreateCardSubtitle =>
      'Start a POS-style sale with products and payment.';

  @override
  String get salesEditTitle => 'Edit sale';

  @override
  String get salesDetailsTitle => 'Invoice';

  @override
  String get salesSearchHint => 'Search by number, customer, or product';

  @override
  String get salesSearchCustomerHint => 'Search customers';

  @override
  String get salesSearchProductHint => 'Type product name';

  @override
  String get salesEmptyTitle => 'No sales yet';

  @override
  String get salesEmptyMessage => 'Create your first sale to get started.';

  @override
  String get salesCustomer => 'Customer';

  @override
  String get salesSelectCustomer => 'Select customer';

  @override
  String get salesCashCustomerHint => 'Enter a name or select a customer';

  @override
  String get salesWalkInCustomer => 'Walk-in customer';

  @override
  String get salesCustomerEmpty => 'No customers found.';

  @override
  String get salesCustomerNotFound => 'Customer not found.';

  @override
  String get salesProducts => 'Products';

  @override
  String get salesProductName => 'Product';

  @override
  String get salesAddProduct => 'Add product';

  @override
  String get salesAddRow => 'Add row';

  @override
  String get salesProductsEmpty => 'No products added.';

  @override
  String get salesProductNotFound => 'Product not found.';

  @override
  String get salesAutocompleteSearchFailed =>
      'Unable to load results. Try again.';

  @override
  String get salesRemoveItem => 'Remove item';

  @override
  String get salesScanProduct => 'Scan product';

  @override
  String get salesScanHint => 'Enter barcode or QR payload';

  @override
  String get salesUnitPrice => 'Unit price';

  @override
  String get salesSubtotal => 'Subtotal';

  @override
  String get salesDiscount => 'Discount';

  @override
  String get salesItemDiscount => 'Item discounts';

  @override
  String get salesDiscountType => 'Discount type';

  @override
  String get salesDiscountFixed => 'Fixed amount';

  @override
  String get salesDiscountPercent => 'Percentage';

  @override
  String get salesTax => 'Tax';

  @override
  String get salesTaxRate => 'Tax rate (%)';

  @override
  String get salesTotal => 'Total';

  @override
  String get salesPaid => 'Paid';

  @override
  String get salesRemaining => 'Remaining';

  @override
  String get salesPayFull => 'Pay full amount';

  @override
  String get salesPayment => 'Payment';

  @override
  String get salesPaymentMethod => 'Payment method';

  @override
  String get salesPaymentStatus => 'Payment status';

  @override
  String get salesPaymentCash => 'Cash';

  @override
  String get salesPaymentCard => 'Card';

  @override
  String get salesPaymentBankTransfer => 'Bank transfer';

  @override
  String get salesPaymentCredit => 'Credit';

  @override
  String get salesPaymentOther => 'Other';

  @override
  String get salesDate => 'Date';

  @override
  String get salesSettlementType => 'Invoice type';

  @override
  String get salesSettlementCash => 'Cash';

  @override
  String get salesSettlementCredit => 'Credit';

  @override
  String get salesSettlementCashHint => 'Collect now via cash box';

  @override
  String get salesSettlementCreditHint => 'Charge to customer account';

  @override
  String get salesVoucherBook => 'Sales book';

  @override
  String get salesSelectVoucherBook => 'Select sales book';

  @override
  String get salesVoucherBookEmpty =>
      'No sales books found. Create one in Accounting.';

  @override
  String get salesInvoiceNumber => 'Invoice number';

  @override
  String get salesCashAccount => 'Cash box account';

  @override
  String get salesSelectCashAccount => 'Select cash box account';

  @override
  String get salesCashAccountEmpty => 'No cash box accounts found.';

  @override
  String get salesCustomerAccount => 'Customer account';

  @override
  String get salesCustomerAccountMissing =>
      'Customer has no accounting account linked.';

  @override
  String get salesClearCustomer => 'Clear customer';

  @override
  String get salesCurrency => 'Currency';

  @override
  String get salesBaseCurrency => 'Base';

  @override
  String salesExchangeRateHint(String currency, String rate, String base) {
    return '1 $currency = $rate $base';
  }

  @override
  String get salesCreditHint =>
      'Credit sale — the amount is posted to the customer account. Remaining stays outstanding.';

  @override
  String get salesSearchOrScanProduct => 'Search or scan product';

  @override
  String get salesInvoiceOptions => 'Invoice options';

  @override
  String get salesItemMore => 'More';

  @override
  String get salesAddCustomer => 'Add customer';

  @override
  String get salesAdd => 'Add';

  @override
  String get salesIncreaseQty => 'Increase quantity';

  @override
  String get salesDecreaseQty => 'Decrease quantity';

  @override
  String get salesErrorCustomerRequired =>
      'Select a customer for credit sales.';

  @override
  String get salesErrorCustomerAccountRequired =>
      'Link an accounting account to the customer first.';

  @override
  String get salesErrorCashAccountRequired => 'Select a cash box account.';

  @override
  String get salesErrorVoucherBookRequired => 'Select a sales voucher book.';

  @override
  String get salesErrorCurrencyRequired => 'Select a valid currency.';

  @override
  String get salesPaymentUnpaid => 'Unpaid';

  @override
  String get salesPaymentPartiallyPaid => 'Partially paid';

  @override
  String get salesPaymentPaid => 'Paid';

  @override
  String get salesStatus => 'Sale status';

  @override
  String get salesStatusUnposted => 'Unposted';

  @override
  String get salesStatusPosted => 'Posted';

  @override
  String get salesStatusDraft => 'Unposted';

  @override
  String get salesStatusPending => 'Unposted';

  @override
  String get salesStatusConfirmed => 'Posted';

  @override
  String get salesStatusCompleted => 'Posted';

  @override
  String get salesStatusCancelled => 'Cancelled';

  @override
  String get salesStatusRejected => 'Rejected';

  @override
  String get salesNotes => 'Notes';

  @override
  String get salesSave => 'Save sale';

  @override
  String get salesSaveAndConfirm => 'Save & post';

  @override
  String get salesSaving => 'Saving sale…';

  @override
  String get salesLoadingInvoice => 'Loading invoice…';

  @override
  String get salesConfirming => 'Posting sale…';

  @override
  String get salesPosting => 'Posting…';

  @override
  String get salesSaved => 'Sale saved';

  @override
  String get salesConfirmed => 'Sale posted';

  @override
  String get salesPosted => 'Sale posted';

  @override
  String get salesCompleted => 'Sale completed';

  @override
  String get salesCancelled => 'Sale cancelled';

  @override
  String get salesDuplicated => 'Sale duplicated';

  @override
  String get salesConfirmSale => 'Post';

  @override
  String get salesPostSale => 'Post';

  @override
  String get salesCompleteSale => 'Mark completed';

  @override
  String get salesCancelSale => 'Cancel sale';

  @override
  String get salesCancelTitle => 'Cancel sale?';

  @override
  String salesCancelMessage(String saleNumber) {
    return 'Cancel $saleNumber? Inventory effects will reverse when applicable.';
  }

  @override
  String get salesDuplicate => 'Duplicate';

  @override
  String get salesPrintInvoice => 'Print';

  @override
  String get salesPreviewInvoice => 'Preview & print';

  @override
  String get salesPrintingInvoice => 'Preparing invoice preview…';

  @override
  String get salesPrintFailed => 'Could not print the invoice.';

  @override
  String get salesShareInvoice => 'Share';

  @override
  String get salesSharingInvoice => 'Preparing share…';

  @override
  String get salesShareFailed => 'Could not share the invoice.';

  @override
  String get salesInvoiceSaved => 'Invoice saved to the invoices folder.';

  @override
  String get salesNotFound => 'Sale not found';

  @override
  String get salesFiltersTitle => 'Filters';

  @override
  String get salesFilterAll => 'All';

  @override
  String get salesApplyFilters => 'Apply filters';

  @override
  String get salesClearFilters => 'Clear filters';

  @override
  String get salesSyncStatus => 'Sync status';

  @override
  String get salesExternalId => 'External id';

  @override
  String get salesExternalNumber => 'External document number';

  @override
  String get salesErrorEmptyItems => 'Add at least one product.';

  @override
  String get salesErrorInvalidQuantity => 'Quantity must be greater than zero.';

  @override
  String get salesErrorInvalidPrice => 'Price cannot be negative.';

  @override
  String get salesErrorPriceBelowCatalog =>
      'Unit price cannot be lower than the product default price.';

  @override
  String get salesPriceBelowCatalogHint => 'Below default price';

  @override
  String get salesErrorInvalidDiscount => 'Discount is invalid.';

  @override
  String get salesErrorInvalidTax => 'Tax rate must be between 0 and 100.';

  @override
  String get salesErrorInvalidPayment => 'Paid amount is invalid.';

  @override
  String get salesErrorInvalidStatus =>
      'This action is not allowed for the current status.';

  @override
  String get customersListTitle => 'Customers';

  @override
  String get customersListCardSubtitle =>
      'Browse, create, and manage customers.';

  @override
  String get customersAccountsTitle => 'Customer accounts';

  @override
  String get customersAccountsCardSubtitle =>
      'Chart of Accounts entries under the customers parent, same as the CoA tree.';

  @override
  String customersAccountsUnderParent(String code, String name) {
    return 'Under $code · $name';
  }

  @override
  String get customersAccountsEmptyTitle => 'No accounts yet';

  @override
  String get customersAccountsEmptyMessage =>
      'When you create a customer with auto-link, their posting account appears here and in the Chart of Accounts.';

  @override
  String get customersAccountGroupBadge => 'Group';

  @override
  String get customersAccountNonPostingBadge => 'Non-posting';

  @override
  String get customersAccountMissingInChart => 'Account missing from chart';

  @override
  String get customersCreateTitle => 'New customer';

  @override
  String get customersEditTitle => 'Edit customer';

  @override
  String get customersDetailsTitle => 'Customer details';

  @override
  String get customersSearchHint => 'Search by code, name, phone, or email';

  @override
  String get customersEmptyTitle => 'No customers yet';

  @override
  String get customersEmptyMessage =>
      'Add a customer or import an Excel list to start building your master list.';

  @override
  String get customersFieldCode => 'Customer code';

  @override
  String get customersFieldCodeHelper =>
      'Sequential code from the customers parent CoA account (e.g. 12210001). Auto-generated, imported, or manual.';

  @override
  String get customersGenerateCode => 'Generate code';

  @override
  String get customersFieldName => 'Name';

  @override
  String get customersFieldPhone => 'Phone';

  @override
  String get customersFieldEmail => 'Email';

  @override
  String get customersFieldAddress => 'Address';

  @override
  String get customersFieldNotes => 'Notes';

  @override
  String get customersFieldActive => 'Active';

  @override
  String get customersFieldAccount => 'Accounting account';

  @override
  String get customersFieldAccountHelper =>
      'Optional. Leave empty to auto-create under the customers parent when auto-link is on, or enter an existing posting account code.';

  @override
  String get customersFieldAccountHelperAuto =>
      'Leave empty to auto-create a Chart of Accounts account under the customers parent (same code as the customer).';

  @override
  String customersAccountLinked(String code, String name) {
    return 'Linked: $code · $name';
  }

  @override
  String get customersAccountLinkInvalid =>
      'No matching posting account found for that code.';

  @override
  String get customersAccountAutoLinkFailed =>
      'Could not create or link the Chart of Accounts account for this customer.';

  @override
  String customersAccountMustBeUnderParent(String code, String name) {
    return 'Linked account must be under parent $code · $name.';
  }

  @override
  String get customersSettingsTitle => 'Customers settings';

  @override
  String get customersSettingsSubtitle =>
      'Configure Chart of Accounts linking and other customer options.';

  @override
  String get customersSettingsCardSubtitle =>
      'Parent account, auto-link, and more';

  @override
  String get customersAutoLinkSectionTitle => 'Auto-link Chart of Accounts';

  @override
  String get customersAutoLinkSectionSubtitle =>
      'When enabled, saving a customer without an account creates a posting account under the customers parent group.';

  @override
  String get customersAutoLinkToggle => 'Create CoA account automatically';

  @override
  String get customersLinkMissingAccountsTitle => 'Link existing customers';

  @override
  String get customersLinkMissingAccountsSubtitle =>
      'Create Chart of Accounts accounts for customers imported or saved without a link.';

  @override
  String get customersLinkMissingAccountsAction => 'Link missing accounts now';

  @override
  String customersLinkMissingAccountsDone(int count) {
    return 'Linked $count customers to the Chart of Accounts.';
  }

  @override
  String get customersParentAccountSectionTitle => 'Customers parent account';

  @override
  String get customersParentAccountSectionSubtitle =>
      'Choose the Chart of Accounts group under which customer accounts nest (default: Customers 1221).';

  @override
  String customersParentAccountCurrent(String code, String name) {
    return 'Parent: $code · $name';
  }

  @override
  String get customersParentAccountNotSet =>
      'Parent account is not set. Configure it in Customers settings.';

  @override
  String get customersParentAccountField => 'Parent account code';

  @override
  String get customersParentAccountFieldHelper =>
      'Enter a group account code from the Chart of Accounts (e.g. 1221).';

  @override
  String get customersParentAccountUseDefault => 'Use default';

  @override
  String get customersParentAccountSaved => 'Customers parent account saved.';

  @override
  String get customersParentAccountInvalid =>
      'No matching group account found for that code.';

  @override
  String get customersFieldDataSource => 'Data source';

  @override
  String get customersDataSourceLocal => 'Local';

  @override
  String get customersDataSourceLocalHint => 'Created and owned in this app.';

  @override
  String get customersDataSourceExternal => 'External';

  @override
  String get customersDataSourceExternalHint =>
      'Imported or maintained from an external accounting/ERP system.';

  @override
  String get customersFieldExternalId => 'External ID';

  @override
  String get customersFieldExternalIdHelper =>
      'Required when the data source is external.';

  @override
  String get customersStatusActive => 'Active';

  @override
  String get customersStatusInactive => 'Inactive';

  @override
  String get customersCreated => 'Customer created.';

  @override
  String get customersUpdated => 'Customer updated.';

  @override
  String get customersDelete => 'Delete';

  @override
  String get customersDeleteTitle => 'Delete customer?';

  @override
  String customersDeleteMessage(String name) {
    return 'Remove $name from the customer list?';
  }

  @override
  String get customersDeleted => 'Customer deleted.';

  @override
  String get customersErrorDuplicateCode =>
      'A customer with this code already exists.';

  @override
  String get customersErrorDuplicateExternalId =>
      'A customer with this external ID already exists.';

  @override
  String get customersErrorInvalidCode => 'Customer code is required.';

  @override
  String get customersErrorInvalidName => 'Customer name is required.';

  @override
  String get customersErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get customersErrorExternalIdRequired =>
      'External ID is required for external customers.';

  @override
  String get customersImportTitle => 'Import customers';

  @override
  String get customersImportSubtitle =>
      'Import customer rows from an Excel file.';

  @override
  String get customersImportPageTitle => 'Import customers';

  @override
  String get customersImportFormatHintTitle => 'Customers Excel layout';

  @override
  String get customersImportFormatHintIntro =>
      'First row = headers. Required: code and name. Use .xlsx or .xls.';

  @override
  String get customersImportFormatColCodeAliases =>
      'Customer Code · Code · رمز العميل';

  @override
  String get customersImportFormatColNameAliases =>
      'Customer Name · Name · اسم العميل';

  @override
  String get customersImportFormatColPhoneAliases => 'Phone · Mobile · الهاتف';

  @override
  String get customersImportFormatColEmailAliases => 'Email · البريد';

  @override
  String get customersImportFormatColAddressAliases => 'Address · العنوان';

  @override
  String get customersImportFormatColNotesAliases => 'Notes · ملاحظات';

  @override
  String get customersImportFormatColExternalIdAliases =>
      'External ID · المعرف الخارجي';

  @override
  String get customersImportFormatSampleNote =>
      'Without headers, columns are read as: code, name. Matching rows update by customer code (or external ID when present).';

  @override
  String customersImportInsertedCount(int count) {
    return 'Inserted $count customers';
  }

  @override
  String customersImportUpdatedCount(int count) {
    return 'Updated $count customers';
  }

  @override
  String get customersNoValidRows =>
      'No valid customer rows were found in the file.';

  @override
  String get loadingImportingCustomers => 'Importing customers…';

  @override
  String get accountingModeSectionTitle => 'Accounting mode';

  @override
  String get accountingModeSectionSubtitle =>
      'Choose whether this app owns accounting locally or complements an external ERP.';

  @override
  String get accountingModeStandalone => 'Standalone';

  @override
  String get accountingModeStandaloneDescription =>
      'The app owns Chart of Accounts and future local accounting features.';

  @override
  String get accountingModeIntegrated => 'Integrated';

  @override
  String get accountingModeIntegratedDescription =>
      'The app is an operational interface beside an existing accounting/ERP system.';

  @override
  String get accountingModeStandaloneHint =>
      'Local accounting data is authoritative. Standalone sales create local journal entries on save/post.';

  @override
  String get accountingModeIntegratedHint =>
      'Operational documents can be prepared here and posted later in the external system. Local journals are not auto-created.';

  @override
  String get accountingModeSavedSuccess => 'Accounting mode saved.';

  @override
  String get accountingFiscalClosedSectionTitle => 'Closed fiscal period';

  @override
  String get accountingFiscalClosedSectionSubtitle =>
      'Journal entries on or before this date cannot be posted or changed.';

  @override
  String get accountingFiscalClosedThroughLabel => 'Closed through';

  @override
  String get accountingFiscalClosedNone => 'No closed period';

  @override
  String get accountingFiscalClosedSavedSuccess =>
      'Closed fiscal period saved.';

  @override
  String get accountingFiscalClosedClear => 'Clear';

  @override
  String get accountingJournalsTitle => 'Journal entries';

  @override
  String get accountingJournalsSubtitle =>
      'Browse, create, and review journal vouchers.';

  @override
  String get accountingJournalsEmptyTitle => 'No journal entries yet';

  @override
  String get accountingJournalsEmptyMessage =>
      'Create a manual journal or post a standalone sale.';

  @override
  String get accountingJournalsSearchHint =>
      'Search voucher number or description';

  @override
  String get accountingJournalAdd => 'New journal';

  @override
  String get accountingJournalDetails => 'Journal details';

  @override
  String get accountingJournalEdit => 'Edit journal';

  @override
  String get accountingJournalSave => 'Save journal';

  @override
  String get accountingJournalSavedSuccess => 'Journal saved.';

  @override
  String get accountingJournalVoid => 'Void entry';

  @override
  String get accountingJournalVoidConfirmTitle => 'Void this journal?';

  @override
  String get accountingJournalVoidConfirmMessage =>
      'The entry will be soft-deleted and removed from ledgers. Lines are kept for audit.';

  @override
  String get accountingJournalVoidedSuccess => 'Journal voided.';

  @override
  String get accountingJournalNotFound => 'Journal entry not found.';

  @override
  String get accountingJournalFieldDate => 'Date';

  @override
  String get accountingJournalFieldVoucherNumber => 'Voucher number';

  @override
  String get accountingJournalFieldVoucherType => 'Voucher type';

  @override
  String get accountingJournalFieldDescription => 'Description';

  @override
  String get accountingJournalFieldCurrency => 'Currency';

  @override
  String get accountingJournalFieldStatus => 'Status';

  @override
  String get accountingJournalPosted => 'Posted';

  @override
  String get accountingJournalUnposted => 'Unposted';

  @override
  String accountingJournalSourceLinked(String source) {
    return 'Linked to $source';
  }

  @override
  String get accountingJournalLines => 'Lines';

  @override
  String get accountingJournalAddLine => 'Add line';

  @override
  String get accountingJournalAccount => 'Account';

  @override
  String get accountingJournalDebit => 'Debit';

  @override
  String get accountingJournalCredit => 'Credit';

  @override
  String get accountingJournalTotals => 'Totals';

  @override
  String get accountingJournalPickAccount => 'Select account';

  @override
  String get accountingJournalErrorUnbalanced =>
      'Total debit must equal total credit.';

  @override
  String get accountingJournalErrorPeriodClosed =>
      'This date falls in a closed fiscal period.';

  @override
  String get accountingJournalErrorLines => 'Add at least two balanced lines.';

  @override
  String get accountingJournalManualType => 'Manual journal';

  @override
  String get accountingChartOfAccounts => 'Chart of Accounts';

  @override
  String get accountingChartOfAccountsDescription =>
      'Browse and manage the hierarchical account structure.';

  @override
  String get accountingReportsTitle => 'Accounting reports';

  @override
  String get accountingReportsSubtitle =>
      'Statements and financial reports built on the Chart of Accounts.';

  @override
  String get accountingReportTrialBalanceTitle => 'Trial balance';

  @override
  String get accountingReportJournalTitle => 'Journal';

  @override
  String get accountingReportComingSoonSubtitle => 'Coming in a later release.';

  @override
  String get accountingReportComingSoonBadge => 'Soon';

  @override
  String get accountingCurrencyRatesTitle => 'Currency rates';

  @override
  String get accountingCurrencyRatesCardSubtitle =>
      'Add only the currencies you need and set their rates.';

  @override
  String get accountingCurrencyRatesSubtitle =>
      'Add currencies on demand. Only enabled currencies (plus the company base) appear here — later used for multi-currency account balances.';

  @override
  String accountingCurrencyRatesBase(String code, String name) {
    return 'Base currency: $code · $name';
  }

  @override
  String get accountingCurrencyRatesBaseBadge => 'Base';

  @override
  String get accountingCurrencyRatesBaseHint =>
      'Company base currency — rate is always 1.';

  @override
  String get accountingCurrencyRatesNotSet => 'Rate not set — tap to enter.';

  @override
  String accountingCurrencyRatesEquals(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String accountingCurrencyRatesUpdated(String when) {
    return 'Updated $when';
  }

  @override
  String get accountingCurrencyRatesEmptyTitle => 'No currencies enabled';

  @override
  String get accountingCurrencyRatesEmptyMessage =>
      'Tap Add currency to enable a currency and set its rate.';

  @override
  String get accountingCurrencyRatesAdd => 'Add currency';

  @override
  String get accountingCurrencyRatesAddTitle => 'Enable currency';

  @override
  String get accountingCurrencyRatesAddHint =>
      'Choose a currency you need for the business and enter its rate against the base currency.';

  @override
  String get accountingCurrencyRatesCurrencyField => 'Currency';

  @override
  String get accountingCurrencyRatesRemove => 'Remove';

  @override
  String get accountingCurrencyRatesRemoveTitle => 'Remove currency?';

  @override
  String accountingCurrencyRatesRemoveMessage(String name, String code) {
    return 'Remove $name ($code)? It will no longer be available for multi-currency balances until you add it again.';
  }

  @override
  String get accountingCurrencyRatesRemoved => 'Currency removed.';

  @override
  String accountingCurrencyRatesEditTitle(String code) {
    return 'Edit $code rate';
  }

  @override
  String accountingCurrencyRatesEditHint(String currency, String base) {
    return 'How many $base equal 1 $currency?';
  }

  @override
  String get accountingCurrencyRatesRateField => 'Rate to base';

  @override
  String accountingCurrencyRatesRateHelper(String base) {
    return 'Example: if base is $base, enter how many $base equal 1 unit of this currency.';
  }

  @override
  String get accountingCurrencyRatesInvalid => 'Enter a valid positive rate.';

  @override
  String get accountingCurrencyRatesSaved => 'Currency rate saved.';

  @override
  String get accountingVoucherBooksTitle => 'Voucher books';

  @override
  String get accountingVoucherBooksCardSubtitle =>
      'Set up numbering books for sales, receipts, and other vouchers.';

  @override
  String get accountingVoucherBooksSubtitle =>
      'Open a section, then use tabs for each type (e.g. sales and sales returns). Each type has its own list and add action.';

  @override
  String get accountingVoucherBooksEmptyTitle => 'No voucher books';

  @override
  String get accountingVoucherBooksEmptyMessage =>
      'Add a book under a section to prepare sequential voucher numbers.';

  @override
  String get accountingVoucherBooksAdd => 'Add book';

  @override
  String accountingVoucherBooksAddOfType(String type) {
    return 'Add $type';
  }

  @override
  String get accountingVoucherBooksAddUnderSection =>
      'Add book in this section';

  @override
  String accountingVoucherBooksSectionKinds(int kinds, int books) {
    return '$kinds types · $books books';
  }

  @override
  String accountingVoucherBooksTypeEmptyTitle(String type) {
    return 'No $type books';
  }

  @override
  String get accountingVoucherBooksTypeEmptyMessage =>
      'Tap add to create a numbering book for this type.';

  @override
  String get accountingVoucherBooksEdit => 'Edit book';

  @override
  String get accountingVoucherBooksSave => 'Save book';

  @override
  String get accountingVoucherBooksName => 'Book name';

  @override
  String get accountingVoucherBooksNameHint =>
      'e.g. Main sales / Sales returns branch A';

  @override
  String get accountingVoucherBooksParentSection => 'Section';

  @override
  String get accountingVoucherBooksType => 'Book type';

  @override
  String get accountingVoucherBooksCurrentNumber => 'Current number';

  @override
  String get accountingVoucherBooksCurrentNumberHelper =>
      'The next voucher number that will be issued from this book.';

  @override
  String get accountingVoucherBooksEndNumber => 'End number';

  @override
  String get accountingVoucherBooksEndNumberHelper =>
      'Last number available in this book.';

  @override
  String accountingVoucherBooksRangePreview(String current, String end) {
    return 'Current $current · ends at $end';
  }

  @override
  String accountingVoucherBooksSectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
      zero: 'No books yet',
    );
    return '$_temp0';
  }

  @override
  String get accountingVoucherBooksSectionEmpty =>
      'No books in this section yet. Add sales, returns, or other series as needed.';

  @override
  String get accountingVoucherBooksNotes => 'Notes';

  @override
  String get accountingVoucherBooksActive => 'Active';

  @override
  String get accountingVoucherBooksInactive => 'Inactive';

  @override
  String get accountingVoucherBooksDelete => 'Delete';

  @override
  String get accountingVoucherBooksDeleteTitle => 'Delete voucher book?';

  @override
  String accountingVoucherBooksDeleteMessage(String name) {
    return 'Delete “$name”? This cannot be undone.';
  }

  @override
  String get accountingVoucherBooksDeleted => 'Voucher book deleted.';

  @override
  String get accountingVoucherBooksSaved => 'Voucher book saved.';

  @override
  String get accountingVoucherBooksErrorName => 'Enter a book name.';

  @override
  String get accountingVoucherBooksErrorParent => 'Choose a parent section.';

  @override
  String get accountingVoucherBooksErrorCurrentNumber =>
      'Current number must be at least 1.';

  @override
  String get accountingVoucherBooksErrorEndNumber =>
      'End number must be at least 1.';

  @override
  String get accountingVoucherBooksErrorEndBeforeCurrent =>
      'End number must be greater than or equal to current number.';

  @override
  String get accountingVoucherBookTypeSales => 'Sales';

  @override
  String get accountingVoucherBookTypeSalesReturns => 'Sales returns';

  @override
  String get accountingVoucherBookTypeReceipts => 'Receipts';

  @override
  String get accountingVoucherBookTypePayments => 'Payments';

  @override
  String get accountingVoucherBookTypePurchases => 'Purchases';

  @override
  String get accountingVoucherBookTypePurchaseReturns => 'Purchase returns';

  @override
  String get accountingVoucherBookTypeJournal => 'Journal';

  @override
  String get accountingAddAccount => 'Add account';

  @override
  String get accountingEditAccount => 'Edit account';

  @override
  String get accountingSaveAccount => 'Save account';

  @override
  String get accountingAccountDetails => 'Account details';

  @override
  String get accountingSearchHint => 'Search by name or code';

  @override
  String get accountingEmptyTitle => 'No accounts yet';

  @override
  String get accountingEmptyMessage =>
      'Default accounts will appear after first open, or add your own.';

  @override
  String get accountingNoSearchResults => 'No matching accounts';

  @override
  String get accountingNoSearchResultsMessage =>
      'Try a different name or account code.';

  @override
  String get accountingExpandAll => 'Expand all';

  @override
  String get accountingCollapseAll => 'Collapse all';

  @override
  String get accountingShowInactive => 'Show inactive';

  @override
  String get accountingHideInactive => 'Hide inactive';

  @override
  String get accountingFieldName => 'Account name';

  @override
  String get accountingFieldCode => 'Account code';

  @override
  String get accountingFieldParent => 'Parent account';

  @override
  String get accountingFieldType => 'Account type';

  @override
  String get accountingFieldDescription => 'Description';

  @override
  String get accountingFieldNormalBalance => 'Normal balance';

  @override
  String get accountingFieldLevel => 'Level';

  @override
  String get accountingFieldKind => 'Kind';

  @override
  String get accountingFieldStatus => 'Status';

  @override
  String get accountingFieldSystem => 'System account';

  @override
  String get accountingFieldCreatedAt => 'Created';

  @override
  String get accountingFieldUpdatedAt => 'Updated';

  @override
  String get accountingRootAccount => 'No parent (root)';

  @override
  String get accountingTypeAsset => 'Assets';

  @override
  String get accountingTypeLiability => 'Liabilities';

  @override
  String get accountingTypeEquity => 'Equity';

  @override
  String get accountingTypeRevenue => 'Revenue';

  @override
  String get accountingTypeExpense => 'Expenses';

  @override
  String get accountingTypeInheritedHint =>
      'Type is inherited from the parent account.';

  @override
  String get accountingNormalDebit => 'Debit';

  @override
  String get accountingNormalCredit => 'Credit';

  @override
  String get accountingAccountGroup => 'Group account';

  @override
  String get accountingAccountGroupHint =>
      'Group accounts organize the tree and are not used for posting.';

  @override
  String get accountingAccountPosting => 'Posting account';

  @override
  String get accountingAccountActive => 'Active';

  @override
  String get accountingAccountInactive => 'Inactive';

  @override
  String get accountingSystemAccount => 'System';

  @override
  String get accountingSystemAccountHint =>
      'System accounts have protected code and type.';

  @override
  String get accountingYes => 'Yes';

  @override
  String get accountingNo => 'No';

  @override
  String get accountingComingSoonSection => 'Coming soon';

  @override
  String get accountingComingSoonHint =>
      'Available after journal entries are implemented.';

  @override
  String get accountingCurrentBalance => 'Current balance';

  @override
  String get accountingTransactions => 'Transactions';

  @override
  String get accountingLedger => 'Ledger';

  @override
  String get accountingDeactivate => 'Deactivate';

  @override
  String get accountingSoftDelete => 'Remove account';

  @override
  String get accountingDeactivateConfirmTitle => 'Deactivate account?';

  @override
  String get accountingDeactivateConfirmMessage =>
      'The account stays in history but cannot be selected for new activity.';

  @override
  String get accountingDeleteConfirmTitle => 'Remove account?';

  @override
  String get accountingDeleteConfirmMessage =>
      'This soft-deletes the account. System accounts and accounts with children cannot be removed.';

  @override
  String get accountingSavedSuccess => 'Account saved successfully.';

  @override
  String get accountingDeactivatedSuccess => 'Account deactivated.';

  @override
  String get accountingDeletedSuccess => 'Account removed.';

  @override
  String get accountingAccountNotFound => 'Account not found.';

  @override
  String get accountingErrorNameRequired => 'Account name is required.';

  @override
  String get accountingErrorCodeRequired => 'Account code is required.';

  @override
  String get accountingErrorDuplicateCode =>
      'An account with this code already exists.';

  @override
  String get accountingErrorTypeMismatch =>
      'Account type must match the parent account.';

  @override
  String get accountingErrorInvalidParent =>
      'Parent account is invalid or inactive.';

  @override
  String get accountingErrorCircularParent =>
      'An account cannot be nested under itself.';

  @override
  String get accountingErrorParentMustBeGroup =>
      'Only group accounts can have children.';

  @override
  String get accountingErrorSystemProtected =>
      'System accounts cannot be changed this way.';

  @override
  String get accountingErrorHasChildren =>
      'Remove or move child accounts first.';

  @override
  String get accountingErrorInUse =>
      'This account is used in transactions and cannot be removed.';

  @override
  String accountingAccountsCount(int count) {
    return '$count accounts';
  }

  @override
  String accountingSectionChildrenCount(int count) {
    return '$count accounts';
  }

  @override
  String get accountingFilterAll => 'All';

  @override
  String get accountingFilterByType => 'Filter by type';

  @override
  String get accountingToolbarActions => 'Tree actions';

  @override
  String get accountingAccountAssets => 'Assets';

  @override
  String get accountingAccountCurrentAssets => 'Current Assets';

  @override
  String get accountingAccountCash => 'Cash';

  @override
  String get accountingAccountBank => 'Bank';

  @override
  String get accountingAccountPettyCash => 'Petty Cash';

  @override
  String get accountingAccountAccountsReceivable => 'Accounts Receivable';

  @override
  String get accountingAccountCustomers => 'Customers';

  @override
  String get accountingAccountInventory => 'Inventory';

  @override
  String get accountingAccountInventoryInTransit => 'Inventory in Transit';

  @override
  String get accountingAccountVatInput => 'VAT Input';

  @override
  String get accountingAccountPrepaidExpenses => 'Prepaid Expenses';

  @override
  String get accountingAccountOtherCurrentAssets => 'Other Current Assets';

  @override
  String get accountingAccountFixedAssets => 'Fixed Assets';

  @override
  String get accountingAccountBuildings => 'Buildings';

  @override
  String get accountingAccountVehicles => 'Vehicles';

  @override
  String get accountingAccountEquipment => 'Equipment';

  @override
  String get accountingAccountLiabilities => 'Liabilities';

  @override
  String get accountingAccountCurrentLiabilities => 'Current Liabilities';

  @override
  String get accountingAccountAccountsPayable => 'Accounts Payable';

  @override
  String get accountingAccountSuppliers => 'Suppliers';

  @override
  String get accountingAccountShortTermLoans => 'Short Term Loans';

  @override
  String get accountingAccountVatOutput => 'VAT Output Payable';

  @override
  String get accountingAccountAccruedExpenses => 'Accrued Expenses';

  @override
  String get accountingAccountCustomerAdvances => 'Customer Advances';

  @override
  String get accountingAccountLongTermLiabilities => 'Long Term Liabilities';

  @override
  String get accountingAccountLongTermLoans => 'Long Term Loans';

  @override
  String get accountingAccountEquity => 'Equity';

  @override
  String get accountingAccountCapital => 'Capital';

  @override
  String get accountingAccountRetainedEarnings => 'Retained Earnings';

  @override
  String get accountingAccountRevenue => 'Revenue';

  @override
  String get accountingAccountSalesRevenue => 'Sales Revenue';

  @override
  String get accountingAccountOtherRevenue => 'Other Revenue';

  @override
  String get accountingAccountPurchaseDiscounts => 'Purchase Discounts';

  @override
  String get accountingAccountExpenses => 'Expenses';

  @override
  String get accountingAccountCogs => 'Cost of Goods Sold';

  @override
  String get accountingAccountInventoryAdjustments => 'Inventory Adjustments';

  @override
  String get accountingAccountSalesReturns => 'Sales Returns';

  @override
  String get accountingAccountSalesDiscounts => 'Sales Discounts';

  @override
  String get accountingAccountSalaries => 'Salaries';

  @override
  String get accountingAccountRent => 'Rent';

  @override
  String get accountingAccountUtilities => 'Utilities';

  @override
  String get accountingAccountBankCharges => 'Bank Charges';

  @override
  String get accountingAccountDepreciation => 'Depreciation';

  @override
  String get accountingAccountAdvertising => 'Advertising';

  @override
  String get accountingAccountShippingDelivery => 'Shipping and Delivery';

  @override
  String get accountingAccountMaintenance => 'Maintenance';

  @override
  String get accountingAccountOtherExpenses => 'Other Expenses';

  @override
  String get inventoryStockCountService => 'Stock count';

  @override
  String get inventoryStockCountServiceDescription =>
      'Count items, import stock lists, and view count reports.';

  @override
  String get inventoryProductsService => 'Products';

  @override
  String get inventoryProductsServiceDescription =>
      'Manage the product catalog, prices, and pack sizes.';

  @override
  String get productsHubTitle => 'Products';

  @override
  String get productsHubDescription =>
      'Browse the catalog, manage barcodes, or import from Excel.';

  @override
  String get productsListTitle => 'Product list';

  @override
  String get productsListSubtitle => 'Search, add, edit, and delete products.';

  @override
  String get productsImportTitle => 'Import products';

  @override
  String get productsImportSubtitle =>
      'Import catalog rows from an Excel file.';

  @override
  String get productsBarcodeTitle => 'Barcodes';

  @override
  String get productsBarcodeSubtitle =>
      'Generate, scan, preview, and print product barcodes.';

  @override
  String get productsBarcodeSelectHint => 'Search or scan to select a product.';

  @override
  String productsBarcodeSearchResults(int count) {
    return '$count products';
  }

  @override
  String get productsBarcodeNoResults => 'No products match your search.';

  @override
  String get productsBarcodeChangeProduct => 'Change';

  @override
  String get productsBarcodeHasCode => 'Has barcode';

  @override
  String get productsBarcodeNoCode => 'No barcode';

  @override
  String get productsBarcodeReplaceTitle => 'Replace barcode?';

  @override
  String get productsBarcodeReplaceMessage =>
      'This product already has a barcode. Generate a new one and save it?';

  @override
  String get productsBarcodeSavedSuccess => 'Barcode saved successfully.';

  @override
  String get productsBarcodeMissingForPrint =>
      'Generate or assign a barcode before printing.';

  @override
  String get productsBarcodePrint => 'Print';

  @override
  String get productsBarcodeShare => 'Share';

  @override
  String get productsBarcodeThermalPrint => 'Thermal printer';

  @override
  String get productsBarcodeThermalComingSoon =>
      'Thermal printing will be available in a future update.';

  @override
  String get productsSearchHint => 'Search by code, name, or barcode';

  @override
  String get catalogSearchFieldAll => 'All';

  @override
  String get catalogSearchFieldName => 'Name';

  @override
  String get catalogSearchFieldCode => 'Code';

  @override
  String get catalogSearchFieldBarcode => 'Barcode';

  @override
  String get catalogSearchHintName => 'Search by name';

  @override
  String get catalogSearchHintCode => 'Search by code';

  @override
  String get catalogSearchHintBarcode => 'Search by barcode';

  @override
  String get catalogSearchFilterLabel => 'Search in';

  @override
  String get productsEmptyTitle => 'No products yet';

  @override
  String get productsEmptyMessage =>
      'Add a product manually or import an Excel catalog.';

  @override
  String get productsGoToImport => 'Go to import';

  @override
  String get productsAdd => 'Add product';

  @override
  String get productsViewList => 'List';

  @override
  String get productsViewGrid => 'Grid';

  @override
  String get productsViewModeTooltip => 'Change product layout';

  @override
  String get productsEdit => 'Edit product';

  @override
  String get productsDelete => 'Delete';

  @override
  String get productsDeleteConfirmTitle => 'Delete product?';

  @override
  String get productsDeleteConfirmMessage =>
      'This removes the product from the catalog. Stock-count data is not changed.';

  @override
  String get productsSavedSuccess => 'Product saved successfully.';

  @override
  String get productsDeletedSuccess => 'Product deleted.';

  @override
  String get productsDuplicateCode =>
      'A product with this item code already exists.';

  @override
  String get productsDuplicateBarcode =>
      'A product with this barcode already exists.';

  @override
  String get productsInvalidForm =>
      'Enter a valid code, name, pack size, and price.';

  @override
  String get productsItemCodeAutoHint =>
      'Generated automatically and cannot be edited.';

  @override
  String get productsFieldLockedHint => 'This field cannot be edited.';

  @override
  String get price => 'Price';

  @override
  String get priceRequiredHint => 'e.g. 12.50';

  @override
  String get productsImportPageTitle => 'Import products';

  @override
  String get productsImportFormatHintTitle => 'Products Excel layout';

  @override
  String get productsImportFormatHintIntro =>
      'First row = headers. Required columns only. Use .xlsx or .xls.';

  @override
  String get productsImportFormatColPrice => 'Price';

  @override
  String get productsImportFormatColPriceAliases =>
      'Price · Unit Price · السعر';

  @override
  String get productsImportFormatColPackAliases => 'Pack Size · Pack · العبوة';

  @override
  String get productsImportFormatSampleNote =>
      'Without headers, columns are read as: code, name, pack size, price.';

  @override
  String get productsImportFormatSamplePriceHeader => 'Price';

  @override
  String productsImportInsertedCount(int count) {
    return 'Inserted $count products';
  }

  @override
  String productsImportUpdatedCount(int count) {
    return 'Updated $count products';
  }

  @override
  String get productsNoValidRows =>
      'No valid product rows were found in the file.';

  @override
  String get productsScanBarcode => 'Scan barcode or QR';

  @override
  String get productsScanAction => 'Scan';

  @override
  String get productsScannerAlignHint => 'Align barcode or QR code here';

  @override
  String get productsScannerScanning => 'Scanning...';

  @override
  String get productsScannerDetected => 'Code detected';

  @override
  String get productsScannerProcessing => 'Processing...';

  @override
  String get productsScannerInvalid => 'Unsupported code';

  @override
  String get productsGenerateBarcode => 'Generate';

  @override
  String get productsGenerateBarcodeTooltip =>
      'Generate a unique barcode value';

  @override
  String get productsBarcodePreview => 'Barcode preview';

  @override
  String get productsBarcodeTypeLabel => 'Barcode type';

  @override
  String get productsBarcodeFormatBarcode => 'Barcode';

  @override
  String get productsBarcodeFormatQr => 'QR Code';

  @override
  String get productsQrCodePreview => 'QR Code preview';

  @override
  String get productsGenerateQrCode => 'Generate QR Code';

  @override
  String get productsSaveQrCode => 'Save QR Code';

  @override
  String get productsShareQrCode => 'Share QR Code';

  @override
  String get productsInvalidProductData => 'Invalid product data';

  @override
  String get productsQrScanRecognized => 'Product loaded from QR Code';

  @override
  String get productsQrScanOfflineData =>
      'Product shown from QR data (not found in catalog)';

  @override
  String get productsQrProductDetails => 'Product details';

  @override
  String get productsCodesSection => 'Product codes';

  @override
  String get productsPrintBarcode => 'Print barcode';

  @override
  String get productsPrintQr => 'Print QR Code';

  @override
  String get productsBarcodeNotFound => 'No product found for this barcode.';

  @override
  String get productsCameraPermissionDenied =>
      'Camera permission is required to scan barcodes.';

  @override
  String get productsCameraUnavailable =>
      'Camera is not available on this device.';

  @override
  String get productsEnterBarcodeHint =>
      'Enter the barcode manually, or use camera scan on Android/iOS after a full app restart.';

  @override
  String get inventoryOpenStockCount => 'Open stock count';

  @override
  String get inventoryCustomizeServices => 'Customize';

  @override
  String get inventoryCustomizeServicesHint =>
      'Choose services to show, then drag to change their order.';

  @override
  String get inventorySaveServices => 'Save';

  @override
  String get inventoryPinnedServices => 'Pinned services';

  @override
  String get inventoryAvailableServices => 'Available services';

  @override
  String get inventoryAddService => 'Add';

  @override
  String get inventoryRemoveService => 'Remove';

  @override
  String get inventoryNoServicesTitle => 'No services on inventory home';

  @override
  String get inventoryNoServicesMessage =>
      'Customize to pin the inventory services you use most.';

  @override
  String get inventoryNoServicesAvailable =>
      'No inventory services are available yet.';

  @override
  String get modulePlaceholderMessage =>
      'This module is registered and ready. Business features will be added in the next stages.';

  @override
  String get inventoryOverview => 'Overview';

  @override
  String get inventoryCountTitle => 'Count';

  @override
  String get inventoryCountSubtitle =>
      'Search items and enter counted quantities.';

  @override
  String get searchItems => 'Search Items';

  @override
  String get searchItemsHint => 'Search by name or code';

  @override
  String searchResultsCount(int count) {
    return '$count results';
  }

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get noItemSelected => 'No item selected';

  @override
  String get saveCount => 'Save Count';

  @override
  String get editCount => 'Edit Count';

  @override
  String get editCountTitle => 'Edit Count';

  @override
  String get editCountSubtitle => 'Enter the new count quantities.';

  @override
  String get countSavedSuccess => 'Count saved successfully.';

  @override
  String get negativeQuantityNotAllowed =>
      'Negative quantities are not allowed.';

  @override
  String get packSize => 'Pack Size';

  @override
  String get packSizeMissingWarning =>
      'This product has no pack size. Enter the pack size before counting.';

  @override
  String get packSizeIncompleteMarkerWarning =>
      'The product name has * without a pack number. Enter the pack size to continue.';

  @override
  String get packSizeInvalidWarning =>
      'The pack size in the product name is invalid. Enter a valid pack size.';

  @override
  String get packSizeRequiredHint => 'e.g. 24';

  @override
  String get savePackSize => 'Save Pack Size';

  @override
  String get packSizeSavedSuccess => 'Pack size saved successfully.';

  @override
  String get packSizeRequiredBeforeCount =>
      'Enter the pack size before counting.';

  @override
  String get invalidPackSize => 'Enter a valid pack size greater than zero.';

  @override
  String get codeLabel => 'Code';

  @override
  String get barcode => 'Barcode';

  @override
  String get mainQuantity => 'Main Quantity';

  @override
  String get subQuantity => 'Sub Quantity';

  @override
  String get systemQuantity => 'System Quantity';

  @override
  String get actualQuantity => 'Actual Quantity';

  @override
  String get difference => 'Difference';

  @override
  String get countDetails => 'Count Details';

  @override
  String get shortageQuantity => 'Shortage Quantity';

  @override
  String get overageQuantity => 'Overage Quantity';

  @override
  String get totalItems => 'Total Items';

  @override
  String get countedItems => 'Counted Items';

  @override
  String get remainingItems => 'Remaining Items';

  @override
  String get matched => 'Matched';

  @override
  String get shortage => 'Shortage';

  @override
  String get overage => 'Overage';

  @override
  String get matchedStatus => 'Matched';

  @override
  String get shortageStatus => 'Shortage';

  @override
  String get overageStatus => 'Overage';

  @override
  String get notCountedStatus => 'Not Counted';

  @override
  String get allItems => 'All Items';

  @override
  String get matchedItems => 'Matched Items';

  @override
  String get shortageItems => 'Shortages';

  @override
  String get overageItems => 'Overages';

  @override
  String get notCountedItems => 'Not Counted Items';

  @override
  String get emptyStateTitle => 'No items found';

  @override
  String get emptyStateSubtitle =>
      'Try a different search or import inventory first.';

  @override
  String get inventoryEmptyNeedsImportTitle => 'No inventory items yet';

  @override
  String get inventoryEmptyNeedsImportMessage =>
      'Import an Excel list to start counting and viewing reports.';

  @override
  String get inventoryGoToImport => 'Go to Import';

  @override
  String get importPageTitle => 'Import Inventory';

  @override
  String get selectExcelFile => 'Select Excel File';

  @override
  String get selectedFileName => 'Selected File';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get importButton => 'Import';

  @override
  String get importFormatHintTitle => 'Excel file layout';

  @override
  String get importFormatHintIntro => 'First row = headers. Use .xlsx or .xls.';

  @override
  String get importFormatRequired => 'Required';

  @override
  String get importFormatOptional => 'Optional';

  @override
  String get importFormatColCode => 'Item code';

  @override
  String get importFormatColCodeAliases => 'Item Code · Code · رقم السلعة';

  @override
  String get importFormatColName => 'Item name';

  @override
  String get importFormatColNameAliases => 'Item Name · Name · اسم السلعة';

  @override
  String get importFormatColMainQty => 'Main quantity';

  @override
  String get importFormatColMainQtyAliases => 'Main Quantity · الكمية الرئيسية';

  @override
  String get importFormatColSubQty => 'Sub quantity';

  @override
  String get importFormatColSubQtyAliases => 'Sub Quantity · الكمية الفرعية';

  @override
  String get importFormatColBarcode => 'Barcode';

  @override
  String get importFormatColBarcodeAliases => 'Barcode · الباركود';

  @override
  String get importFormatColPack => 'Pack size';

  @override
  String get importFormatColPackAliases => 'Pack Size · حجم العبوة';

  @override
  String get importFormatSampleTitle => 'Sample';

  @override
  String get importFormatSampleNote =>
      'Without headers, columns are read as: code, name, main qty, sub qty.';

  @override
  String get importFormatSampleCodeHeader => 'Item Code';

  @override
  String get importFormatSampleNameHeader => 'Item Name';

  @override
  String get importFormatSampleMainHeader => 'Main Qty';

  @override
  String get importFormatSampleSubHeader => 'Sub Qty';

  @override
  String get importFormatSamplePackHeader => 'Pack Size';

  @override
  String get importing => 'Importing...';

  @override
  String get importSuccess => 'Import completed successfully.';

  @override
  String get importFailed => 'Import failed.';

  @override
  String importedItemsCount(int count) {
    return 'Imported $count items';
  }

  @override
  String ignoredRowsCount(int count) {
    return 'Ignored $count rows';
  }

  @override
  String get invalidFile => 'The selected file is not a valid Excel file.';

  @override
  String get fileSelectedPrompt => 'Please select an Excel file to continue.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get exportReport => 'Export Report';

  @override
  String get exportSuccess => 'Report exported successfully.';

  @override
  String get exportFailed => 'Report export failed.';

  @override
  String get exportNoItems =>
      'There are no items to print for the current filter.';

  @override
  String get exportDataNotReady =>
      'Inventory data is not ready yet. Please wait and try again.';

  @override
  String get inventoryReportTitle => 'Inventory Count Report';

  @override
  String get systemMainQuantity => 'System Main Qty';

  @override
  String get systemSubQuantity => 'System Sub Qty';

  @override
  String get countedMainQuantity => 'Counted Main Qty';

  @override
  String get countedSubQuantity => 'Counted Sub Qty';

  @override
  String get varianceQuantity => 'Shortage / Overage';

  @override
  String get varianceMainQuantity => 'Main Shortage/Overage';

  @override
  String get varianceSubQuantity => 'Sub Shortage/Overage';

  @override
  String get reportSection => 'Section';

  @override
  String get generatedAt => 'Generated';

  @override
  String get inventorySheetName => 'Inventory';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get setupSettingsTitle => 'Setup settings';

  @override
  String get setupSettingsSubtitle =>
      'Configure company identity, logo, default currency, and related business details.';

  @override
  String get setupSettingsCardSubtitle =>
      'Company name, logo, currency, and legal details.';

  @override
  String get moduleSystemSetup => 'Settings';

  @override
  String get moduleSystemSetupDescription =>
      'Company, modules, language, currency, and system initialization.';

  @override
  String get systemSettingsHubSubtitle =>
      'Manage company details and settings for every business module.';

  @override
  String get systemSetupInitializationSection => 'System initialization';

  @override
  String get systemSetupReviewSteps => 'Review setup steps';

  @override
  String get systemSetupTitle => 'Settings';

  @override
  String get systemSetupSubtitle =>
      'Configure your business environment. You can resume anytime.';

  @override
  String get systemSetupProgressLabel => 'Setup progress';

  @override
  String systemSetupPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String get systemSetupRequiredSection => 'Required steps';

  @override
  String get systemSetupOptionalSection => 'Optional steps';

  @override
  String get systemSetupContinue => 'Continue';

  @override
  String get systemSetupRetry => 'Retry';

  @override
  String get systemSetupSkip => 'Skip for now';

  @override
  String get systemSetupFinish => 'Go to app';

  @override
  String get systemSetupEditCompany => 'Company details';

  @override
  String get systemSetupOpenFromSettings => 'System initialization';

  @override
  String get systemSetupOpenFromSettingsSubtitle =>
      'Review setup progress or re-run initialization steps.';

  @override
  String get systemSetupStepWelcome => 'Deployment mode';

  @override
  String get systemSetupStepWelcomeHint =>
      'Choose standalone local accounting or connection to an external system.';

  @override
  String get systemSetupStepCompany => 'Company profile';

  @override
  String get systemSetupStepCompanyHint =>
      'Company name and fiscal year start.';

  @override
  String get systemSetupStepLocale => 'Language';

  @override
  String get systemSetupStepLocaleHint =>
      'Choose the app language or keep the device default.';

  @override
  String get systemSetupStepPrimaryCurrency => 'Base currency';

  @override
  String get systemSetupStepPrimaryCurrencyHint =>
      'Choose the main system currency. This cannot be changed later.';

  @override
  String get systemSetupCurrencyLocked =>
      'Base currency is locked and cannot be changed.';

  @override
  String get systemSetupStepSeed => 'Local defaults';

  @override
  String get systemSetupStepSeedHint =>
      'Create the default chart of accounts and voucher books.';

  @override
  String get systemSetupStepExternal => 'External connection';

  @override
  String get systemSetupStepExternalHint =>
      'Configure an ERP connection when using integrated mode.';

  @override
  String get systemSetupStepSync => 'Initial sync';

  @override
  String get systemSetupStepSyncHint =>
      'Run a synchronization pass when a remote backend is available.';

  @override
  String get systemSetupModeStandalone => 'Standalone';

  @override
  String get systemSetupModeStandaloneHint =>
      'This app owns local accounting data and journals.';

  @override
  String get systemSetupModeIntegrated => 'Integrated';

  @override
  String get systemSetupModeIntegratedHint =>
      'Operate beside an existing accounting/ERP system.';

  @override
  String get systemSetupLocaleSystem => 'Use device language';

  @override
  String get systemSetupLocaleEnglish => 'English';

  @override
  String get systemSetupLocaleArabic => 'Arabic';

  @override
  String get systemSetupSeedRunning => 'Preparing local defaults…';

  @override
  String get systemSetupSeedDone =>
      'Default accounts and voucher books are ready.';

  @override
  String get systemSetupExternalPlaceholder =>
      'External ERP adapters are registered by the App layer. You can skip this and connect later from Settings.';

  @override
  String get systemSetupSyncRunning => 'Synchronizing…';

  @override
  String get systemSetupSyncDone => 'Sync finished.';

  @override
  String get systemSetupSyncSkippedHint =>
      'You can sync anytime from Settings.';

  @override
  String get systemSetupStatusPending => 'Pending';

  @override
  String get systemSetupStatusInProgress => 'In progress';

  @override
  String get systemSetupStatusCompleted => 'Completed';

  @override
  String get systemSetupStatusFailed => 'Failed';

  @override
  String get systemSetupStatusSkipped => 'Skipped';

  @override
  String get systemSetupReadyTitle => 'You\'re ready';

  @override
  String get systemSetupReadyMessage =>
      'Required setup is complete. Optional steps can be finished later.';

  @override
  String get systemSetupErrorGeneric =>
      'This step failed. Fix the issue and retry.';

  @override
  String get setupCompanyIdentitySection => 'Company identity';

  @override
  String get setupCompanyName => 'Company name';

  @override
  String get setupCompanyNameRequired => 'Company name is required.';

  @override
  String get setupLegalName => 'Legal name';

  @override
  String get setupLegalNameHelper =>
      'Official registered name if different from the display name.';

  @override
  String get setupPickLogo => 'Choose logo';

  @override
  String get setupRemoveLogo => 'Remove logo';

  @override
  String get setupLogoUpdated => 'Company logo updated.';

  @override
  String get setupLogoRemoved => 'Company logo removed.';

  @override
  String get setupLogoFailed => 'Could not update the logo. Try another image.';

  @override
  String get setupCurrencySection => 'Currency & fiscal year';

  @override
  String get setupCurrencySectionSubtitle =>
      'Used as the default for amounts, invoices, and reports.';

  @override
  String get setupDefaultCurrency => 'Default currency';

  @override
  String get setupFiscalYearStart => 'Fiscal year starts in';

  @override
  String get setupFiscalYearStartHelper =>
      'First month of your accounting year.';

  @override
  String get setupLegalSection => 'Legal identifiers';

  @override
  String get setupTaxNumber => 'Tax / VAT number';

  @override
  String get setupCommercialRegister => 'Commercial registration';

  @override
  String get setupContactSection => 'Contact & address';

  @override
  String get setupPhone => 'Phone';

  @override
  String get setupEmail => 'Email';

  @override
  String get setupWebsite => 'Website';

  @override
  String get setupAddress => 'Address';

  @override
  String get setupCity => 'City';

  @override
  String get setupCountry => 'Country';

  @override
  String get setupInvoiceHeaderSection => 'Sales invoice header';

  @override
  String get setupInvoiceHeaderSectionSubtitle =>
      'Text for the right and left columns around the company logo on printed invoices.';

  @override
  String get setupInvoiceHeaderRight => 'Right column text';

  @override
  String get setupInvoiceHeaderLeft => 'Left column text';

  @override
  String get setupInvoiceHeaderHelper =>
      'You can enter multiple lines (e.g. address or phone).';

  @override
  String get setupSavedSuccess => 'Setup settings saved.';

  @override
  String get settingsGeneralSection => 'General';

  @override
  String get settingsGeneralSectionSubtitle =>
      'Appearance and language for the whole app.';

  @override
  String get settingsDataSection => 'Data & sync';

  @override
  String get settingsDataSectionSubtitle =>
      'Connection status and manual synchronization.';

  @override
  String get settingsModulesSection => 'Modules';

  @override
  String get settingsModulesSectionSubtitle =>
      'Settings owned by each business module.';

  @override
  String get settingsAboutSectionSubtitle =>
      'Application identity and maintenance.';

  @override
  String get settingsResetHint =>
      'Restore theme, language, and module settings to defaults.';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get about => 'About';

  @override
  String get applicationName => 'Application Name';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get resetApplication => 'Reset Settings';

  @override
  String get resetApplicationConfirmationTitle => 'Reset settings?';

  @override
  String get resetApplicationConfirmationMessage =>
      'Theme and language preferences will be restored to defaults.';

  @override
  String get success => 'Success';

  @override
  String get failure => 'Failure';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyMessage => 'You\'re all caught up.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsUnreadBadge => 'Unread';

  @override
  String notificationsSummaryTotal(int count) {
    return '$count notifications';
  }

  @override
  String notificationsSummaryUnread(int count) {
    return '$count unread';
  }

  @override
  String get notificationsSummaryAllRead => 'All caught up';

  @override
  String get notificationsTimeJustNow => 'Just now';

  @override
  String notificationsTimeMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsTimeHours(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsTimeDays(int count) {
    return '${count}d ago';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get exitAppTitle => 'Exit Application?';

  @override
  String get exitAppMessage => 'Are you sure you want to exit the application?';

  @override
  String get exitAppConfirm => 'Exit';

  @override
  String get splashSubtitle => 'Business Management Platform';

  @override
  String get splashInitErrorTitle => 'Unable to start application';

  @override
  String get splashInitErrorMessage =>
      'Something went wrong while initializing the application.';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get errorStateSubtitle =>
      'Please try again. If the problem continues, check your data and return later.';

  @override
  String get moduleComingSoon => 'Coming soon';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationDashboard => 'Dashboard';

  @override
  String get navigationServices => 'Services';

  @override
  String get navigationReports => 'Reports';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get quickActionsSubtitle =>
      'Your pinned shortcuts. Customize to add or reorder.';

  @override
  String get quickActionsCreateProduct => 'Create product';

  @override
  String get quickActionsCreateProductSubtitle => 'Open the new product form.';

  @override
  String get quickActionsScanBarcode => 'Scan barcode or QR';

  @override
  String get quickActionsScanBarcodeSubtitle =>
      'Scan a barcode or QR and open the product.';

  @override
  String get quickActionsCustomize => 'Customize';

  @override
  String get quickActionsCustomizeTitle => 'Customize quick actions';

  @override
  String get quickActionsCustomizeHint =>
      'Choose actions to show, then drag to change their order.';

  @override
  String get quickActionsPinned => 'Pinned actions';

  @override
  String get quickActionsAvailable => 'Available actions';

  @override
  String get quickActionsAdd => 'Add';

  @override
  String get quickActionsRemove => 'Remove';

  @override
  String get quickActionsSave => 'Save';

  @override
  String quickActionsPinnedCount(int count, int max) {
    return '$count / $max pinned';
  }

  @override
  String quickActionsMaxReached(int max) {
    return 'You can pin up to $max quick actions.';
  }

  @override
  String get quickActionsEmptyPinned =>
      'No shortcuts pinned yet. Tap Customize to add some.';

  @override
  String get quickActionsEmptyMessage =>
      'Pin shortcuts here for faster access. You will be able to customize them later.';

  @override
  String get quickActionsAddLabel => 'Add action';

  @override
  String get quickActionsComingSoon =>
      'Quick action customization is coming soon.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle => 'Overview of your business platform.';

  @override
  String get dashboardOpenServices => 'Browse all services';

  @override
  String get dashboardOpenSettings => 'Open settings';

  @override
  String get dashboardMyServices => 'My services';

  @override
  String get dashboardCustomizeServices => 'Customize';

  @override
  String get dashboardCustomizeTitle => 'Customize dashboard services';

  @override
  String get dashboardCustomizeServicesHint =>
      'Choose which services appear on your dashboard, then drag to reorder.';

  @override
  String get dashboardPinnedServices => 'Pinned services';

  @override
  String get dashboardAvailableServices => 'Available services';

  @override
  String get dashboardAddService => 'Add';

  @override
  String get dashboardRemoveService => 'Remove';

  @override
  String get dashboardSaveServices => 'Save';

  @override
  String dashboardPinnedCount(int count, int max) {
    return '$count / $max pinned';
  }

  @override
  String dashboardServicesMaxReached(int max) {
    return 'You can pin up to $max dashboard services.';
  }

  @override
  String get dashboardNoServicesTitle => 'No services on dashboard';

  @override
  String get dashboardNoServicesMessage =>
      'Customize your dashboard to add the services you use most.';

  @override
  String get dashboardNoModulesAvailable => 'No services are available yet.';

  @override
  String get dashboardStatsComingSoon => 'Coming soon';

  @override
  String get dashboardStatsSlideOverviewTitle => 'Inventory';

  @override
  String get dashboardStatsSlideOverviewSubtitle =>
      'Daily performance indicators will appear here.';

  @override
  String get dashboardStatsSlideSalesTitle => 'Sales';

  @override
  String get dashboardStatsSlideSalesSubtitle =>
      'Sales summaries by period will be added later.';

  @override
  String get dashboardStatsSlideBalanceTitle => 'Collections';

  @override
  String get dashboardStatsSlideBalanceSubtitle =>
      'Customer and cash balances are coming soon.';

  @override
  String get dashboardStatsPeriodToday => 'Today';

  @override
  String get dashboardStatsPeriodWeek => 'This week';

  @override
  String get dashboardStatsPeriodMonth => 'This month';

  @override
  String get dashboardStatsCurrencyHint => 'YER';

  @override
  String get dashboardStatsItemsLabel => 'items';

  @override
  String get dashboardStatsInvoicesLabel => 'Invoices';

  @override
  String get dashboardStatsCustomersLabel => 'Active customers';

  @override
  String get dashboardStatsLowStockLabel => 'Low stock';

  @override
  String get dashboardRecentOperations => 'Recent operations';

  @override
  String get dashboardRecentOperationsEmpty => 'No recent sales yet.';

  @override
  String get dashboardRecentOperationsViewAll => 'View all';

  @override
  String get dashboardRecentSaleInvoice => 'Sales invoice';

  @override
  String dashboardRecentSaleInvoiceLine(String type, String number) {
    return 'Sales invoice $type No. $number';
  }

  @override
  String get platformReportsTitle => 'Reports';

  @override
  String get platformReportsSubtitle =>
      'Choose a module to browse its service reports.';

  @override
  String get platformReportsInventory => 'Inventory reports';

  @override
  String get platformReportsInventorySubtitle =>
      'Stock count and product reports.';

  @override
  String get platformReportsBusiness => 'Business PDF reports';

  @override
  String get platformReportsBusinessSubtitle =>
      'Sales and cross-module PDF reports with preview.';

  @override
  String get platformReportsComingSoon =>
      'Cross-module reports will be available in a future release.';

  @override
  String get platformReportsStockCountTitle => 'Stock count report';

  @override
  String get platformReportsStockCountSubtitle =>
      'Count summary, variances, and export.';

  @override
  String get platformReportsProductsTitle => 'Products report';

  @override
  String get platformReportsServiceComingSoon =>
      'Reports for this service are coming soon.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'The page you are looking for does not exist.';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get availableQuantity => 'Available Quantity';

  @override
  String get statusBreakdown => 'Status Breakdown';

  @override
  String get itemName => 'Item Name';

  @override
  String get status => 'Status';

  @override
  String get exportAs => 'Export as';

  @override
  String get exportExcel => 'Excel (.xlsx)';

  @override
  String get exportPdf => 'PDF (.pdf)';

  @override
  String exportPath(String path) {
    return 'Saved to: $path';
  }

  @override
  String get shareExport => 'Share';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String paginationPage(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String paginationRange(int from, int to, int total) {
    return '$from-$to of $total';
  }

  @override
  String get paginationItemsPerPage => 'Items per page';

  @override
  String get importParsing => 'Parsing Excel file...';

  @override
  String get importSaving => 'Saving items...';

  @override
  String get emptyWorkbook => 'The Excel file is empty or has no sheets.';

  @override
  String get noValidRows => 'No valid inventory rows were found in the file.';

  @override
  String duplicateRowsCount(int count) {
    return 'Replaced $count duplicate item codes';
  }

  @override
  String get syncSectionTitle => 'Synchronization';

  @override
  String get syncBackendLabel => 'Sync backend';

  @override
  String get syncConnectionLabel => 'Connection';

  @override
  String get syncConnectionOnline => 'Online';

  @override
  String get syncConnectionOffline => 'Offline';

  @override
  String get syncLastSyncLabel => 'Last synchronization';

  @override
  String get syncLastSyncNever => 'Never';

  @override
  String get syncPendingChangesLabel => 'Pending changes';

  @override
  String get syncFailedChangesLabel => 'Failed changes';

  @override
  String get syncNowAction => 'Sync Now';

  @override
  String get syncOfflineMessage =>
      'You\'re offline. Changes will sync automatically when an internet connection is available.';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusPending => 'Pending';

  @override
  String get syncStatusFailed => 'Sync failed';

  @override
  String get syncStatusConflict => 'Conflict';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncCompletedTitle => 'Synchronization completed';

  @override
  String get syncCompletedMessage => 'All changes have been synchronized.';

  @override
  String get syncPartialTitle => 'Some changes could not be synchronized';

  @override
  String get syncFailedTitle => 'Synchronization failed';

  @override
  String get syncFailedMessage => 'Please try again later.';

  @override
  String get loadingPleaseWait => 'Please wait…';

  @override
  String get loadingProcessing => 'Processing…';

  @override
  String get loadingSaving => 'Saving…';

  @override
  String get loadingDeleting => 'Deleting…';

  @override
  String get loadingImportingProducts => 'Importing products…';

  @override
  String get loadingImportingInventory => 'Importing inventory…';

  @override
  String get loadingSavingInventory => 'Saving inventory…';

  @override
  String get loadingSynchronizing => 'Synchronizing…';

  @override
  String get loadingExportingReport => 'Preparing report…';
}
