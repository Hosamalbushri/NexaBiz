import '../../core/reporting/arabic_amount_words.dart';
import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/repositories/currency_rate_repository.dart';
import '../../modules/accounting/domain/repositories/journal_repository.dart';
import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/reports/domain/services/account_statement_report_data_port.dart';
import '../../modules/sales/domain/entities/sale.dart';
import '../../modules/sales/domain/services/sale_ledger_posting_port.dart';
import '../settings/company/app_currency.dart';
import '../settings/company/company_profile.dart';

/// App adapter: account statement ← Accounting COA + journal lines.
///
/// When [currencyCode] is null ("all currencies"), movements are emitted in
/// separate per-currency blocks — each with its own opening and running balance
/// (Soft2-compatible; never mixes YER+USD into one running total).
///
/// Before loading movements, optional [loadSalesForAccount] + [ledger] backfill
/// credit-sale journals so unposted invoices created before sync-on-save still
/// appear.
class AccountStatementReportDataAdapter
    implements AccountStatementReportDataPort {
  const AccountStatementReportDataAdapter({
    required this.accounts,
    required this.currencyRates,
    required this.journals,
    required this.loadCompanyProfile,
    this.loadSalesForAccount,
    this.ledger,
  });

  final AccountRepository accounts;
  final CurrencyRateRepository currencyRates;
  final JournalRepository journals;
  final Future<CompanyProfile> Function() loadCompanyProfile;
  final Future<List<Sale>> Function(String accountUuid)? loadSalesForAccount;
  final SaleLedgerPostingPort? ledger;

  @override
  Future<List<AccountStatementAccountRef>> searchAccounts(String query) async {
    final list = await accounts.search(query, includeInactive: false);
    return [
      for (final account in list)
        if (account.isPostingAccount && account.isActive && !account.isDeleted)
          _toRef(account),
    ];
  }

  @override
  Future<List<AccountStatementCurrencyRef>> listCurrencies({
    required bool isArabic,
  }) async {
    final profile = await loadCompanyProfile();
    final base = profile.defaultCurrency;
    final rates = await currencyRates.getAll();
    final codes = <String>{base.code, for (final r in rates) r.currencyCode};
    final sorted = codes.toList()..sort();
    return [
      for (final code in sorted)
        AccountStatementCurrencyRef(
          code: code,
          displayName: AppCurrencies.byCode(code).localizedName(isArabic),
        ),
    ];
  }

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
    final account = await accounts.getByUuid(accountUuid);
    final typeTitle = labels.statementTypeLabelOf(statementType);

    if (account == null || account.isDeleted) {
      return _emptyPayload(
        labels: labels,
        reportTitle: typeTitle,
        accountCode: '—',
        accountName: '—',
        statementType: statementType,
        postingFilter: postingFilter,
        currencyCode: currencyCode,
        fromDate: fromDate,
        toDate: toDate,
      );
    }

    final ref = _toRef(account);
    final profile = await loadCompanyProfile();
    final baseCurrency = profile.defaultCurrencyCode.trim().toUpperCase();
    final postedFilter = switch (postingFilter) {
      AccountStatementPostingFilter.all => null,
      AccountStatementPostingFilter.posted => true,
      AccountStatementPostingFilter.unposted => false,
    };
    final singleCurrency = currencyCode?.trim().isEmpty == true
        ? null
        : currencyCode?.trim().toUpperCase();

    await _ensureCreditSaleJournals(accountUuid);

    final periodMoves = await journals.listMovementsForAccount(
      accountUuid: accountUuid,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: singleCurrency,
      isPosted: postedFilter,
    );

    final currencyCodes = await _resolveCurrencyCodes(
      accountUuid: accountUuid,
      singleCurrency: singleCurrency,
      toDate: toDate,
      isPosted: postedFilter,
      baseCurrencyCode: baseCurrency,
    );

    final allLines = <AccountStatementLine>[];
    final balances = <AccountStatementCurrencyBalance>[];
    var aggregateDebit = 0.0;
    var aggregateCredit = 0.0;
    var aggregateOpening = 0.0;

    for (final code in currencyCodes) {
      final opening = fromDate == null
          ? 0.0
          : await journals.sumNetBefore(
              accountUuid: accountUuid,
              beforeDate: fromDate,
              currencyCode: code,
              isPosted: postedFilter,
            );

      final moves = singleCurrency != null
          ? periodMoves
          : [
              for (final m in periodMoves)
                if (m.currencyCode.toUpperCase() == code) m,
            ];

      var running = opening;
      var totalDebit = 0.0;
      var totalCredit = 0.0;
      final currencyLines = <AccountStatementLine>[];
      for (final m in moves) {
        totalDebit += m.debit;
        totalCredit += m.credit;
        running += m.debit - m.credit;
        currencyLines.add(
          AccountStatementLine(
            entryDate: m.entryDate,
            voucherNumber: m.voucherNumber,
            voucherType: m.voucherType,
            description: m.description,
            debit: m.debit,
            credit: m.credit,
            balance: running,
            sideLabel: m.debit >= m.credit ? 'م' : 'د',
            currencyCode: m.currencyCode,
            displayCurrencyCode: AppCurrencies.byCode(m.currencyCode).symbol,
            isPosted: m.isPosted,
          ),
        );
      }

      // Skip currencies with neither opening nor period activity.
      if (currencyLines.isEmpty && opening.abs() < 0.0001) {
        continue;
      }

      allLines.addAll(currencyLines);
      final closing = opening + totalDebit - totalCredit;
      balances.add(
        AccountStatementCurrencyBalance(
          currencyCode: code,
          openingBalance: opening,
          totalDebit: totalDebit,
          totalCredit: totalCredit,
          closingBalance: closing,
          displayCurrencyCode: AppCurrencies.byCode(code).symbol,
          amountInWords: ArabicAmountWords.forAmount(
            closing.abs(),
            AppCurrencies.byCode(code).nameAr,
          ),
        ),
      );
      aggregateDebit += totalDebit;
      aggregateCredit += totalCredit;
      aggregateOpening += opening;
    }

    final firstOpening = balances.isEmpty ? 0.0 : balances.first.openingBalance;
    final firstClosing = balances.isEmpty ? 0.0 : balances.first.closingBalance;

    return AccountStatementReportPayload(
      companyName: labels.companyName,
      reportTitle: typeTitle,
      printedByLabel: labels.printedByLabel,
      fromDateLabel: labels.fromDateLabel,
      toDateLabel: labels.toDateLabel,
      accountNameLabel: labels.accountNameLabel,
      accountNumberLabel: labels.accountNumberLabel,
      accountCode: account.accountCode,
      accountName: labels.accountDisplayNameOf(ref),
      statementTypeLabel: typeTitle,
      postingFilterLabel: labels.postingFilterLabelOf(postingFilter),
      currencyLabel: singleCurrency ?? labels.currencyAll,
      // Legacy single totals: meaningful for one currency; for "all" prefer
      // [balancesByCurrency] (do not mix currencies into one running figure).
      openingBalance: singleCurrency != null ? firstOpening : aggregateOpening,
      totalDebit: aggregateDebit,
      totalCredit: aggregateCredit,
      closingBalance: singleCurrency != null
          ? firstClosing
          : (balances.isEmpty
                ? 0.0
                : balances.fold<double>(0, (s, b) => s + b.closingBalance)),
      lines: statementType == AccountStatementType.summary
          ? const []
          : allLines,
      balancesByCurrency: balances,
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
      currencyCode: singleCurrency,
      baseCurrencyCode: baseCurrency,
      emptyMessage: labels.emptyMessage,
    );
  }

  /// Currencies to render: the selected one, or every currency with activity
  /// up to [toDate] (DB DISTINCT — does not load prior movement rows).
  Future<List<String>> _resolveCurrencyCodes({
    required String accountUuid,
    required String? singleCurrency,
    required DateTime? toDate,
    required bool? isPosted,
    required String baseCurrencyCode,
  }) async {
    if (singleCurrency != null) {
      return [singleCurrency];
    }

    final sorted = await journals.listCurrencyCodesForAccount(
      accountUuid: accountUuid,
      toDate: toDate,
      isPosted: isPosted,
    );
    final base = baseCurrencyCode.trim().toUpperCase();
    if (base.isNotEmpty && sorted.remove(base)) {
      return [base, ...sorted];
    }
    return sorted;
  }

  /// Upserts journals for credit sales linked to [accountUuid] (idempotent).
  Future<void> _ensureCreditSaleJournals(String accountUuid) async {
    final loadSales = loadSalesForAccount;
    final ledgerPort = ledger;
    if (loadSales == null || ledgerPort == null) {
      return;
    }
    final list = await loadSales(accountUuid);
    for (final sale in list) {
      try {
        await ledgerPort.syncSale(sale);
      } catch (_) {
        // Keep statement generation resilient; missing one sale should not
        // blank the whole report.
      }
    }
  }

  AccountStatementReportPayload _emptyPayload({
    required AccountStatementReportLabels labels,
    required String reportTitle,
    required String accountCode,
    required String accountName,
    required AccountStatementType statementType,
    required AccountStatementPostingFilter postingFilter,
    required String? currencyCode,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    return AccountStatementReportPayload(
      companyName: labels.companyName,
      reportTitle: reportTitle,
      printedByLabel: labels.printedByLabel,
      fromDateLabel: labels.fromDateLabel,
      toDateLabel: labels.toDateLabel,
      accountNameLabel: labels.accountNameLabel,
      accountNumberLabel: labels.accountNumberLabel,
      accountCode: accountCode,
      accountName: accountName,
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
      baseCurrencyCode: null,
      emptyMessage: labels.emptyMessage,
    );
  }

  AccountStatementAccountRef _toRef(Account account) {
    return AccountStatementAccountRef(
      accountUuid: account.uuid,
      accountCode: account.accountCode,
      name: account.name,
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }
}
