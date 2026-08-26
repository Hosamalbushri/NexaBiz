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
  String get moduleReceiptsPayments => 'Receipts & Payments';

  @override
  String get moduleReceiptsPaymentsDescription =>
      'Record cash and bank receipts and payments with accounting posting and offline sync.';

  @override
  String get moduleReports => 'Reports';

  @override
  String get moduleReportsDescription =>
      'Generate, preview, print, and share professional PDF reports.';

  @override
  String get rpListTitle => 'Transactions';

  @override
  String get rpListTitleReceipts => 'Receipts';

  @override
  String get rpListTitlePayments => 'Payments';

  @override
  String get rpListTitleTransfers => 'Cash box transfers';

  @override
  String get rpListTitleExchanges => 'Currency exchange';

  @override
  String get rpListCardSubtitle => 'Search and filter receipts and payments';

  @override
  String get rpActionViewAll => 'All transactions';

  @override
  String get rpActionNewReceipt => 'New receipt';

  @override
  String get rpActionNewPayment => 'New payment';

  @override
  String get rpActionNewTransfer => 'New transfer';

  @override
  String get rpActionNewExchange => 'New exchange';

  @override
  String get rpCreateReceiptSubtitle => 'Collect cash or bank into treasury';

  @override
  String get rpCreatePaymentSubtitle => 'Pay from cash or bank';

  @override
  String get rpCreateTransferSubtitle => 'Move cash between cash boxes';

  @override
  String get rpCreateExchangeSubtitle =>
      'Convert one currency to another in the same cash box';

  @override
  String get rpServiceReceiptsTitle => 'Receipts';

  @override
  String get rpServiceReceiptsSubtitle =>
      'View receipt vouchers or create a new one';

  @override
  String get rpServicePaymentsTitle => 'Payments';

  @override
  String get rpServicePaymentsSubtitle =>
      'View payment vouchers or create a new one';

  @override
  String get rpServiceTransfersTitle => 'Cash box transfers';

  @override
  String get rpServiceTransfersSubtitle =>
      'Transfer between cash boxes or create a new voucher';

  @override
  String get rpServiceExchangesTitle => 'Currency exchange';

  @override
  String get rpServiceExchangesSubtitle =>
      'View exchange vouchers or create a new one';

  @override
  String get rpServiceViewReceipts => 'All receipts';

  @override
  String get rpServiceViewReceiptsSubtitle =>
      'Browse and filter receipt vouchers';

  @override
  String get rpServiceViewPayments => 'All payments';

  @override
  String get rpServiceViewPaymentsSubtitle =>
      'Browse and filter payment vouchers';

  @override
  String get rpServiceViewTransfers => 'All transfers';

  @override
  String get rpServiceViewTransfersSubtitle =>
      'Browse and filter cash box transfer vouchers';

  @override
  String get rpServiceViewExchanges => 'All exchanges';

  @override
  String get rpServiceViewExchangesSubtitle =>
      'Browse and filter currency exchange vouchers';

  @override
  String get rpServiceCreateReceipt => 'New receipt voucher';

  @override
  String get rpServiceCreatePayment => 'New payment voucher';

  @override
  String get rpServiceCreateTransfer => 'New transfer voucher';

  @override
  String get rpServiceCreateExchange => 'New exchange voucher';

  @override
  String get rpFormTitleReceipt => 'New receipt';

  @override
  String get rpFormTitlePayment => 'New payment';

  @override
  String get rpFormTitleTransfer => 'New cash box transfer';

  @override
  String get rpFormTitleTransferEdit => 'Edit cash box transfer';

  @override
  String get rpFormTitleExchange => 'New currency exchange';

  @override
  String get rpFormTitleExchangeEdit => 'Edit currency exchange';

  @override
  String get rpTransferFromAccount => 'From cash box';

  @override
  String get rpTransferToAccount => 'To cash box';

  @override
  String get rpExchangeCashAccount => 'Cash box';

  @override
  String get rpExchangeFromCurrency => 'From currency';

  @override
  String get rpExchangeToCurrency => 'To currency';

  @override
  String get rpExchangeFromAmount => 'Amount given';

  @override
  String get rpExchangeToAmount => 'Amount received';

  @override
  String get rpEmptyTitleTransfers => 'No transfers';

  @override
  String get rpEmptyMessageTransfers =>
      'Create a cash box transfer to get started.';

  @override
  String get rpEmptyTitleExchanges => 'No exchanges';

  @override
  String get rpEmptyMessageExchanges =>
      'Create a currency exchange voucher to get started.';

  @override
  String get rpDetailsTitleTransfer => 'Transfer details';

  @override
  String get rpDetailsTitleExchange => 'Exchange details';

  @override
  String get rpDashboardTodayReceipts => 'Today\'s receipts';

  @override
  String get rpDashboardTodayPayments => 'Today\'s payments';

  @override
  String get rpDashboardPeriodReceipts => 'Period receipts';

  @override
  String get rpDashboardPeriodPayments => 'Period payments';

  @override
  String get rpDashboardNetMovement => 'Net movement';

  @override
  String get rpDashboardCashMovement => 'Cash movement';

  @override
  String get rpDashboardBankMovement => 'Bank movement';

  @override
  String get rpDashboardPendingSync => 'Pending sync';

  @override
  String get rpDashboardFailedSync => 'Failed sync';

  @override
  String get rpFormSectionDocument => 'Document';

  @override
  String get rpFormSectionAccounts => 'Accounts & amount';

  @override
  String get rpFormSectionParty => 'Party';

  @override
  String get rpFormSectionNotes => 'Reference & notes';

  @override
  String get rpFormSectionLines => 'Entry lines';

  @override
  String get rpGeneralDescription => 'Voucher description';

  @override
  String get rpDefaultGeneralDescription => 'Payment from account';

  @override
  String rpDefaultPaymentDescription(String date) {
    return 'خارج--$date';
  }

  @override
  String rpDefaultTransferDescription(String date) {
    return 'Transfer--$date';
  }

  @override
  String rpDefaultExchangeDescription(String date) {
    return 'Exchange--$date';
  }

  @override
  String get rpManualExchangeRate => 'Exchange rate';

  @override
  String rpManualExchangeRateHint(String cash, String party) {
    return '1 $cash = ? $party';
  }

  @override
  String get rpLineDescription => 'Line description';

  @override
  String get rpCurrency => 'Currency';

  @override
  String get rpCurrencyEquivalent => 'Base equivalent';

  @override
  String get rpExchangeRate => 'Rate';

  @override
  String get rpBaseCurrency => 'Base currency';

  @override
  String get rpLinesEmpty => 'No accounts added.';

  @override
  String get rpAddAccountLine => 'Add account';

  @override
  String get rpAddAnotherAccountLine => 'Add row';

  @override
  String get rpChangeAccount => 'Change account';

  @override
  String get rpEditTitle => 'Edit transaction';

  @override
  String get rpDetailsTitle => 'Transaction details';

  @override
  String get rpSave => 'Save';

  @override
  String get rpSaved => 'Transaction saved';

  @override
  String get rpSaving => 'Saving…';

  @override
  String get rpPost => 'Post';

  @override
  String get rpPosting => 'Posting…';

  @override
  String get rpPosted => 'Transaction posted';

  @override
  String get rpUnpost => 'Unpost';

  @override
  String get rpUnposting => 'Unposting…';

  @override
  String get rpUnposted => 'Transaction unposted';

  @override
  String get rpPostingServiceTitle => 'Post / Unpost';

  @override
  String get rpPostingServiceHubSubtitle =>
      'Post or unpost vouchers by type, date, or number';

  @override
  String get rpPostingServiceSubtitle =>
      'Choose voucher type and operation, then search by date range or number range. Apply to one selected voucher or to all results.';

  @override
  String get rpPostingServiceDocumentType => 'Voucher type';

  @override
  String get rpPostingServiceOperation => 'Operation';

  @override
  String get rpPostingServiceLookup => 'Find by';

  @override
  String get rpPostingServicePickDate => 'Select a date';

  @override
  String get rpPostingServiceFromDate => 'From date';

  @override
  String get rpPostingServiceToDate => 'To date';

  @override
  String get rpPostingServiceFromNumber => 'From number';

  @override
  String get rpPostingServiceToNumber => 'To number';

  @override
  String get rpPostingServiceNumberHint => 'e.g. 1';

  @override
  String get rpPostingServiceDateRequired => 'Select from and to dates';

  @override
  String get rpPostingServiceDateRangeInvalid =>
      'From date must be on or before to date';

  @override
  String get rpPostingServiceNumberRequired =>
      'Enter from and to voucher numbers';

  @override
  String get rpPostingServiceNumberRangeInvalid =>
      'From number must be less than or equal to to number';

  @override
  String get rpPostingServiceSearch => 'Show vouchers';

  @override
  String rpPostingServiceResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vouchers',
      one: '1 voucher',
      zero: 'No vouchers',
    );
    return '$_temp0';
  }

  @override
  String get rpPostingServiceEmpty => 'No matching vouchers for this filter.';

  @override
  String get rpPostingServiceSelectOne => 'Select a voucher first';

  @override
  String get rpPostingServiceApplySelectedPost => 'Post selected';

  @override
  String get rpPostingServiceApplySelectedUnpost => 'Unpost selected';

  @override
  String rpPostingServiceApplyAllPost(int count) {
    return 'Post all ($count)';
  }

  @override
  String rpPostingServiceApplyAllUnpost(int count) {
    return 'Unpost all ($count)';
  }

  @override
  String rpPostingServiceConfirmOnePost(String number) {
    return 'Post voucher $number?';
  }

  @override
  String rpPostingServiceConfirmOneUnpost(String number) {
    return 'Unpost voucher $number?';
  }

  @override
  String rpPostingServiceConfirmAllPost(int count) {
    return 'Post all $count vouchers in the list?';
  }

  @override
  String rpPostingServiceConfirmAllUnpost(int count) {
    return 'Unpost all $count vouchers in the list?';
  }

  @override
  String rpPostingServiceSuccessPost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vouchers posted',
      one: '1 voucher posted',
    );
    return '$_temp0';
  }

  @override
  String rpPostingServiceSuccessUnpost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vouchers unposted',
      one: '1 voucher unposted',
    );
    return '$_temp0';
  }

  @override
  String rpPostingServicePartial(int success, int failed) {
    return '$success succeeded, $failed failed';
  }

  @override
  String get rpPostingServiceNoPermission =>
      'You do not have permission to post or unpost vouchers.';

  @override
  String get rpCancelTitle => 'Cancel transaction';

  @override
  String rpCancelMessage(String number) {
    return 'Cancel $number? The linked accounting entry will be voided.';
  }

  @override
  String get rpCancelAction => 'Cancel transaction';

  @override
  String get rpCancelled => 'Transaction cancelled';

  @override
  String get rpLoading => 'Loading…';

  @override
  String get rpNotFound => 'Transaction not found';

  @override
  String get rpEmptyTitle => 'No transactions';

  @override
  String get rpEmptyMessage => 'Create a receipt or payment to get started.';

  @override
  String get rpEmptyTitleReceipts => 'No receipts';

  @override
  String get rpEmptyMessageReceipts =>
      'Create a receipt voucher to get started.';

  @override
  String get rpEmptyTitlePayments => 'No payments';

  @override
  String get rpEmptyMessagePayments =>
      'Create a payment voucher to get started.';

  @override
  String get rpDetailsTitleReceipt => 'Receipt details';

  @override
  String get rpDetailsTitlePayment => 'Payment details';

  @override
  String get rpSearchHint => 'Search number, party, reference…';

  @override
  String get rpTypeAll => 'All';

  @override
  String get rpTypeLabel => 'Type';

  @override
  String get rpTypeReceipt => 'Receipt';

  @override
  String get rpTypePayment => 'Payment';

  @override
  String get rpTypeTransfer => 'Transfer';

  @override
  String get rpTypeExchange => 'Exchange';

  @override
  String get rpStatusUnposted => 'Unposted';

  @override
  String get rpStatusPosted => 'Posted';

  @override
  String get rpSource => 'Source';

  @override
  String get rpSourceManualReceipt => 'Manual receipt';

  @override
  String get rpSourceManualPayment => 'Manual payment';

  @override
  String get rpSourceCustomerReceipt => 'Customer receipt';

  @override
  String get rpSourceExpensePayment => 'Expense payment';

  @override
  String get rpSourceOtherReceipt => 'Other receipt';

  @override
  String get rpSourceOtherPayment => 'Other payment';

  @override
  String get rpSourceSalesRelatedReceipt => 'Sales-related receipt';

  @override
  String get rpSourcePurchaseRelatedPayment => 'Purchase-related payment';

  @override
  String get rpSourceCashBoxTransfer => 'Cash box transfer';

  @override
  String get rpSourceCurrencyExchange => 'Currency exchange';

  @override
  String get rpDate => 'Date';

  @override
  String get rpAmount => 'Amount';

  @override
  String get rpLineAmountCredit => 'Amount (Credit)';

  @override
  String get rpLineAmountDebit => 'Amount (Debit)';

  @override
  String get rpTotalsDebit => 'Total debit';

  @override
  String get rpTotalsCredit => 'Total credit';

  @override
  String get rpTotalsDifference => 'Difference';

  @override
  String get rpCashAmount => 'Cash amount';

  @override
  String get rpCashAccount => 'Cash / bank account';

  @override
  String get rpCounterAccount => 'Counter account';

  @override
  String get rpCustomer => 'Customer';

  @override
  String get rpPartyName => 'Party name';

  @override
  String get rpNoParty => 'No party';

  @override
  String get rpReference => 'Reference';

  @override
  String get rpDescription => 'Description';

  @override
  String get rpPaymentMethod => 'Payment method';

  @override
  String get rpPaymentCash => 'Cash';

  @override
  String get rpPaymentCard => 'Card';

  @override
  String get rpPaymentBankTransfer => 'Bank transfer';

  @override
  String get rpPaymentOther => 'Other';

  @override
  String get rpVoucherBook => 'Voucher book';

  @override
  String get rpVoucherBookEmpty => 'No voucher books available';

  @override
  String get rpTransactionNumber => 'Number';

  @override
  String get rpSearchAccountHint => 'Search accounts';

  @override
  String get rpSearchCustomerHint => 'Search customers';

  @override
  String get rpCustomerNotFound => 'No customers found';

  @override
  String get rpAutocompleteSearchFailed => 'Search failed';

  @override
  String get rpErrorAmountMustBePositive => 'Amount must be greater than zero';

  @override
  String get rpErrorCounterAmountMustBePositive =>
      'Party amount must be greater than zero';

  @override
  String get rpErrorCashAccountRequired => 'Cash or bank account is required';

  @override
  String get rpErrorCounterAccountRequired => 'Counter account is required';

  @override
  String get rpErrorCustomerRequired => 'Customer is required for this source';

  @override
  String get rpErrorSameAccounts =>
      'Cash and counter accounts must be different';

  @override
  String get rpErrorCurrenciesMustDiffer =>
      'From and to currencies must be different';

  @override
  String get rpErrorVoucherBookRequired => 'Select a voucher book';

  @override
  String get rpErrorNotEditable => 'Posted transactions cannot be edited';

  @override
  String get rpErrorCannotPost => 'This transaction cannot be posted';

  @override
  String get rpErrorCannotUnpost => 'This transaction cannot be unposted';

  @override
  String get rpErrorCannotCancel => 'This transaction cannot be cancelled';

  @override
  String get rpErrorAlreadyCancelled => 'Transaction is already cancelled';

  @override
  String get rpErrorCurrencyRequired => 'Currency is required';

  @override
  String get rpErrorUnbalanced =>
      'Cannot save while debit and credit totals differ';

  @override
  String get rpErrorSavingInProgress => 'Save already in progress';

  @override
  String get rpErrorLedgerPostingFailed => 'Accounting posting failed';

  @override
  String get adminPermPackageReceiptsPaymentsHint =>
      'Receipts, payments, reports, and sync';

  @override
  String get adminPermServiceReceipts => 'Receipts';

  @override
  String get adminPermServiceReceiptsHint => 'Cash and bank receipts';

  @override
  String get adminPermServicePayments => 'Payments';

  @override
  String get adminPermServicePaymentsHint => 'Cash and bank payments';

  @override
  String get adminPermServiceTransfers => 'Cash box transfers';

  @override
  String get adminPermServiceTransfersHint => 'Transfers between cash boxes';

  @override
  String get adminPermServiceExchanges => 'Currency exchange';

  @override
  String get adminPermServiceExchangesHint =>
      'Convert currencies within a cash box';

  @override
  String get adminPermServiceRpReports => 'Reports';

  @override
  String get adminPermServiceRpReportsHint => 'Receipts and payments reports';

  @override
  String get adminPermServiceRpSync => 'Synchronization';

  @override
  String get adminPermServiceRpSyncHint => 'Sync receipts and payments';

  @override
  String get adminPermActionSync => 'Sync';

  @override
  String get reportsRpReceiptsTitle => 'Receipts report';

  @override
  String get reportsRpReceiptsSubtitle =>
      'Receipts in a period with totals from the database.';

  @override
  String get reportsRpPaymentsTitle => 'Payments report';

  @override
  String get reportsRpPaymentsSubtitle =>
      'Payments in a period with totals from the database.';

  @override
  String get reportsRpCashMovementTitle => 'Cash movement';

  @override
  String get reportsRpCashMovementSubtitle =>
      'Cash-box receipts and payments for a period.';

  @override
  String get reportsRpBankMovementTitle => 'Bank movement';

  @override
  String get reportsRpBankMovementSubtitle =>
      'Bank account receipts and payments for a period.';

  @override
  String get reportsRpCustomerReceiptsTitle => 'Customer receipts';

  @override
  String get reportsRpCustomerReceiptsSubtitle =>
      'Receipts linked to customers.';

  @override
  String get reportsRpDailySummaryTitle => 'Daily summary';

  @override
  String get reportsRpDailySummarySubtitle =>
      'Receipts and payments for a single day.';

  @override
  String get reportsRpPeriodSummaryTitle => 'Period summary';

  @override
  String get reportsRpPeriodSummarySubtitle =>
      'Aggregated receipts and payments for a date range.';

  @override
  String get reportsRpColNumber => 'Number';

  @override
  String get reportsRpColDate => 'Date';

  @override
  String get reportsRpColType => 'Type';

  @override
  String get reportsRpColParty => 'Party';

  @override
  String get reportsRpColAmount => 'Amount';

  @override
  String get reportsRpColStatus => 'Status';

  @override
  String get reportsRpTotal => 'Total';

  @override
  String get reportsRpCount => 'Count';

  @override
  String get reportsAccountingCategoryTitle => 'Accounting & Financial Reports';

  @override
  String get reportsAccountingCategorySubtitle =>
      'Account statements, trial balance, and journal book.';

  @override
  String get reportsSalesCategoryTitle => 'Sales Reports';

  @override
  String get reportsSalesCategorySubtitle =>
      'Sales figures and invoice summaries by period.';

  @override
  String get reportsRpCategoryTitle => 'Receipts & Payments Reports';

  @override
  String get reportsRpCategorySubtitle =>
      'Voucher summaries, cash, and bank movements.';

  @override
  String get reportsInventoryCategoryTitle => 'Inventory & Stock Reports';

  @override
  String get reportsInventoryCategorySubtitle =>
      'Stock levels, item balances, and store counts.';

  @override
  String get reportsCustomersCategoryTitle => 'Customer Reports';

  @override
  String get reportsCustomersCategorySubtitle =>
      'Customer directory, account details, and balances.';

  @override
  String get reportsStockBalanceTitle => 'Stock Balance Report';

  @override
  String get reportsStockBalanceSubtitle =>
      'View product stock levels, items, and inventory counts.';

  @override
  String get reportsCustomersListTitle => 'Customers Directory Report';

  @override
  String get reportsCustomersListSubtitle =>
      'View customer directory list and detailed balances.';

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
  String get reportsTrialBalanceTitle => 'Trial balance';

  @override
  String get reportsTrialBalanceSubtitle =>
      'Debit and credit totals by account in base currency for a date range.';

  @override
  String get reportsTrialBalanceColCode => 'Code';

  @override
  String get reportsTrialBalanceColName => 'Account';

  @override
  String get reportsTrialBalanceColDebit => 'Debit';

  @override
  String get reportsTrialBalanceColCredit => 'Credit';

  @override
  String get reportsTrialBalanceTotals => 'Totals';

  @override
  String get reportsTrialBalanceBalanced => 'Balanced';

  @override
  String get reportsTrialBalanceUnbalanced => 'Unbalanced';

  @override
  String get reportsTrialBalanceEmpty =>
      'No ledger activity for the selected filters.';

  @override
  String get reportsTrialBalancePostedOnly => 'Posted entries only';

  @override
  String get reportsJournalBookTitle => 'Journal book';

  @override
  String get reportsJournalBookSubtitle =>
      'Chronological journal lines in base currency for a date range.';

  @override
  String get reportsJournalBookColDate => 'Date';

  @override
  String get reportsJournalBookColVoucher => 'Voucher#';

  @override
  String get reportsJournalBookColType => 'Type';

  @override
  String get reportsJournalBookColDescription => 'Description';

  @override
  String get reportsJournalBookColAccount => 'Account';

  @override
  String get reportsJournalBookColDebit => 'Debit';

  @override
  String get reportsJournalBookColCredit => 'Credit';

  @override
  String get reportsJournalBookTotals => 'Totals';

  @override
  String get reportsJournalBookEmpty =>
      'No journal lines for the selected filters.';

  @override
  String get reportsJournalBookPostedOnly => 'Posted entries only';

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
  String salesInvoiceReference(String number) {
    return 'Ref. $number';
  }

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
  String get salesPostRequiresInventory =>
      'Posting is unavailable until inventory stock tracking is added.';

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
  String get customersImportBackgroundHint =>
      'You can leave this page and keep using the app while import runs in the background.';

  @override
  String get importBackgroundHint =>
      'You can leave this page and keep using the app while import runs in the background.';

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
  String get accountingJournalVoid => 'Reverse / void';

  @override
  String get accountingJournalVoidConfirmTitle => 'Reverse this journal?';

  @override
  String get accountingJournalVoidConfirmMessage =>
      'A balanced reversing entry will be posted. The original entry stays on the books for audit.';

  @override
  String get accountingJournalVoidedSuccess => 'Journal reversed.';

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
      'This date is not within an open accounting period. Please open the period.';

  @override
  String get accountingJournalErrorOutsideFiscalYear =>
      'This date is not within any defined fiscal year.';

  @override
  String get accountingJournalErrorPostedImmutable =>
      'Posted journals cannot be deleted. Use an accounting reversal.';

  @override
  String get accountingJournalErrorAlreadyReversed =>
      'This journal has already been reversed.';

  @override
  String get accountingJournalErrorDebitAccountMissing =>
      'A debit account (customer AR or cash) is required before ledger posting.';

  @override
  String get accountingFiscalYearsTitle => 'Fiscal years';

  @override
  String get accountingFiscalYearsSubtitle =>
      'Create fiscal years, open and close accounting periods.';

  @override
  String get accountingFiscalYearsEmptyTitle => 'No fiscal years yet';

  @override
  String get accountingFiscalYearsEmptyMessage =>
      'Create a fiscal year to control which periods accept postings.';

  @override
  String get accountingFiscalYearsAdd => 'New fiscal year';

  @override
  String get accountingFiscalYearDetails => 'Fiscal year';

  @override
  String get accountingFiscalYearCreateTitle => 'Create fiscal year';

  @override
  String get accountingFiscalYearCode => 'Code';

  @override
  String get accountingFiscalYearName => 'Name';

  @override
  String get accountingFiscalYearStart => 'Start date';

  @override
  String get accountingFiscalYearEnd => 'End date';

  @override
  String get accountingFiscalYearPeriods => 'Number of periods';

  @override
  String get accountingFiscalYearFxEnabled => 'Foreign currency revaluation';

  @override
  String get accountingFiscalYearFxGainAccount => 'FX gain account';

  @override
  String get accountingFiscalYearFxLossAccount => 'FX loss account';

  @override
  String get accountingFiscalYearPreview => 'Period preview';

  @override
  String get accountingFiscalYearCreated =>
      'Fiscal year created. Open a period before posting.';

  @override
  String accountingFiscalYearOpenPeriods(int count) {
    return 'Open periods: $count';
  }

  @override
  String accountingFiscalYearClosedPeriods(int count) {
    return 'Closed periods: $count';
  }

  @override
  String get accountingFiscalYearFxSummary => 'Foreign exchange revaluation';

  @override
  String get accountingFiscalYearFxGains => 'FX gains';

  @override
  String get accountingFiscalYearFxLosses => 'FX losses';

  @override
  String get accountingFiscalYearFxNet => 'Net FX difference';

  @override
  String get accountingFiscalYearFxDeferredHint =>
      'Automatic FX journals are deferred until base carrying amounts are stored on ledger lines.';

  @override
  String get accountingPeriodColumnNumber => '#';

  @override
  String get accountingPeriodColumnName => 'Period';

  @override
  String get accountingPeriodColumnRange => 'Date range';

  @override
  String get accountingPeriodColumnStatus => 'Status';

  @override
  String get accountingPeriodColumnActions => 'Actions';

  @override
  String get accountingPeriodStatusClosed => 'Closed';

  @override
  String get accountingPeriodStatusOpen => 'Open';

  @override
  String get accountingPeriodStatusClosing => 'Closing';

  @override
  String get accountingPeriodStatusReopened => 'Reopened';

  @override
  String get accountingPeriodOpen => 'Open';

  @override
  String get accountingPeriodClose => 'Close';

  @override
  String get accountingPeriodReopen => 'Reopen';

  @override
  String accountingPeriodOpenConfirmTitle(String name) {
    return 'Open $name?';
  }

  @override
  String accountingPeriodOpenConfirmMessage(String start, String end) {
    return 'Transactions dated between $start and $end will become available for accounting operations.';
  }

  @override
  String accountingPeriodCloseTitle(String name) {
    return 'Close $name';
  }

  @override
  String accountingPeriodCloseUnposted(int count) {
    return 'Unposted journals: $count';
  }

  @override
  String accountingPeriodCloseMissingRates(String codes) {
    return 'Missing exchange rates: $codes';
  }

  @override
  String get accountingPeriodCloseBlocked =>
      'Resolve the issues above before closing.';

  @override
  String get accountingPeriodCloseSuccess => 'Period closed.';

  @override
  String get accountingPeriodOpenSuccess => 'Period opened.';

  @override
  String accountingPeriodReopenTitle(String name) {
    return 'Reopen $name?';
  }

  @override
  String get accountingPeriodReopenReason => 'Reason';

  @override
  String get accountingPeriodReopenSuccess => 'Period reopened.';

  @override
  String get accountingFiscalWizardStepYear => 'Fiscal year';

  @override
  String get accountingFiscalWizardStepPeriods => 'Periods';

  @override
  String get accountingFiscalWizardStepFx => 'Currency';

  @override
  String get accountingFiscalWizardStepPreview => 'Preview';

  @override
  String get accountingFiscalWizardNext => 'Next';

  @override
  String get accountingFiscalWizardBack => 'Back';

  @override
  String get accountingFiscalWizardCreate => 'Create fiscal year';

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
      'Open a section, then pick a book type from the list (e.g. receipts or transfers). Each type has its own book list and add action.';

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
  String get accountingVoucherBookTypeTransfers => 'Cash box transfers';

  @override
  String get accountingVoucherBookTypeExchanges => 'Currency exchange';

  @override
  String get accountingVoucherBookTypeReceiptsPayments => 'Receipts & expenses';

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
  String get accountingFieldCodeHelper =>
      'When a parent is selected, the next code after the highest sibling is generated (e.g. 1213 → 1214).';

  @override
  String get accountingGenerateCode => 'Generate code';

  @override
  String get accountingAddChildAccount => 'Add child account';

  @override
  String get accountingImportTitle => 'Import accounts';

  @override
  String get accountingImportPageTitle => 'Import Chart of Accounts';

  @override
  String get accountingImportSubtitle =>
      'Choose a parent group, load Excel or add rows, then save with optional opening balances.';

  @override
  String get accountingImportParent => 'Parent group account';

  @override
  String get accountingImportOpeningDebit => 'Opening debit';

  @override
  String get accountingImportOpeningCredit => 'Opening credit';

  @override
  String get accountingImportCurrency => 'Currency';

  @override
  String get accountingImportRowsTitle => 'Accounts to import';

  @override
  String get accountingImportAddRow => 'Add row';

  @override
  String get accountingImportRemoveRow => 'Remove row';

  @override
  String get accountingImportEmptyRows =>
      'No rows yet. Pick an Excel file or add a row.';

  @override
  String get accountingImportFormatHintTitle => 'Excel layout for accounts';

  @override
  String get accountingImportFormatHintIntro =>
      'First row = headers. Required: name. Use .xlsx or .xls. All rows are created under the selected parent group.';

  @override
  String get accountingImportFormatColCodeAliases =>
      'Account Code · Code · رمز الحساب';

  @override
  String get accountingImportFormatColNameAliases =>
      'Account Name · Name · اسم الحساب';

  @override
  String get accountingImportFormatColDebitAliases =>
      'Opening Debit · Debit · مدين افتتاحي';

  @override
  String get accountingImportFormatColCreditAliases =>
      'Opening Credit · Credit · دائن افتتاحي';

  @override
  String get accountingImportFormatColCurrencyAliases =>
      'Currency · Currency Code · عملة';

  @override
  String get accountingImportFormatSampleNote =>
      'Without headers columns are read as: code, name, opening debit, opening credit, currency. Duplicate codes are skipped. Opening amounts post one journal against Capital (3100), balanced per currency.';

  @override
  String accountingImportInsertedCount(int count) {
    return 'Inserted $count accounts';
  }

  @override
  String accountingImportSkippedCount(int count) {
    return 'Skipped $count duplicates';
  }

  @override
  String get accountingImportOpeningPosted =>
      'Opening balances journal posted against Capital.';

  @override
  String get accountingImportOpeningVoucherType => 'Opening';

  @override
  String get accountingImportOpeningJournalDescription =>
      'Opening balances from account import';

  @override
  String get accountingImportErrorParentRequired =>
      'Select a parent group account.';

  @override
  String get accountingImportErrorParentNotGroup =>
      'The parent must be a group account.';

  @override
  String get accountingImportErrorNoRows =>
      'Add at least one account with a name.';

  @override
  String get accountingImportErrorBothSides =>
      'A row cannot have both opening debit and credit.';

  @override
  String get accountingImportErrorCapitalMissing =>
      'Capital account (3100) was not found.';

  @override
  String get accountingOpeningSetupTitle => 'Opening import center';

  @override
  String get accountingOpeningSetupSubtitle =>
      'Import accounts, set multi-currency opening balances for any posting account, then post one journal against Capital (3100).';

  @override
  String get accountingOpeningSetupStepImport => 'Import';

  @override
  String get accountingOpeningSetupStepBalances => 'Balances';

  @override
  String get accountingOpeningSetupStepReview => 'Review';

  @override
  String get accountingOpeningSetupStepImportHint =>
      'Create posting accounts under a parent group. Opening amounts are entered in the next step.';

  @override
  String get accountingOpeningSetupStepBalancesHint =>
      'Add posting accounts and enter one currency line per configured currency (debit or credit). Only currencies enabled in Currency rates are available.';

  @override
  String get accountingOpeningSetupStepReviewHint =>
      'Review totals per currency, then post a single opening journal offset to Capital.';

  @override
  String get accountingOpeningSetupImportFormatIntro =>
      'First row = headers. Required: name. Use .xlsx or .xls. All rows are created under the selected parent group.';

  @override
  String get accountingOpeningSetupImportFormatNote =>
      'Without headers columns are read as: code, name. Duplicate codes are skipped. Balances are set in step 2.';

  @override
  String get accountingOpeningSetupAddAccount => 'Add posting account';

  @override
  String get accountingOpeningSetupRemoveAccount => 'Remove account';

  @override
  String get accountingOpeningSetupAddCurrencyLine => 'Add currency line';

  @override
  String get accountingOpeningSetupImportBalancesExcel =>
      'Import balances from Excel';

  @override
  String get accountingOpeningSetupEmptyBalances =>
      'No balance lines yet. Add a row or import balances from Excel.';

  @override
  String get accountingOpeningSetupContinueToReview => 'Continue to review';

  @override
  String get accountingOpeningSetupBalancesRowsTitle => 'Opening balance lines';

  @override
  String get accountingOpeningSetupBalancesFormatTitle =>
      'Excel layout for opening balances';

  @override
  String get accountingOpeningSetupBalancesFormatNote =>
      'Columns: Code or Account Id, Currency, Debit, Credit. Currency must already be enabled in Currency rates. Same account may appear once per currency. Rows merge into the current list.';

  @override
  String accountingOpeningSetupErrorCurrencyNotConfigured(String code) {
    return 'Currency is not configured in the system: $code';
  }

  @override
  String get accountingOpeningSetupErrorAccountRequired =>
      'Select an account for every balance line.';

  @override
  String get accountingOpeningSetupReviewSummaryTitle => 'Summary by currency';

  @override
  String accountingOpeningSetupCapitalOffset(String code) {
    return 'Offset account: Capital ($code)';
  }

  @override
  String accountingOpeningSetupNetVsCapital(String amount, String side) {
    return 'Capital offset: $amount ($side)';
  }

  @override
  String accountingOpeningSetupLinesCount(int count) {
    return '$count balance lines with amounts';
  }

  @override
  String get accountingOpeningSetupNoAmountsToPost =>
      'Enter at least one debit or credit amount before posting.';

  @override
  String get accountingOpeningSetupPostJournal => 'Post opening journal';

  @override
  String get accountingOpeningSetupPosting => 'Posting opening journal…';

  @override
  String get accountingOpeningSetupPostSuccess =>
      'Opening journal posted successfully against Capital.';

  @override
  String get accountingOpeningSetupJournalDescription => 'Opening balances';

  @override
  String get accountingOpeningSetupReset => 'Reset session';

  @override
  String get accountingOpeningSetupCardTitle => 'Import & opening balances';

  @override
  String get accountingOpeningSetupCardSubtitle =>
      'Import CoA accounts and post multi-currency opening balances.';

  @override
  String accountingOpeningSetupErrorDuplicateCurrency(String name) {
    return 'Duplicate currency for account: $name';
  }

  @override
  String accountingOpeningSetupErrorAccountNotFound(String code) {
    return 'Account not found: $code';
  }

  @override
  String get accountingOpeningSetupErrorNoBalanceRows =>
      'No valid opening-balance rows found in the file.';

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
  String get accountingAccountCashBoxes => 'Cash Boxes';

  @override
  String get accountingAccountCash => 'Main Cash Box';

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
  String get accountingAccountFxGain => 'Foreign Exchange Gains';

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
  String get accountingAccountFxLoss => 'Foreign Exchange Losses';

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
  String get systemSetupStepSeed => 'Chart of accounts';

  @override
  String get systemSetupStepSeedHint =>
      'Create the chart locally (first device) or sync it from your company server (joining device).';

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
  String get systemSetupSeedCreateLocalTitle => 'Create locally';

  @override
  String get systemSetupSeedCreateLocalSubtitle =>
      'Build the default chart of accounts on this device. Use this on the first device or when offline.';

  @override
  String get systemSetupSeedSyncTitle => 'Sync from server';

  @override
  String get systemSetupSeedSyncSubtitle =>
      'Sign in and enter the app. The company chart downloads in the background so you do not create a duplicate.';

  @override
  String get systemSetupSeedSyncRunning => 'Downloading chart of accounts…';

  @override
  String get systemSetupSeedSyncDone =>
      'You can enter the app now. Chart sync continues in the background.';

  @override
  String get systemSetupSeedSignInToSync => 'Sign in to sync';

  @override
  String get systemSetupSeedErrorSyncRequired =>
      'Turn on sync and sign in, then try again.';

  @override
  String get systemSetupSeedErrorAuth =>
      'Sign in to the company server, then try again.';

  @override
  String get systemSetupSeedErrorOffline =>
      'Connect to the internet to sync the chart of accounts.';

  @override
  String get systemSetupSeedErrorEmpty =>
      'No chart of accounts on the server yet. Create it locally on the first device, sync there, then retry here.';

  @override
  String get systemSetupSeedErrorPull =>
      'Could not download the chart of accounts. Try again.';

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
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get leave => 'Leave';

  @override
  String get splashSubtitle => 'Business Management Platform';

  @override
  String get splashInitErrorTitle => 'Unable to start application';

  @override
  String get splashInitErrorMessage =>
      'Something went wrong while initializing the application.';

  @override
  String get appLockTitle => 'App locked';

  @override
  String get appLockSubtitle =>
      'Enter your PIN to continue. This protects the app on this device — you are still signed in.';

  @override
  String get appLockPinLabel => 'PIN';

  @override
  String get appLockConfirmPinLabel => 'Confirm PIN';

  @override
  String get appLockCurrentPinLabel => 'Current PIN';

  @override
  String get appLockNewPinLabel => 'New PIN';

  @override
  String get appLockUnlockAction => 'Unlock';

  @override
  String get appLockShowPin => 'Show PIN';

  @override
  String get appLockHidePin => 'Hide PIN';

  @override
  String get appLockErrorInvalid => 'Incorrect PIN. Try again.';

  @override
  String get appLockErrorLockout =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get appLockErrorLength => 'PIN must be 4 to 6 digits.';

  @override
  String get appLockErrorDigits => 'PIN must contain digits only.';

  @override
  String get appLockErrorMismatch => 'PIN confirmation does not match.';

  @override
  String get appLockSettingsSection => 'Security';

  @override
  String get appLockSettingsTitle => 'App Lock';

  @override
  String get appLockSettingsEnabledHint =>
      'PIN required when returning to the app.';

  @override
  String get appLockSettingsDisabledHint =>
      'Add a PIN to protect this app locally.';

  @override
  String get appLockEnableTitle => 'Enable App Lock';

  @override
  String get appLockEnableMessage =>
      'Choose a 4–6 digit PIN. You will need it whenever the app is locked.';

  @override
  String get appLockDisableTitle => 'Disable App Lock';

  @override
  String get appLockDisableMessage =>
      'Enter your current PIN to turn off App Lock.';

  @override
  String get appLockChangePin => 'Change PIN';

  @override
  String get appLockChangePinHint => 'Update your current PIN.';

  @override
  String get appLockBiometricTitle => 'Unlock with fingerprint';

  @override
  String get appLockBiometricHint =>
      'Use fingerprint or device biometrics to unlock.';

  @override
  String get appLockBiometricUnavailable =>
      'Biometrics are not available on this device.';

  @override
  String get appLockBiometricPrompt => 'Authenticate to unlock NexaBiz';

  @override
  String get appLockBiometricEnabledSuccess => 'Fingerprint unlock is on.';

  @override
  String get appLockBiometricUnlockAction => 'Use fingerprint';

  @override
  String get appLockPolicyLabel => 'When to lock';

  @override
  String get appLockPolicyDisabled => 'Disabled';

  @override
  String get appLockPolicyOnResume => 'When returning from background';

  @override
  String get appLockPolicyOnResumeHint =>
      'Asks for PIN after the app was in the background.';

  @override
  String get appLockPolicyColdStart => 'Only when reopening the app';

  @override
  String get appLockPolicyColdStartHint =>
      'Asks for PIN after the app was fully closed.';

  @override
  String get appLockEnabledSuccess => 'App Lock is on.';

  @override
  String get appLockDisabledSuccess => 'App Lock is off.';

  @override
  String get appLockPinChangedSuccess => 'PIN updated.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingPage1Title => 'Welcome to NexaBiz';

  @override
  String get onboardingPage1Body =>
      'Your offline-first platform for running inventory, sales, customers, and accounting in one place.';

  @override
  String get onboardingPage2Title => 'Works fully offline';

  @override
  String get onboardingPage2Body =>
      'Use inventory, sales, and accounting on this device without a network. Synchronization is optional — enable it later from Settings only if you need multi-device sync.';

  @override
  String get onboardingPage3Title => 'Set up your company';

  @override
  String get onboardingPage3Body =>
      'Next you will configure company details, currency, and how the system should run for your business.';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get permissionDenied =>
      'You do not have permission to perform this action.';

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
  String get importLinking => 'Linking Chart of Accounts…';

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
  String get syncEnabledTitle => 'Enable synchronization';

  @override
  String get syncEnabledSubtitle =>
      'Optional. Keep data on this device only, or authenticate with the server to sync across devices.';

  @override
  String get syncDisabledMessage =>
      'Synchronization is turned off. Local data stays on this device.';

  @override
  String get syncAuthRequiredHint =>
      'Sign in with your server account. Synchronization stays off until authentication succeeds.';

  @override
  String get syncAuthCancelled =>
      'Synchronization was not enabled. Authentication is required.';

  @override
  String get syncPermissionRequired =>
      'This account cannot synchronize. Ask an admin to grant sync.view or sync.execute on your role.';

  @override
  String get syncSessionAuthenticated =>
      'Authenticated synchronization session is active.';

  @override
  String syncSessionAsUser(String email) {
    return 'Signed in as $email';
  }

  @override
  String get syncSessionExpired =>
      'Session expired. Sign in again to continue syncing.';

  @override
  String get syncAutoTitle => 'Automatic synchronization';

  @override
  String get syncAutoSubtitle =>
      'Sync in the background without blocking the app. You can still tap Sync Now anytime.';

  @override
  String get syncAutoIntervalLabel => 'Frequency';

  @override
  String get syncAutoIntervalOnChange => 'When there are pending changes';

  @override
  String syncAutoIntervalMinutes(int minutes) {
    return 'Every $minutes minutes';
  }

  @override
  String get syncDisableRequestSent =>
      'A request was sent to the administrator. Synchronization stays on until they approve.';

  @override
  String get syncDisableRequestFailed =>
      'Could not notify the administrator. Check your connection and try again.';

  @override
  String get syncDisableNeedsAdminOnline =>
      'Only an administrator can disable sync. Connect and sign in to send a request.';

  @override
  String get adminDevicesTitle => 'Devices';

  @override
  String get adminDevicesSubtitle =>
      'Registered devices and sync-disable requests';

  @override
  String adminDevicesPendingCount(int count) {
    return '$count pending disable requests';
  }

  @override
  String get adminDevicesListIntro =>
      'See every device linked to this company. Revoke a device to end its sessions and block further sync.';

  @override
  String get adminDevicesListSection => 'Registered devices';

  @override
  String get adminDevicesRequestsSection => 'Sync-disable requests';

  @override
  String get adminDevicesListEmptyTitle => 'No devices yet';

  @override
  String get adminDevicesListEmptyMessage =>
      'Devices appear here after a user signs in for synchronization.';

  @override
  String get adminDevicesListLoadError => 'Could not load devices';

  @override
  String get adminDevicesUntitled => 'Unnamed device';

  @override
  String get adminDevicesStatusActive => 'Active';

  @override
  String get adminDevicesStatusRevoked => 'Revoked';

  @override
  String get adminDevicesStatusBlocked => 'Blocked';

  @override
  String get adminDevicesLastSeenNever => 'Last seen: never';

  @override
  String adminDevicesLastSeen(String when) {
    return 'Last seen: $when';
  }

  @override
  String get adminDevicesRevokeAction => 'Revoke';

  @override
  String get adminDevicesRevokeCancel => 'Cancel';

  @override
  String get adminDevicesRevokeConfirmTitle => 'Revoke this device?';

  @override
  String get adminDevicesRevokeConfirmMessage =>
      'The device will lose sync access immediately. The user must sign in again on a new registration.';

  @override
  String get adminDevicesRevokeSuccess => 'Device revoked.';

  @override
  String get adminDevicesDisableRequestsIntro =>
      'Users who are not administrators cannot turn sync off themselves. Approve to disable sync on their device, or reject to keep it enabled.';

  @override
  String get adminDevicesDisableRequestHint =>
      'This user asked to disable synchronization on their device.';

  @override
  String get adminDevicesApproveAction => 'Disable on device';

  @override
  String get adminDevicesRejectAction => 'Keep syncing';

  @override
  String get adminDevicesApproveSuccess => 'Device sync will be disabled.';

  @override
  String get adminDevicesRejectSuccess =>
      'Request rejected. Sync stays enabled.';

  @override
  String get adminDevicesEmptyTitle => 'No pending requests';

  @override
  String get adminDevicesEmptyMessage =>
      'When a user asks to disable sync, the request appears here.';

  @override
  String get adminDevicesLoadError => 'Could not load device requests';

  @override
  String get adminDevicesRefresh => 'Refresh';

  @override
  String get adminDevicesUnknownUser => 'Unknown user';

  @override
  String get syncServerSectionTitle => 'Sync server';

  @override
  String get syncServerUrlLabel => 'Server URL';

  @override
  String get syncServerUrlHint => 'http://192.168.1.10:8000';

  @override
  String get syncServerUrlRequired => 'Enter the sync server URL first.';

  @override
  String get syncServerUrlInvalid =>
      'Enter a valid URL including http:// or https://.';

  @override
  String get syncServerTokenLabel => 'API token (optional)';

  @override
  String get syncServerTokenHint => 'Leave blank to keep the current token';

  @override
  String get syncServerSaveAction => 'Save server';

  @override
  String get syncServerSaved => 'Server settings saved.';

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
  String syncLastPassMetrics(int uploaded, int downloaded, int ms) {
    return 'Last pass: ↑$uploaded ↓$downloaded · $ms ms';
  }

  @override
  String get syncPendingChangesLabel => 'Pending changes';

  @override
  String get syncFailedChangesLabel => 'Failed changes';

  @override
  String get syncNowAction => 'Sync Now';

  @override
  String get syncCheckIncomingAction => 'Get server changes';

  @override
  String get syncCheckingIncoming => 'Checking server…';

  @override
  String get syncOfflineMessage =>
      'You\'re offline. Connect to the internet, then tap Sync Now.';

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
  String get syncStatusRejected => 'Not authorized';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncCompletedTitle => 'Synchronization completed';

  @override
  String get syncCompletedMessage => 'All changes have been synchronized.';

  @override
  String get syncIncomingNone => 'No new changes from the server.';

  @override
  String syncIncomingCount(int count) {
    return '$count changes received from the server';
  }

  @override
  String syncIncomingSummary(int count, String details) {
    return '$count from server: $details';
  }

  @override
  String syncIncomingEntityCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get syncIncomingFromServerTitle => 'From server';

  @override
  String get syncEntityProduct => 'Products';

  @override
  String get syncEntityInventoryItem => 'Stock items';

  @override
  String get syncEntityCustomer => 'Customers';

  @override
  String get syncEntityAccount => 'Accounts';

  @override
  String get syncEntityJournalEntry => 'Journal entries';

  @override
  String get syncEntitySale => 'Sales';

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

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle =>
      'Sign in to sync securely across your devices.';

  @override
  String get authLoginLocalHint =>
      'Sign in with your local offline account. You must change the default admin password before using the app.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSigningIn => 'Signing in…';

  @override
  String get authChangePasswordTitle => 'Change password';

  @override
  String get authChangePasswordHint =>
      'The default admin password cannot be used in production. Choose a new password of at least 8 characters.';

  @override
  String get authCurrentPasswordLabel => 'Current password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authConfirmPasswordLabel => 'Confirm new password';

  @override
  String get authChangePasswordAction => 'Save password';

  @override
  String get authChangingPassword => 'Saving…';

  @override
  String get authPasswordMismatch => 'Passwords do not match.';

  @override
  String get authPasswordWrongCurrent => 'Current password is incorrect.';

  @override
  String get authPasswordSameAsDefault =>
      'Choose a password other than the default bootstrap password.';

  @override
  String get authBiometricSignIn => 'Sign in with fingerprint';

  @override
  String get authBiometricPrompt => 'Authenticate to sign in to sync';

  @override
  String get authBiometricSaveForNext => 'Use fingerprint next time';

  @override
  String get authBiometricUnavailable =>
      'Fingerprint is not available on this device.';

  @override
  String get authBiometricRequiredFirst =>
      'Please sign in with your email and password first to enable fingerprint.';

  @override
  String get authBiometricPromptReason =>
      'Authenticate to sign in quickly using fingerprint';

  @override
  String get authBiometricFailed =>
      'Fingerprint authentication failed. Try again or use your password.';

  @override
  String get authLoginFailed => 'Invalid email or password.';

  @override
  String get authNetworkError =>
      'Cannot reach the server. Check Wi‑Fi and API address.';

  @override
  String get authLoginGenericError => 'Sign-in failed. Please try again.';

  @override
  String get authSelectCompanyTitle => 'Select company';

  @override
  String get authLogoutAction => 'Sign out';

  @override
  String get authSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get moduleAdministration => 'Administration';

  @override
  String get moduleAdministrationDescription =>
      'Users, roles, and access control';

  @override
  String get adminRequiresOnlineTitle => 'Online required';

  @override
  String get adminRequiresOnlineMessage =>
      'User management needs an authenticated sync session and network connection.';

  @override
  String get adminUsersTitle => 'Users';

  @override
  String get adminUsersSubtitle => 'Create and manage application users';

  @override
  String get adminRolesTitle => 'Roles & permissions';

  @override
  String get adminRolesSubtitle =>
      'Create roles and assign the permissions you need';

  @override
  String get adminRolesHubSubtitle =>
      'Build custom roles and control what each role can do';

  @override
  String get adminAccessControlSection => 'Access control';

  @override
  String get adminAccessControlIntro =>
      'Manage who can use the app and what they can see or change. Roles package permissions; users receive a role.';

  @override
  String get adminAccessControlTip =>
      'Tip: create a role first, pick permissions carefully (especially accounting), then assign the role when creating a user.';

  @override
  String get adminPermissionsCatalogTitle => 'Permission catalog';

  @override
  String get adminPermissionsCatalogSubtitle =>
      'Browse every available permission by module';

  @override
  String get adminPermissionsCatalogIntro =>
      'These are the building blocks of access control. Attach them to roles — never hard-code them into screens.';

  @override
  String get adminRolesPageIntro =>
      'Custom roles are fully editable. System roles come from the server and are protected.';

  @override
  String get adminRolesSearchHint => 'Search roles by name';

  @override
  String get adminRolesFilterAll => 'All';

  @override
  String get adminRolesFilterCustom => 'Custom';

  @override
  String get adminRolesFilterSystem => 'System';

  @override
  String get adminRolesStatTotal => 'Total';

  @override
  String get adminSystemRoleHint => 'Built-in role maintained by the server';

  @override
  String get adminCustomRoleHint =>
      'Your role — edit name and permissions anytime';

  @override
  String get adminTapToConfigure => 'Tap to configure';

  @override
  String get adminUsersSearchHint => 'Search by name or email';

  @override
  String get adminUsersLoadError => 'Could not load users';

  @override
  String get adminUsersEmptyTitle => 'No users';

  @override
  String get adminUsersEmptyMessage => 'Create a user to grant access.';

  @override
  String get adminCreateUser => 'Create user';

  @override
  String get adminEditUser => 'Edit user';

  @override
  String get adminSuspendUser => 'Suspend';

  @override
  String get adminActivateUser => 'Activate';

  @override
  String get adminDeactivateUser => 'Deactivate';

  @override
  String get adminUserUpdated => 'User updated';

  @override
  String get adminUserNameLabel => 'Name';

  @override
  String get adminUserPhoneLabel => 'Phone';

  @override
  String get adminUserStatusLabel => 'Status';

  @override
  String get adminUserRoleLabel => 'Role';

  @override
  String get adminStatusActive => 'Active';

  @override
  String get adminStatusInactive => 'Inactive';

  @override
  String get adminStatusSuspended => 'Suspended';

  @override
  String get adminNewPasswordOptional => 'New password (optional)';

  @override
  String get adminConfirmPasswordLabel => 'Confirm password';

  @override
  String get adminUserValidationError => 'Name and email are required.';

  @override
  String get adminPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get adminPasswordMismatch => 'Passwords do not match.';

  @override
  String get adminRolesLoadError => 'Could not load roles';

  @override
  String get adminRolesEmptyTitle => 'No roles';

  @override
  String get adminRolesEmptyMessage =>
      'Create a custom role and pick its permissions.';

  @override
  String get adminSystemRole => 'System role';

  @override
  String get adminCustomRole => 'Custom role';

  @override
  String get adminCreateRole => 'Create role';

  @override
  String get adminEditRole => 'Edit role';

  @override
  String get adminDeleteRole => 'Delete role';

  @override
  String adminDeleteRoleConfirm(String name) {
    return 'Delete role \"$name\"? Users with this role keep their account but lose these permissions until reassigned.';
  }

  @override
  String get adminRoleDeleted => 'Role deleted';

  @override
  String get adminRoleNameLabel => 'Role name';

  @override
  String get adminRoleNameHint => 'e.g. Sales employee';

  @override
  String get adminRoleDescriptionLabel => 'Description';

  @override
  String get adminRoleDescriptionHint => 'What this role is for';

  @override
  String get adminRoleBasicsSection => 'Role details';

  @override
  String get adminRoleBasicsHint =>
      'Give the role a clear name so admins can assign it confidently.';

  @override
  String get adminRoleCapabilitiesSection => 'What this role can open';

  @override
  String get adminRoleCapabilitiesHint =>
      'Updates live as you toggle permissions below.';

  @override
  String get adminRolePermissionsSection => 'Permissions';

  @override
  String get adminRoleVisibleModules => 'Modules this role can open';

  @override
  String get adminRoleNoModulesYet =>
      'No modules yet — select at least one .view permission.';

  @override
  String get adminSelectAllPermissions => 'Select all';

  @override
  String get adminClearPermissions => 'Clear';

  @override
  String get adminRoleNameRequired => 'Role name is required.';

  @override
  String get adminRolePermissionsRequired => 'Select at least one permission.';

  @override
  String get adminPermissionsSearchHint => 'Search by name, action, or code';

  @override
  String get adminPermissionsLoadError => 'Could not load permissions';

  @override
  String get adminPermissionsEmptyTitle => 'No matches';

  @override
  String get adminPermissionsEmptyMessage =>
      'Try another search or clear the module filter.';

  @override
  String adminPermissionCount(int count) {
    return '$count permissions';
  }

  @override
  String adminSelectedPermissionsCount(int count) {
    return '$count selected';
  }

  @override
  String adminGroupPermissionSummary(int selected, int total) {
    return '$selected of $total';
  }

  @override
  String get adminSystemRoleReadOnly =>
      'System roles are protected. Permission changes may be restricted.';

  @override
  String get adminPermActionView => 'View';

  @override
  String get adminPermActionCreate => 'Create';

  @override
  String get adminPermActionUpdate => 'Update';

  @override
  String get adminPermActionDelete => 'Delete';

  @override
  String get adminPermActionManage => 'Manage';

  @override
  String get adminPermActionAdjust => 'Adjust';

  @override
  String get adminPermActionPost => 'Post';

  @override
  String get adminPermActionCancel => 'Cancel';

  @override
  String get adminPermActionExecute => 'Execute';

  @override
  String get adminPermActionRevoke => 'Revoke';

  @override
  String get adminPermResourceAccounts => 'Accounts';

  @override
  String get adminPermResourceJournals => 'Journals';

  @override
  String get adminPermResourceDevices => 'Devices';

  @override
  String get adminPermResourceCompanies => 'Companies';

  @override
  String get adminPermGroupSalesHint => 'Sales documents and posting';

  @override
  String get adminPermGroupCustomersHint => 'Customer master data';

  @override
  String get adminPermGroupInventoryHint => 'Products and stock';

  @override
  String get adminPermGroupAccountingHint => 'Sensitive financial access';

  @override
  String get adminPermGroupReportsHint => 'Reports and exports';

  @override
  String get adminPermGroupAdminHint => 'Users, roles, and platform control';

  @override
  String get adminPermGroupSettingsHint => 'Application settings';

  @override
  String get adminPermGroupSyncHint => 'Synchronization actions';

  @override
  String get adminPermGroupOtherHint => 'Other permissions';

  @override
  String get adminPermTreeHint =>
      'Organized like the app: Package → Service → Operation. Example: Inventory → Stock count → Import.';

  @override
  String get adminPermTreeCatalogIntro =>
      'Full map of packages, their services, and every operation you can grant on a role.';

  @override
  String get adminPermPackagePlatform => 'Platform';

  @override
  String get adminPermPackageInventoryHint =>
      'Stock count and products services';

  @override
  String get adminPermPackageSalesHint => 'Sales documents and invoices';

  @override
  String get adminPermPackageCustomersHint =>
      'Customers, accounts, and settings';

  @override
  String get adminPermPackageAccountingHint =>
      'Accounts, journals, rates, voucher books';

  @override
  String get adminPermPackageReportsHint => 'Operational and financial reports';

  @override
  String get adminPermPackageAdminHint => 'Users, roles, and permissions';

  @override
  String get adminPermPackagePlatformHint =>
      'Settings, sync, devices, companies';

  @override
  String adminPermPackageSummary(int services, int selected, int total) {
    return '$services services · $selected/$total operations';
  }

  @override
  String get adminPermServiceSalesDocuments => 'Sales documents';

  @override
  String get adminPermServiceSalesDocumentsHint =>
      'List, create, post, cancel, and print invoices';

  @override
  String get adminPermServiceCustomersMaster => 'Customer list';

  @override
  String get adminPermServiceCustomersMasterHint =>
      'Create and manage customers';

  @override
  String get adminPermServiceCustomersAccounts => 'Customer accounts';

  @override
  String get adminPermServiceCustomersAccountsHint =>
      'Browse linked chart of accounts';

  @override
  String get adminPermServiceCustomersSettings => 'Customer settings';

  @override
  String get adminPermServiceCustomersSettingsHint =>
      'Parent account and auto-link options';

  @override
  String get adminPermServiceChartOfAccounts => 'Chart of accounts';

  @override
  String get adminPermServiceChartOfAccountsHint =>
      'Create and maintain accounts';

  @override
  String get adminPermServiceJournals => 'Journal entries';

  @override
  String get adminPermServiceJournalsHint => 'Create and manage journals';

  @override
  String get adminPermServiceCurrencyRates => 'Currency rates';

  @override
  String get adminPermServiceCurrencyRatesHint => 'Exchange rates maintenance';

  @override
  String get adminPermServiceVoucherBooks => 'Voucher books';

  @override
  String get adminPermServiceVoucherBooksHint =>
      'Numbering books by document type';

  @override
  String get adminPermServiceFiscalYears => 'Fiscal years';

  @override
  String get adminPermServiceFiscalYearsHint =>
      'Fiscal years and accounting periods';

  @override
  String get adminPermActionOpenPeriod => 'Open period';

  @override
  String get adminPermActionClosePeriod => 'Close period';

  @override
  String get adminPermActionReopenPeriod => 'Reopen period';

  @override
  String get adminPermActionConfigureFx => 'Configure FX revaluation';

  @override
  String get adminPermServiceAccountingReports => 'Accounting reports';

  @override
  String get adminPermServiceAccountingReportsHint => 'Accounting report hub';

  @override
  String get adminPermServiceSalesPeriod => 'Sales period report';

  @override
  String get adminPermServiceSalesPeriodHint => 'Sales by period with export';

  @override
  String get adminPermServiceAccountStatement => 'Account statement';

  @override
  String get adminPermServiceAccountStatementHint =>
      'Customer / account statement with export';

  @override
  String get adminPermServiceTrialBalance => 'Trial balance';

  @override
  String get adminPermServiceTrialBalanceHint =>
      'Trial balance report with export';

  @override
  String get adminPermServiceJournalBook => 'Journal book';

  @override
  String get adminPermServiceJournalBookHint =>
      'Journal book report with export';

  @override
  String get adminPermServiceDevicesHint => 'Registered sync devices';

  @override
  String get adminPermServiceCompaniesHint =>
      'Company profile and platform company tools';

  @override
  String get adminPermOpStockCount => 'Perform stock count';

  @override
  String get adminPermOpImport => 'Import';

  @override
  String get adminPermOpExport => 'Export';

  @override
  String get adminPermOpReportsExport => 'View / export reports';

  @override
  String get adminPermOpClear => 'Clear data';

  @override
  String get adminPermOpBarcode => 'Barcodes & labels';

  @override
  String get adminPermOpDuplicate => 'Duplicate';

  @override
  String get adminPermOpInvoiceExport => 'Print / share invoice';

  @override
  String get adminPermOpPlatformCompanies => 'Manage companies (platform)';

  @override
  String get adminPermOpPlatformUsers => 'Manage users (platform)';

  @override
  String get setupChoiceTitle => 'How would you like to set up?';

  @override
  String get setupChoiceSubtitle =>
      'Choose how NexaBiz manages your business data';

  @override
  String get setupChoiceServerTitle => 'Connect to Server';

  @override
  String get setupChoiceServerSubtitle =>
      'Sync data across multiple devices with a central server';

  @override
  String get setupChoiceLocalTitle => 'Use Locally';

  @override
  String get setupChoiceLocalSubtitle =>
      'Run everything on this device, no internet required';

  @override
  String get serverSetupTitle => 'Connect to Server';

  @override
  String get serverSetupSubtitle =>
      'Enter your sync server address to get started';

  @override
  String get serverSetupUrlLabel => 'Server Address';

  @override
  String get serverSetupUrlHint => 'http://192.168.1.10:8000';

  @override
  String get serverSetupValidate => 'Check Connection';

  @override
  String get serverSetupValidating => 'Checking server connection...';

  @override
  String get serverSetupValidSuccess => 'Server connected successfully';

  @override
  String get serverSetupValidFailed => 'Could not connect to server';

  @override
  String get serverSetupContinueToSignIn => 'Continue to Sign In';

  @override
  String get serverSetupBackToChoice => 'Back to setup options';

  @override
  String get onboardingWelcomeTitle => 'Welcome to NexaBiz';

  @override
  String get onboardingWelcomeSubtitle =>
      'Your complete business management platform. Let\'s get you set up in just a few steps.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get authServerUrlRequired => 'Please enter server URL';

  @override
  String authServerVerificationFailed(int statusCode) {
    return 'Could not verify server (Status code: $statusCode)';
  }

  @override
  String get authServerConnectionError =>
      'Could not connect to server. Please check the URL and network connection.';

  @override
  String get authSyncModeLabel => 'Sync Mode';

  @override
  String get authLocalModeLabel => 'Offline Mode';

  @override
  String get authSwitchToLocalMode => 'Switch to Offline Mode';

  @override
  String get authSwitchToSyncMode => 'Switch to Server Sync Mode';

  @override
  String get authServerSetupTitle => 'Server Setup';

  @override
  String get authServerSetupSubtitle =>
      'Enter server URL and verify connection before signing in.';

  @override
  String get authServerUrlLabel => 'Server Address';

  @override
  String get authServerVerifying => 'Verifying server...';

  @override
  String get authServerVerifyAndNext => 'Verify Server & Next';

  @override
  String get authChangeServer => 'Change Server';

  @override
  String get authAppSubtitle => 'Smart ERP & Accounting System';

  @override
  String get authSecurityFooter =>
      'Encrypted & Secure Connection (Standard Compliant)';

  @override
  String get authPasswordStrengthWeak => 'Weak';

  @override
  String get authPasswordStrengthMedium => 'Medium';

  @override
  String get authPasswordStrengthStrong => 'Strong';

  @override
  String get authPasswordStrengthVeryStrong => 'Very Strong';

  @override
  String get authPasswordChangedSuccess => 'Password updated successfully';

  @override
  String get authBiometricsSettingsTitle => 'Biometric Sign-In';

  @override
  String get authBiometricsSettingsSubtitle =>
      'Use fingerprint or face ID to unlock your session quickly';

  @override
  String get authBiometricsNotAvailable =>
      'Biometric authentication is not supported or set up on this device';

  @override
  String get authSecuritySectionTitle => 'Authentication & Security';

  @override
  String get authChangePasswordTileTitle => 'Change Password';

  @override
  String get authChangePasswordTileSubtitle =>
      'Update local device account password';

  @override
  String get syncSummaryTitle => 'Outbox Breakdown';

  @override
  String get syncSummaryPending => 'Pending Push';

  @override
  String get syncSummaryConflicts => 'Conflicts';

  @override
  String get syncSummaryFailed => 'Failed';

  @override
  String get syncDiagnosticsTitle => 'Server Health & Connection';

  @override
  String get syncDiagnosticsServerConnected => 'Connected';

  @override
  String get syncDiagnosticsServerDisconnected => 'Disconnected';

  @override
  String get syncDiagnosticsResponse => 'Status';

  @override
  String get syncDiagnosticsLatency => 'Latency';

  @override
  String get syncInspectorTitle => 'Outbox Inspector';

  @override
  String syncInspectAction(int count) {
    return 'Inspect Outbox ($count)';
  }

  @override
  String get syncHistoryTitle => 'Recent Pass History';

  @override
  String get syncHistoryEmpty => 'No recent synchronization passes recorded.';

  @override
  String syncHistoryPassItem(
    String time,
    int uploaded,
    int downloaded,
    int ms,
  ) {
    return 'Pass at $time: ↑$uploaded ↓$downloaded (${ms}ms)';
  }

  @override
  String syncRetryFailedAction(int count) {
    return 'Retry Failed ($count)';
  }

  @override
  String get syncOfflineHint =>
      'You are currently offline. Local changes are stored safely and will sync automatically when connection returns.';

  @override
  String get syncOutboxInspectorTooltip => 'Outbox Inspector';

  @override
  String syncPassCompletedSuccess(int uploaded, int downloaded) {
    return 'Synchronization completed: $uploaded uploaded, $downloaded downloaded.';
  }

  @override
  String syncPassCompletedWarnings(int failed, int conflicts) {
    return 'Sync completed with $failed failures and $conflicts conflicts.';
  }

  @override
  String get syncPassUpToDate => 'Synchronization up to date.';

  @override
  String syncOutboxTitle(int count) {
    return 'Sync Outbox Inspector ($count)';
  }

  @override
  String get syncOutboxEmpty => 'No operations in outbox queue';

  @override
  String syncOutboxTabAll(int count) {
    return 'All ($count)';
  }

  @override
  String syncOutboxTabIssues(int count) {
    return 'Issues ($count)';
  }

  @override
  String syncOutboxTabPending(int count) {
    return 'Pending ($count)';
  }

  @override
  String get syncOutboxPurge => 'Purge';

  @override
  String get syncOutboxRetryNow => 'Retry Now';

  @override
  String get syncOutboxDetailsTitle => 'Operation Details';

  @override
  String get authChangePasswordLocalAccountNotice =>
      'Note: This password change applies to your local device authentication account.';

  @override
  String get syncServerTestingConnection => 'Testing server connection...';

  @override
  String get syncServerConnectionSuccess => 'Server connection successful.';

  @override
  String get syncServerConnectionFailed =>
      'Unable to reach server. Please check the URL and network connection.';

  @override
  String get syncBiometricSettingsTitle => 'Server Biometric Login';

  @override
  String get syncBiometricSettingsSubtitle =>
      'Allow signing into server account using fingerprint';

  @override
  String get syncGoToLoginAction => 'Proceed to Server Login';

  @override
  String get syncDisableConfirmTitle => 'Disable Sync & Confirm Logout';

  @override
  String get syncDisableConfirmAdminContent =>
      'Disabling sync will log you out from the server and return to the main login page. Do you agree?';

  @override
  String get syncDisableConfirmAction => 'Confirm & Disable Sync';

  @override
  String get syncDisabledSuccessLogout =>
      'Synchronization disabled and logged out successfully.';

  @override
  String get syncDisableRequestTitle => 'Request Sync Disable';

  @override
  String get syncDisableRequestContent =>
      'Disabling synchronization requires System Administrator approval. Would you like to send a request to the Admin?';

  @override
  String get syncDisableSendRequestAction => 'Send Request';

  @override
  String get syncDisableRequestSentSuccess =>
      'Sync disable request sent to Administrator pending approval.';

  @override
  String get syncActiveServerLabel => 'Active Sync Server';

  @override
  String get syncDisableAction => 'Disable Synchronization';

  @override
  String get authBiometricPasswordDialogTitle => 'Enable Biometric Login';

  @override
  String get authBiometricPasswordDialogContent =>
      'Enter password to confirm and enable biometric login:';

  @override
  String get authBiometricPasswordDialogSkip => 'Skip';

  @override
  String get authBiometricPasswordDialogConfirm => 'Confirm';

  @override
  String get authBiometricEnabledSuccess =>
      'Biometric login enabled successfully';

  @override
  String get authBiometricDisabledSuccess => 'Biometric login disabled';

  @override
  String get authBackToLoginFields => 'Back to Login Fields';

  @override
  String get authUsernameOrEmailRequired => 'Please enter username or email';

  @override
  String get authPasswordRequired => 'Please enter password';

  @override
  String get syncPreparingOperations => 'Preparing sync operations...';

  @override
  String get syncSummaryDownloaded => 'Downloaded';

  @override
  String get syncSummaryUploaded => 'Uploaded';

  @override
  String get close => 'Close';

  @override
  String get subscriptionAndPackagesTitle => 'Subscription & Packages';

  @override
  String get subscriptionAndPackagesSubtitle =>
      'Commercial Plans & Cloud Packages';

  @override
  String get manageSubscriptionButton => 'Manage Subscription & Packages';

  @override
  String get activePackagesHeader => 'ACTIVE PACKAGES & CAPABILITIES';

  @override
  String get resourceUsageHeader => 'RESOURCE USAGE & METERS';

  @override
  String get cloudSyncCapabilityTitle => 'Cloud Data Synchronization';

  @override
  String get multiDeviceCapabilityTitle => 'Multi-Device Access';

  @override
  String get multiBranchCapabilityTitle => 'Multi-Branch Management';

  @override
  String get capabilityLockedLabel => 'Locked';

  @override
  String get registeredDevicesLabel => 'Registered Devices';

  @override
  String get teamUsersLabel => 'Team Users';

  @override
  String get packageStoreSheetTitle => 'Package Store & Upgrade';

  @override
  String get selectCommercialPlanSection => 'SELECT COMMERCIAL PLAN';

  @override
  String get availableAddonPackagesSection => 'AVAILABLE ADD-ON PACKAGES';

  @override
  String get activateSubscriptionButton =>
      'Activate Subscription & Update Entitlement';

  @override
  String get subscriptionActivatedSuccess =>
      'Subscription activated and entitlement updated successfully!';

  @override
  String get setupLocalAccountSection => 'Local Account Credentials';

  @override
  String get setupLocalAccountSubtitle =>
      'Set the email and password used to log in to the local account.';

  @override
  String get setupLocalEmail => 'Local Email';

  @override
  String get setupLocalEmailRequired => 'Email is required';

  @override
  String get setupLocalPassword => 'New Password (Optional)';

  @override
  String get setupLocalPasswordHelper =>
      'Enter a new password (min 6 chars) to update.';

  @override
  String get systemSetupWizardHeaderTitle => 'System Setup Wizard';

  @override
  String get systemSetupWizardHeaderSubtitle =>
      'Configure language, currency, company profile, and local admin account.';

  @override
  String get systemSetupStepLocalAccount => 'Local Admin Account';

  @override
  String get systemSetupStepLocalAccountHint =>
      'Set the email and password for local admin access.';

  @override
  String get systemSetupLocalAccountTitle => 'Local Admin Account Setup';

  @override
  String get systemSetupLocalAccountSubtitle =>
      'Set the email and password for local admin access.';

  @override
  String get systemSetupAdminEmail => 'Admin Email';

  @override
  String get systemSetupPassword => 'Password';

  @override
  String get systemSetupConfirmPassword => 'Confirm Password';

  @override
  String get systemSetupPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get systemSetupCompleteAndLaunch => 'Complete Setup & Launch';

  @override
  String get systemSetupSuccess => 'System setup complete!';

  @override
  String systemSetupStepsCompletedCount(int done, int total) {
    return 'Completed $done of $total steps';
  }

  @override
  String get setupSeedInitialDataTitle => 'Initialize default system data';

  @override
  String get setupSeedInitialDataSubtitle =>
      'Automatically seed default chart of accounts and initial settings.';

  @override
  String get moduleUnitsSettingsTitle => 'Unit Settings';

  @override
  String get moduleUnitsSettingsSubtitle =>
      'Unit and service settings for system modules';

  @override
  String get selectModulePrompt =>
      'Select a module to access its unit and service settings';

  @override
  String get stockCountSettingsTitle => 'Stock Count Settings';

  @override
  String get stockCountSettingsSubtitle =>
      'Customize inventory count policies and approval workflows';

  @override
  String get productSettingsTitle => 'Product Settings';

  @override
  String get productSettingsSubtitle =>
      'Customize categories, barcoding, pricing, and units';

  @override
  String get moduleUnitsReportsTitle => 'Module & Unit Reports';

  @override
  String get moduleUnitsReportsSubtitle =>
      'View and generate unit and service reports organized by module';

  @override
  String get selectModuleReportsPrompt =>
      'Select a module to view its available unit reports';
}
