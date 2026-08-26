import 'dart:typed_data';

/// Statement layout variants (classic Soft2-style titles).
enum AccountStatementType {
  /// Cumulative running balance in the account currency (sample model).
  cumulativeAccountCurrency('cumulative_account_currency'),

  /// Line-by-line without emphasizing account-currency cumulative title.
  detailed('detailed'),

  /// Period totals only.
  summary('summary');

  const AccountStatementType(this.storageValue);
  final String storageValue;

  static AccountStatementType fromStorage(String raw) {
    // Legacy value from earlier builds.
    if (raw == 'with_opening') {
      return AccountStatementType.cumulativeAccountCurrency;
    }
    return AccountStatementType.values.firstWhere(
      (e) => e.storageValue == raw,
      orElse: () => AccountStatementType.cumulativeAccountCurrency,
    );
  }
}

/// Journal posting filter (future journals; empty until ledger exists).
enum AccountStatementPostingFilter {
  all('all'),
  posted('posted'),
  unposted('unposted');

  const AccountStatementPostingFilter(this.storageValue);
  final String storageValue;

  static AccountStatementPostingFilter fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return AccountStatementPostingFilter.all;
    }
    return AccountStatementPostingFilter.values.firstWhere(
      (e) => e.storageValue == raw,
      orElse: () => AccountStatementPostingFilter.all,
    );
  }
}

class AccountStatementAccountRef {
  const AccountStatementAccountRef({
    required this.accountUuid,
    required this.accountCode,
    required this.name,
    this.systemKey,
  });

  final String accountUuid;
  final String accountCode;
  final String name;

  /// Optional system seed key (`system:…` description) for localized labels.
  final String? systemKey;
}

class AccountStatementCurrencyRef {
  const AccountStatementCurrencyRef({
    required this.code,
    required this.displayName,
  });

  final String code;
  final String displayName;
}

class AccountStatementLine {
  const AccountStatementLine({
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.sideLabel,
    this.currencyCode,
    this.displayCurrencyCode,
    this.isPosted = true,
  });

  final DateTime entryDate;
  final String voucherNumber;

  /// e.g. سند قبض نقد / بيع آجل / قيود يومية
  final String voucherType;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  /// Classic marker: مدين = م ، دائن = د
  final String sideLabel;

  /// ISO / storage code (YER, USD, …).
  final String? currencyCode;

  /// System catalog symbol for printing (ر.ي, ر.س, …).
  final String? displayCurrencyCode;
  final bool isPosted;
}

/// Per-currency totals for Soft2 "الرصيد النهائي على مستوى العملة".
class AccountStatementCurrencyBalance {
  const AccountStatementCurrencyBalance({
    required this.currencyCode,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    this.amountInWords,
    this.displayCurrencyCode,
  });

  final String currencyCode;
  final double openingBalance;

  /// Period movement totals (for reference / future use).
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;

  /// Soft2 amount-in-words line under the totals table.
  final String? amountInWords;

  /// Soft2-style currency code / symbol in the grid (from system catalog).
  final String? displayCurrencyCode;

  /// Soft2 final table: absolute closing on debit side when balance ≥ 0.
  double get closingDebitSide =>
      closingBalance >= 0 ? closingBalance.abs() : 0;

  /// Soft2 final table: absolute closing on credit side when balance < 0.
  double get closingCreditSide =>
      closingBalance < 0 ? closingBalance.abs() : 0;
}

class AccountStatementReportPayload {
  const AccountStatementReportPayload({
    required this.companyName,
    required this.reportTitle,
    required this.printedByLabel,
    required this.fromDateLabel,
    required this.toDateLabel,
    required this.accountNameLabel,
    required this.accountNumberLabel,
    required this.accountCode,
    required this.accountName,
    required this.statementTypeLabel,
    required this.postingFilterLabel,
    required this.currencyLabel,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.lines,
    required this.balancesByCurrency,
    required this.columnSide,
    required this.columnDescription,
    required this.columnVoucherType,
    required this.columnVoucherNumber,
    required this.columnDate,
    required this.columnDebit,
    required this.columnCredit,
    required this.columnBalance,
    required this.columnCurrency,
    required this.columnInCurrency,
    required this.totalsDebitLabel,
    required this.totalsCreditLabel,
    required this.finalBalanceByCurrencyLabel,
    required this.disclaimer,
    required this.accountantLabel,
    required this.reviewerLabel,
    required this.financeManagerLabel,
    this.fromDate,
    this.toDate,
    this.currencyCode,
    this.baseCurrencyCode,
    this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String printedByLabel;
  final String fromDateLabel;
  final String toDateLabel;
  final String accountNameLabel;
  final String accountNumberLabel;
  final String accountCode;
  final String accountName;
  final String statementTypeLabel;
  final String postingFilterLabel;
  final String currencyLabel;
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;

  /// Movement rows. When [currencyCode] is null (all currencies), lines are
  /// grouped by currency (each group has its own running balance).
  /// Default company currency group appears first.
  final List<AccountStatementLine> lines;

  /// One final-balance strip per currency (Soft2).
  final List<AccountStatementCurrencyBalance> balancesByCurrency;
  final String columnSide;
  final String columnDescription;
  final String columnVoucherType;
  final String columnVoucherNumber;
  final String columnDate;
  final String columnDebit;
  final String columnCredit;
  final String columnBalance;
  final String columnCurrency;
  final String columnInCurrency;
  final String totalsDebitLabel;
  final String totalsCreditLabel;
  final String finalBalanceByCurrencyLabel;
  final String disclaimer;
  final String accountantLabel;
  final String reviewerLabel;
  final String financeManagerLabel;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? currencyCode;

  /// Company default currency — used for display ordering.
  final String? baseCurrencyCode;
  final String? emptyMessage;
}

/// Localized strings + formatters from UI (ARB resolved before port call).
class AccountStatementReportLabels {
  const AccountStatementReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.printedByLabel,
    required this.fromDateLabel,
    required this.toDateLabel,
    required this.accountNameLabel,
    required this.accountNumberLabel,
    required this.currencyAll,
    required this.columnSide,
    required this.columnDescription,
    required this.columnVoucherType,
    required this.columnVoucherNumber,
    required this.columnDate,
    required this.columnDebit,
    required this.columnCredit,
    required this.columnBalance,
    required this.columnCurrency,
    required this.columnInCurrency,
    required this.totalsDebitLabel,
    required this.totalsCreditLabel,
    required this.finalBalanceByCurrencyLabel,
    required this.disclaimer,
    required this.accountantLabel,
    required this.reviewerLabel,
    required this.financeManagerLabel,
    required this.emptyMessage,
    required this.statementTypeLabelOf,
    required this.postingFilterLabelOf,
    required this.accountDisplayNameOf,
  });

  final String companyName;
  final String reportTitle;
  final String printedByLabel;
  final String fromDateLabel;
  final String toDateLabel;
  final String accountNameLabel;
  final String accountNumberLabel;
  final String currencyAll;
  final String columnSide;
  final String columnDescription;
  final String columnVoucherType;
  final String columnVoucherNumber;
  final String columnDate;
  final String columnDebit;
  final String columnCredit;
  final String columnBalance;
  final String columnCurrency;

  /// Soft2 totals header: بالعملة
  final String columnInCurrency;

  /// Soft2 totals short debit label: مدين
  final String totalsDebitLabel;

  /// Soft2 totals short credit label: دائن
  final String totalsCreditLabel;
  final String finalBalanceByCurrencyLabel;
  final String disclaimer;
  final String accountantLabel;
  final String reviewerLabel;
  final String financeManagerLabel;
  final String emptyMessage;
  final String Function(AccountStatementType type) statementTypeLabelOf;
  final String Function(AccountStatementPostingFilter filter)
  postingFilterLabelOf;
  final String Function(AccountStatementAccountRef account) accountDisplayNameOf;
}

/// App wires this to Accounting repositories (modules ↛ modules).
abstract class AccountStatementReportDataPort {
  Future<List<AccountStatementAccountRef>> searchAccounts(String query);

  Future<List<AccountStatementCurrencyRef>> listCurrencies({
    required bool isArabic,
  });

  Future<AccountStatementReportPayload> load({
    required String accountUuid,
    String? currencyCode,
    DateTime? fromDate,
    DateTime? toDate,
    required AccountStatementType statementType,
    required AccountStatementPostingFilter postingFilter,
    required AccountStatementReportLabels labels,
  });
}

class NoOpAccountStatementReportDataPort
    implements AccountStatementReportDataPort {
  const NoOpAccountStatementReportDataPort();

  @override
  Future<List<AccountStatementAccountRef>> searchAccounts(String query) async =>
      const [];

  @override
  Future<List<AccountStatementCurrencyRef>> listCurrencies({
    required bool isArabic,
  }) async => const [];

  @override
  Future<AccountStatementReportPayload> load({
    required String accountUuid,
    String? currencyCode,
    DateTime? fromDate,
    DateTime? toDate,
    required AccountStatementType statementType,
    required AccountStatementPostingFilter postingFilter,
    required AccountStatementReportLabels labels,
  }) async {
    return AccountStatementReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.statementTypeLabelOf(statementType),
      printedByLabel: labels.printedByLabel,
      fromDateLabel: labels.fromDateLabel,
      toDateLabel: labels.toDateLabel,
      accountNameLabel: labels.accountNameLabel,
      accountNumberLabel: labels.accountNumberLabel,
      accountCode: '—',
      accountName: '—',
      statementTypeLabel: labels.statementTypeLabelOf(statementType),
      postingFilterLabel: labels.postingFilterLabelOf(postingFilter),
      currencyLabel: currencyCode ?? labels.currencyAll,
      openingBalance: 0,
      totalDebit: 0,
      totalCredit: 0,
      closingBalance: 0,
      lines: const [],
      balancesByCurrency: const [],
      columnSide: labels.columnSide,
      columnDescription: labels.columnDescription,
      columnVoucherType: labels.columnVoucherType,
      columnVoucherNumber: labels.columnVoucherNumber,
      columnDate: labels.columnDate,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      columnBalance: labels.columnBalance,
      columnCurrency: labels.columnCurrency,
      columnInCurrency: labels.columnInCurrency,
      totalsDebitLabel: labels.totalsDebitLabel,
      totalsCreditLabel: labels.totalsCreditLabel,
      finalBalanceByCurrencyLabel: labels.finalBalanceByCurrencyLabel,
      disclaimer: labels.disclaimer,
      accountantLabel: labels.accountantLabel,
      reviewerLabel: labels.reviewerLabel,
      financeManagerLabel: labels.financeManagerLabel,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: currencyCode,
      emptyMessage: labels.emptyMessage,
    );
  }
}

/// Unused import guard for typed_data in payload consumers.
typedef AccountStatementPdfBytes = Uint8List;
